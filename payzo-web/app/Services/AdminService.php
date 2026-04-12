<?php

namespace App\Services;

use App\Models\FraudLog;
use App\Models\PaymentLink;
use App\Models\Transaction;
use App\Models\User;
use App\Models\VirtualCard;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AdminService
{
    public function getAllUsers(array $filters = []): LengthAwarePaginator
    {
        $query = User::with('wallet')->latest();

        if ($search = $filters['search'] ?? null) {
            $query->where(fn ($q) => $q
                ->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%")
            );
        }

        if ($role = $filters['role'] ?? null) {
            $query->where('role', $role);
        }

        if (isset($filters['is_frozen'])) {
            $query->where('is_frozen', (bool) $filters['is_frozen']);
        }

        return $query->paginate(20);
    }

    public function getAllTransactions(array $filters = []): LengthAwarePaginator
    {
        $query = Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])->latest();

        if ($status = $filters['status'] ?? null) {
            $query->where('status', $status);
        }

        if ($type = $filters['type'] ?? null) {
            $query->where('type', $type);
        }

        if ($date = $filters['date'] ?? null) {
            $query->whereDate('created_at', $date);
        }

        return $query->paginate(20);
    }

    public function getAllFraudLogs(array $filters = []): LengthAwarePaginator
    {
        $query = FraudLog::with([
            'user:id,name,email',
            'transaction:id,reference,sender_id,receiver_id,amount,status,created_at',
            'resolvedBy:id,name,email',
        ])->latest();

        if ($riskLevel = $filters['risk_level'] ?? null) {
            $query->where('risk_level', $riskLevel);
        }

        if ($resolution = $filters['resolution'] ?? null) {
            $query->where('resolution', $resolution);
        }

        return $query->paginate(20);
    }

    public function getAllTopups(): LengthAwarePaginator
    {
        return Transaction::with('sender:id,name,email')
            ->where('type', 'airtime')
            ->latest()
            ->paginate(20);
    }

    public function getAllBills(): LengthAwarePaginator
    {
        return Transaction::with('sender:id,name,email')
            ->where('type', 'bill')
            ->latest()
            ->paginate(20);
    }

    public function getAllPaymentLinks(): LengthAwarePaginator
    {
        return PaymentLink::with(['owner:id,name,email', 'payer:id,name,email'])
            ->latest()
            ->paginate(20);
    }

    public function getAllCards(): LengthAwarePaginator
    {
        return VirtualCard::with('user:id,name,email')
            ->latest()
            ->paginate(20);
    }
}
