<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\FraudLog;
use App\Models\KycDocument;
use App\Models\PaymentLink;
use App\Models\Transaction;
use App\Models\User;
use App\Models\VirtualCard;
use App\Repositories\AuditLogRepository;
use App\Services\KycService;
use App\Services\TransactionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminDashboardController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactionService,
        private readonly AuditLogRepository $auditRepo,
        private readonly KycService $kycService
    ) {}

    // Auth

    public function loginForm()
    {
        return view('auth.login');
    }

    public function loginPost(Request $request)
    {
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (! Auth::attempt($credentials)) {
            return back()->with('error', 'Invalid credentials. Please try again.');
        }

        $user = Auth::user();

        if ($user->role !== 'admin') {
            Auth::logout();
            return back()->with('error', 'Access denied. Admin accounts only.');
        }

        session([
            'admin_token' => $user->createToken('dashboard')->plainTextToken,
            'admin_name'  => $user->name,
        ]);

        return redirect()->route('admin.dashboard');
    }

    public function logout(Request $request)
    {
        Auth::user()?->tokens()->where('name', 'dashboard')->delete();
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    // Dashboard

    public function dashboard()
    {
        $stats = [
            'total_users'        => User::count(),
            'total_transactions' => Transaction::count(),
            'fraud_alerts'       => FraudLog::where('resolution', 'open')->count(),
            'total_volume'       => Transaction::where('status', 'success')->sum('amount'),
            'pending_kyc'        => KycDocument::where('status', 'pending')->count(),
        ];

        $recentTransactions = Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])
            ->latest()->limit(8)->get()->toArray();

        $recentFraud = FraudLog::with(['user:id,name,email'])
            ->where('resolution', 'open')->latest()->limit(6)->get()->toArray();

        return view('admin.dashboard', compact('stats', 'recentTransactions', 'recentFraud'));
    }

    // Users

    public function users(Request $request)
    {
        $query = User::with('wallet')->latest();

        if ($search = $request->get('search')) {
            $query->where(fn ($q) => $q
                ->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%")
            );
        }

        if ($role = $request->get('role')) {
            $query->where('role', $role);
        }

        if ($request->get('frozen') === '1') {
            $query->where('is_frozen', true);
        }

        $users = $query->paginate(20)->toArray();

        return view('admin.users', compact('users'));
    }

    public function freezeUserWeb(Request $request, User $user)
    {
        if ($user->isAdmin()) {
            return back()->with('error', 'Cannot freeze an admin account.');
        }

        if ($user->isFrozen()) {
            return back()->with('error', 'Account is already frozen.');
        }

        $before = $user->only(['is_frozen']);
        $user->update(['is_frozen' => true]);

        $this->auditRepo->record(
            Auth::user(), 'freeze_user', $user,
            $before, ['is_frozen' => true], $request->ip()
        );

        return back()->with('success', "User {$user->email} has been frozen.");
    }

    public function unfreezeUserWeb(Request $request, User $user)
    {
        if (! $user->isFrozen()) {
            return back()->with('error', 'Account is not frozen.');
        }

        $before = $user->only(['is_frozen']);
        $user->update(['is_frozen' => false]);

        $this->auditRepo->record(
            Auth::user(), 'unfreeze_user', $user,
            $before, ['is_frozen' => false], $request->ip()
        );

        return back()->with('success', "User {$user->email} has been unfrozen.");
    }

    // Transactions

    public function transactions(Request $request)
    {
        $query = Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])->latest();

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $transactions = $query->paginate(20)->toArray();

        return view('admin.transactions', compact('transactions'));
    }

    public function reverseTransactionWeb(Request $request, Transaction $tx)
    {
        try {
            $before   = $tx->only(['status', 'amount', 'sender_id', 'receiver_id']);
            $reversed = $this->transactionService->reverse($tx, Auth::user());

            $this->auditRepo->record(
                Auth::user(), 'reverse_transaction', $tx,
                $before, $reversed->only(['status']), $request->ip()
            );

            return back()->with('success', "Transaction {$tx->reference} has been reversed.");
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    // Fraud Logs

    public function fraudLogs(Request $request)
    {
        $query = FraudLog::with([
            'user:id,name,email',
            'transaction:id,reference,sender_id,receiver_id,amount,status,created_at',
        ])->latest();

        if ($riskLevel = $request->get('risk_level')) {
            $query->where('risk_level', $riskLevel);
        }

        if ($resolution = $request->get('resolution')) {
            $query->where('resolution', $resolution);
        }

        if ($rule = $request->get('rule')) {
            $query->where('rule_triggered', $rule);
        }

        $fraudLogs = $query->paginate(20)->toArray();

        return view('admin.fraud-logs', compact('fraudLogs'));
    }

    public function resolveFraudLogWeb(Request $request, FraudLog $log)
    {
        $request->validate([
            'resolution'      => ['required', 'in:resolved,escalated'],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ]);

        if ($log->resolution !== 'open') {
            return back()->with('error', 'This fraud log is already resolved.');
        }

        $before = $log->only(['resolution']);

        $log->update([
            'resolution'      => $request->resolution,
            'resolution_note' => $request->resolution_note,
            'resolved_by'     => Auth::id(),
            'resolved_at'     => now(),
        ]);

        $this->auditRepo->record(
            Auth::user(), 'resolve_fraud_log', $log,
            $before,
            $log->fresh()->only(['resolution', 'resolution_note']),
            $request->ip()
        );

        return back()->with('success', "Fraud log #{$log->id} marked as {$request->resolution}.");
    }

    // Top-ups

    public function topups(Request $request)
    {
        $query = Transaction::with('sender:id,name,email')->where('type', 'airtime')->latest();

        if ($network = $request->get('network')) {
            $query->whereJsonContains('meta->network', $network);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $topups = $query->paginate(20)->toArray();

        return view('admin.topups', compact('topups'));
    }

    // Bills

    public function bills(Request $request)
    {
        $query = Transaction::with('sender:id,name,email')->where('type', 'bill')->latest();

        if ($provider = $request->get('provider')) {
            $query->whereJsonContains('meta->provider', $provider);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $bills = $query->paginate(20)->toArray();

        return view('admin.bills', compact('bills'));
    }

    // Payment Links

    public function paymentLinks(Request $request)
    {
        $query = PaymentLink::with(['owner:id,name,email', 'payer:id,name,email'])->latest();

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $paymentLinks = $query->paginate(20)->toArray();

        return view('admin.payment-links', compact('paymentLinks'));
    }

    // Virtual Cards

    public function cards(Request $request)
    {
        $query = VirtualCard::with('user:id,name,email')->latest();

        if ($brand = $request->get('brand')) {
            $query->where('brand', $brand);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $cards = $query->paginate(20)
            ->through(fn ($card) => array_merge($card->toArray(), [
                'masked_number' => $card->masked_number,
            ]))
            ->toArray();

        return view('admin.cards', compact('cards'));
    }

    // Audit Logs

    public function auditLogs()
    {
        $auditLogs = AuditLog::with('admin:id,name,email')
            ->latest()
            ->paginate(30)
            ->toArray();

        return view('admin.audit-logs', compact('auditLogs'));
    }

    // KYC

    public function kycRequests(Request $request)
    {
        $query = KycDocument::with([
            'user:id,name,email,kyc_level,kyc_status',
            'reviewer:id,name,email',
        ])->latest();

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($type = $request->get('document_type')) {
            $query->where('document_type', $type);
        }

        $kycDocuments = $query->paginate(20)->toArray();

        return view('admin.kyc', compact('kycDocuments'));
    }

    public function approveKyc(Request $request, int $id)
    {
        try {
            $document = $this->kycService->approve($id, Auth::user());

            $this->auditRepo->record(
                Auth::user(), 'approve_kyc', $document,
                ['status' => 'pending'],
                ['status' => 'approved', 'kyc_level' => 'tier2'],
                $request->ip()
            );

            return back()->with('success', "KYC approved for {$document->user->email}. Upgraded to tier2.");
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function rejectKyc(Request $request, int $id)
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        try {
            $document = $this->kycService->reject($id, Auth::user(), $request->reason);

            $this->auditRepo->record(
                Auth::user(), 'reject_kyc', $document,
                ['status' => 'pending'],
                ['status' => 'rejected', 'reason' => $request->reason],
                $request->ip()
            );

            return back()->with('success', "KYC rejected for {$document->user->email}.");
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function viewKycDocument(int $id)
    {
        $document = KycDocument::findOrFail($id);
        $url      = $this->kycService->getDocumentUrl($document);
        return redirect($url);
    }
}
