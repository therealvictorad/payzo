<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BillService
{
    // Provider category map for meta enrichment
    private const PROVIDER_CATEGORY = [
        'DSTV'      => 'tv',
        'GOtv'      => 'tv',
        'Startimes' => 'tv',
        'IKEDC'     => 'electricity',
        'EKEDC'     => 'electricity',
        'AEDC'      => 'electricity',
        'IBEDC'     => 'electricity',
    ];

    /**
     * Process a bill payment.
     * Deducts from wallet and records a transaction of type 'bill'.
     */
    public function pay(User $user, array $data): Transaction
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
                'type'        => 'bill',
                'meta'        => [
                    'provider'    => $data['provider'],
                    'customer_id' => $data['customer_id'],
                    'category'    => self::PROVIDER_CATEGORY[$data['provider']] ?? 'other',
                    // Simulate a reference number
                    'reference'   => strtoupper('BILL-' . uniqid()),
                ],
            ]);
        });
    }
}
