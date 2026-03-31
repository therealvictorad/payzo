<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TopupService
{
    /**
     * Process airtime or data top-up.
     * Deducts from wallet and records a transaction of type 'airtime'.
     */
    public function process(User $user, array $data): Transaction
    {
        $amount = (float) $data['amount'];

        if ($user->wallet()->value('balance') < $amount) {
            throw ValidationException::withMessages([
                'amount' => 'Insufficient wallet balance.',
            ]);
        }

        return DB::transaction(function () use ($user, $amount, $data) {
            $user->wallet()->lockForUpdate()->first()->decrement('balance', $amount);

            return Transaction::create([
                'sender_id'   => $user->id,
                'receiver_id' => null,
                'amount'      => $amount,
                'status'      => 'success',
                'type'        => 'airtime',
                'meta'        => [
                    'phone_number' => $data['phone_number'],
                    'network'      => $data['network'],
                    'topup_type'   => $data['type'], // airtime | data
                ],
            ]);
        });
    }
}
