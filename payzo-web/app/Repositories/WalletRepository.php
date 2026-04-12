<?php

namespace App\Repositories;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\Cache;

class WalletRepository
{
    private const CACHE_TTL = 30; // seconds

    /**
     * Get wallet balance — served from cache when available.
     * Cache is invalidated on every debit/credit via invalidateCache().
     */
    public function getBalance(User $user): float
    {
        return (float) Cache::remember(
            $this->cacheKey($user->id),
            self::CACHE_TTL,
            fn () => $user->wallet()->value('balance') ?? 0.0
        );
    }

    /**
     * Debit wallet inside an existing DB transaction (caller must wrap in DB::transaction).
     * Uses lockForUpdate to prevent race conditions.
     * Returns the wallet after decrement.
     */
    public function debit(User $user, float $amount): Wallet
    {
        $wallet = $user->wallet()->lockForUpdate()->firstOrFail();
        $wallet->decrement('balance', $amount);
        $this->invalidateCache($user->id);
        return $wallet->fresh();
    }

    /**
     * Credit wallet inside an existing DB transaction.
     */
    public function credit(User $user, float $amount): Wallet
    {
        $wallet = $user->wallet()->lockForUpdate()->firstOrFail();
        $wallet->increment('balance', $amount);
        $this->invalidateCache($user->id);
        return $wallet->fresh();
    }

    /**
     * Check if user has sufficient balance — reads fresh from DB, not cache.
     */
    public function hasSufficientBalance(User $user, float $amount): bool
    {
        return (float) $user->wallet()->value('balance') >= $amount;
    }

    public function invalidateCache(int $userId): void
    {
        Cache::forget($this->cacheKey($userId));
    }

    private function cacheKey(int $userId): string
    {
        return "wallet_balance_{$userId}";
    }
}
