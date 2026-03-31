<?php

namespace App\Http\Controllers;

use App\Models\FraudLog;
use App\Models\PaymentLink;
use App\Models\Transaction;
use App\Models\User;
use App\Models\VirtualCard;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminDashboardController extends Controller
{
    // ─── Auth ─────────────────────────────────────────────────────────────────

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

        if (!Auth::attempt($credentials)) {
            return back()->with('error', 'Invalid credentials. Please try again.');
        }

        $user = Auth::user();

        if ($user->role !== 'admin') {
            Auth::logout();
            return back()->with('error', 'Access denied. Admin accounts only.');
        }

        // Store admin info in session for display
        session([
            'admin_token' => $user->createToken('dashboard')->plainTextToken,
            'admin_name'  => $user->name,
        ]);

        return redirect()->route('admin.dashboard');
    }

    public function logout(Request $request)
    {
        // Revoke the dashboard token
        Auth::user()?->tokens()->where('name', 'dashboard')->delete();
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    // ─── Dashboard Home ───────────────────────────────────────────────────────

    public function dashboard()
    {
        $stats = [
            'total_users'        => User::count(),
            'total_transactions' => Transaction::count(),
            'fraud_alerts'       => FraudLog::count(),
            'total_volume'       => Transaction::where('status', 'success')->sum('amount'),
        ];

        $recentTransactions = Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])
            ->latest()
            ->limit(8)
            ->get()
            ->toArray();

        $recentFraud = FraudLog::with(['user:id,name,email'])
            ->latest()
            ->limit(6)
            ->get()
            ->toArray();

        return view('admin.dashboard', compact('stats', 'recentTransactions', 'recentFraud'));
    }

    // ─── Users ────────────────────────────────────────────────────────────────

    public function users(Request $request)
    {
        $query = User::with('wallet')->latest();

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($role = $request->get('role')) {
            $query->where('role', $role);
        }

        $users = $query->paginate(20)->toArray();

        return view('admin.users', compact('users'));
    }

    // ─── Transactions ─────────────────────────────────────────────────────────

    public function transactions(Request $request)
    {
        $query = Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])->latest();

        if ($search = $request->get('search')) {
            $query->whereHas('sender', fn ($q) => $q->where('name', 'like', "%{$search}%"))
                  ->orWhereHas('receiver', fn ($q) => $q->where('name', 'like', "%{$search}%"));
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $transactions = $query->paginate(20)->toArray();

        return view('admin.transactions', compact('transactions'));
    }

    // ─── Fraud Logs ───────────────────────────────────────────────────────────

    public function fraudLogs(Request $request)
    {
        $query = FraudLog::with([
            'user:id,name,email',
            'transaction:id,sender_id,receiver_id,amount,status,created_at',
        ])->latest();

        if ($riskLevel = $request->get('risk_level')) {
            $query->where('risk_level', $riskLevel);
        }

        if ($rule = $request->get('rule')) {
            $query->where('rule_triggered', $rule);
        }

        $fraudLogs = $query->paginate(20)->toArray();

        return view('admin.fraud-logs', compact('fraudLogs'));
    }

    // ─── Top-ups ──────────────────────────────────────────────────────────────

    public function topups(Request $request)
    {
        $query = Transaction::with('sender:id,name,email')
            ->where('type', 'airtime')
            ->latest();

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->whereJsonContains('meta->phone_number', $search)
                  ->orWhereHas('sender', fn ($q) => $q->where('name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%"));
            });
        }

        if ($network = $request->get('network')) {
            $query->whereJsonContains('meta->network', $network);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $topups = $query->paginate(20)->toArray();

        return view('admin.topups', compact('topups'));
    }

    // ─── Bills ────────────────────────────────────────────────────────────────

    public function bills(Request $request)
    {
        $query = Transaction::with('sender:id,name,email')
            ->where('type', 'bill')
            ->latest();

        if ($provider = $request->get('provider')) {
            $query->whereJsonContains('meta->provider', $provider);
        }

        if ($category = $request->get('category')) {
            $query->whereJsonContains('meta->category', $category);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $bills = $query->paginate(20)->toArray();

        return view('admin.bills', compact('bills'));
    }

    // ─── Payment Links ────────────────────────────────────────────────────────

    public function paymentLinks(Request $request)
    {
        $query = PaymentLink::with(['owner:id,name,email', 'payer:id,name,email'])->latest();

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($date = $request->get('date')) {
            $query->whereDate('created_at', $date);
        }

        $paymentLinks = $query->paginate(20)->toArray();

        return view('admin.payment-links', compact('paymentLinks'));
    }

    // ─── Virtual Cards ────────────────────────────────────────────────────────

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
                'masked_number' => '**** **** **** ' . substr($card->card_number, -4),
            ]))
            ->toArray();

        return view('admin.cards', compact('cards'));
    }
}
