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
    public function getAllUsers(): LengthAwarePaginator
    {
        return User::with('wallet')->latest()->paginate(20);
    }

    public function getAllTransactions(): LengthAwarePaginator
    {
        return Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])
            ->latest()->paginate(20);
    }

    public function getAllFraudLogs(): LengthAwarePaginator
    {
        return FraudLog::with([
            'user:id,name,email',
            'transaction:id,sender_id,receiver_id,amount,status,created_at',
        ])->latest()->paginate(20);
    }

    /** Airtime & data top-ups only */
    public function getAllTopups(): LengthAwarePaginator
    {
        return Transaction::with('sender:id,name,email')
            ->where('type', 'airtime')
            ->latest()->paginate(20);
    }

    /** Bill payments only */
    public function getAllBills(): LengthAwarePaginator
    {
        return Transaction::with('sender:id,name,email')
            ->where('type', 'bill')
            ->latest()->paginate(20);
    }

    public function getAllPaymentLinks(): LengthAwarePaginator
    {
        return PaymentLink::with(['owner:id,name,email', 'payer:id,name,email'])
            ->latest()->paginate(20);
    }

    public function getAllCards(): LengthAwarePaginator
    {
        return VirtualCard::with('user:id,name,email')
            ->latest()->paginate(20);
    }
}
