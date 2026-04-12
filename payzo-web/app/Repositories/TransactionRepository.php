<?php

namespace App\Repositories;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Str;

class TransactionRepository
{
    /**
     * Generate a unique, human-readable transaction reference.
     * Format: TXN-YYYYMMDD-XXXXXXXX
     */
    public function generateReference(): string
    {
        do {
            $ref = 'TXN-' . now()->format('Ymd') . '-' . strtoupper(Str::random(8));
        } while (Transaction::where('reference', $ref)->exists());

        return $ref;
    }

    /**
     * Find a transaction by its idempotency key.
     * Returns null if no match — caller decides whether to proceed or return cached result.
     */
    public function findByIdempotencyKey(string $key): ?Transaction
    {
        return Transaction::where('idempotency_key', $key)->first();
    }

    /**
     * Find by reference.
     */
    public function findByReference(string $reference): ?Transaction
    {
        return Transaction::where('reference', $reference)->first();
    }

    /**
     * Paginated history for a user — both sent and received.
     * Uses a closure-wrapped orWhere to produce correct SQL grouping.
     */
    public function getHistory(User $user, int $perPage = 15): LengthAwarePaginator
    {
        return Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])
            ->where(function ($q) use ($user) {
                $q->where('sender_id', $user->id)
                  ->orWhere('receiver_id', $user->id);
            })
            ->latest()
            ->paginate($perPage);
    }

    /**
     * Create a transaction record in pending state.
     */
    public function createPending(array $data): Transaction
    {
        return Transaction::create(array_merge($data, [
            'reference' => $this->generateReference(),
            'status'    => 'pending',
        ]));
    }

    /**
     * Calculate the total amount sent by a user today (successful transfers only).
     * Used for daily cumulative KYC limit enforcement.
     * Hits the tx_daily_limit_idx composite index.
     */
    public function getDailyTotalSent(User $user): float
    {
        return (float) Transaction::where('sender_id', $user->id)
            ->where('status', 'success')
            ->whereDate('created_at', today())
            ->sum('amount');
    }
}
