<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\FraudLog;
use App\Models\Transaction;
use App\Models\User;
use App\Repositories\AuditLogRepository;
use App\Services\AdminService;
use App\Services\TransactionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AdminController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AdminService $adminService,
        private readonly TransactionService $transactionService,
        private readonly AuditLogRepository $auditRepo
    ) {}

    // ─── Read ─────────────────────────────────────────────────────────────────

    public function users(Request $request): JsonResponse
    {
        return $this->success('Users retrieved',
            $this->adminService->getAllUsers($request->only(['search', 'role', 'is_frozen']))
        );
    }

    public function transactions(Request $request): JsonResponse
    {
        return $this->success('Transactions retrieved',
            $this->adminService->getAllTransactions($request->only(['status', 'type', 'date']))
        );
    }

    public function fraudLogs(Request $request): JsonResponse
    {
        return $this->success('Fraud logs retrieved',
            $this->adminService->getAllFraudLogs($request->only(['risk_level', 'resolution']))
        );
    }

    public function topups(): JsonResponse
    {
        return $this->success('Top-ups retrieved', $this->adminService->getAllTopups());
    }

    public function bills(): JsonResponse
    {
        return $this->success('Bills retrieved', $this->adminService->getAllBills());
    }

    public function paymentLinks(): JsonResponse
    {
        return $this->success('Payment links retrieved', $this->adminService->getAllPaymentLinks());
    }

    public function cards(): JsonResponse
    {
        return $this->success('Virtual cards retrieved', $this->adminService->getAllCards());
    }

    public function auditLogs(): JsonResponse
    {
        return $this->success('Audit logs retrieved', $this->auditRepo->paginate());
    }

    // ─── Write ────────────────────────────────────────────────────────────────

    public function freezeUser(Request $request, User $user): JsonResponse
    {
        if ($user->isAdmin()) {
            return $this->error('Cannot freeze an admin account.', 403);
        }

        if ($user->isFrozen()) {
            return $this->error('Account is already frozen.', 422);
        }

        $before = $user->only(['is_frozen']);
        $user->update(['is_frozen' => true]);

        $this->auditRepo->record(
            $request->user(), 'freeze_user', $user,
            $before, ['is_frozen' => true], $request->ip()
        );

        return $this->success("User {$user->email} has been frozen.");
    }

    public function unfreezeUser(Request $request, User $user): JsonResponse
    {
        if (! $user->isFrozen()) {
            return $this->error('Account is not frozen.', 422);
        }

        $before = $user->only(['is_frozen']);
        $user->update(['is_frozen' => false]);

        $this->auditRepo->record(
            $request->user(), 'unfreeze_user', $user,
            $before, ['is_frozen' => false], $request->ip()
        );

        return $this->success("User {$user->email} has been unfrozen.");
    }

    public function reverseTransaction(Request $request, Transaction $tx): JsonResponse
    {
        $before   = $tx->only(['status', 'amount', 'sender_id', 'receiver_id']);
        $reversed = $this->transactionService->reverse($tx, $request->user());

        $this->auditRepo->record(
            $request->user(), 'reverse_transaction', $tx,
            $before, $reversed->only(['status']), $request->ip()
        );

        return $this->success('Transaction reversed successfully.', $reversed);
    }

    public function resolveFraudLog(Request $request, FraudLog $log): JsonResponse
    {
        $request->validate([
            'resolution'      => ['required', 'in:resolved,escalated'],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ]);

        if ($log->resolution !== 'open') {
            return $this->error('This fraud log is already resolved.', 422);
        }

        $before = $log->only(['resolution']);

        $log->update([
            'resolution'      => $request->resolution,
            'resolution_note' => $request->resolution_note,
            'resolved_by'     => $request->user()->id,
            'resolved_at'     => now(),
        ]);

        $this->auditRepo->record(
            $request->user(), 'resolve_fraud_log', $log,
            $before, $log->fresh()->only(['resolution', 'resolution_note']), $request->ip()
        );

        return $this->success('Fraud log resolved.', $log->fresh()->load('resolvedBy:id,name,email'));
    }
}
