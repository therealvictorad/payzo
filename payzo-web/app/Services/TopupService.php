<?php

namespace App\Services;

use App\Exceptions\InsufficientBalanceException;
use App\Models\Transaction;
use App\Models\User;
use App\Repositories\TransactionRepository;
use App\Repositories\WalletRepository;
use Illuminate\Support\Facades\DB;

class TopupService
{
    public function __construct(
        private readonly WalletRepository $walletRepo,
        private readonly TransactionRepository $txRepo
    ) {}

    public function process(User $user, array $data): Transaction
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
                'type'       => 'airtime',
                'meta'       => [
                    'phone_number' => $data['phone_number'],
                    'network'      => $data['network'],
                    'topup_type'   => $data['type'],
                ],
            ]);
        });
    }
}
