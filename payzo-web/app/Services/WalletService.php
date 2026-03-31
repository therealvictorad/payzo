<?php

namespace App\Services;

use App\Models\User;
use App\Models\Wallet;

class WalletService
{
    /**
     * Return the authenticated user's wallet.
     */
    public function getWallet(User $user): Wallet
    {
        return $user->wallet;
    }
}
