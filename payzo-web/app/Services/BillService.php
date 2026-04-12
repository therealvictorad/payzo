<?php

namespace App\Services;

use App\Exceptions\InsufficientBalanceException;
use App\Models\Transaction;
use App\Models\User;
use App\Repositories\TransactionRepository;
use App\Repositories\WalletRepository;
use Illuminate\Support\Facades\DB;

class BillService
{
    private const PROVIDER_CATEGORY = [
        'DSTV'      => 'tv',
        'GOtv'      => 'tv',
        'Startimes' => 'tv',
        'IKEDC'     => 'electricity',
        'EKEDC'     => 'electricity',
        'AEDC'      => 'electricity',
        'IBEDC'     => 'electricity',
    ];

    public function __construct(
        private readonly WalletRepository $walletRepo,
        private readonly TransactionRepository $txRepo
    ) {}

    public function pay(User $user, array $data): Transaction
    {
        $amount = (float) $data['amount'];

        if (! $this->walletRepo->hasSufficientBalance($user, $amount)) {
            throw InsufficientBalanceException::make();
        }

        return DB::transaction(function () use ($user, $amount, $data) {
            $this->walletRepo->debit($user, $amount);

            return Transaction::create([
                'reference'  => $this->txRepo->generateReference(),
                'sender_id'  => $user->id,
                'amount'     => $amount,
                'status'     => 'success',
                'type'       => 'bill',
                'meta'       => [
                    'provider'    => $data['provider'],
                    'customer_id' => $data['customer_id'],
                    'category'    => self::PROVIDER_CATEGORY[$data['provider']] ?? 'other',
                    'reference'   => strtoupper('BILL-' . uniqid()),
                ],
            ]);
        });
    }
}
