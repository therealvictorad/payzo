<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TransactionService
{
    public function __construct(private readonly FraudService $fraudService) {}

    /**
     * Transfer money from sender to receiver.
     * Wrapped in a DB transaction to ensure atomicity.
     *
     * @throws ValidationException
     */
    public function transfer(User $sender, array $data): Transaction
    {
        $receiver = User::where('email', $data['receiver_email'])->firstOrFail();
        $amount   = (float) $data['amount'];

        // Prevent self-transfer
        if ($sender->id === $receiver->id) {
            throw ValidationException::withMessages([
                'receiver_email' => 'You cannot transfer money to yourself.',
            ]);
        }

        // Check sender has sufficient balance — read fresh from DB
        if ($sender->wallet()->value('balance') < $amount) {
            throw ValidationException::withMessages([
                'amount' => 'Insufficient wallet balance.',
            ]);
        }

        $transaction = DB::transaction(function () use ($sender, $receiver, $amount) {
            // Deduct from sender using lockForUpdate to prevent race conditions
            $senderWallet = $sender->wallet()->lockForUpdate()->first();
            $senderWallet->decrement('balance', $amount);

            // Credit receiver
            $receiver->wallet()->lockForUpdate()->first()->increment('balance', $amount);

            // Record the transaction
            return Transaction::create([
                'sender_id'   => $sender->id,
                'receiver_id' => $receiver->id,
                'amount'      => $amount,
                'status'      => 'success',
            ]);
        });

        // Run fraud checks asynchronously after the transaction is saved
        $this->fraudService->evaluate($sender, $transaction);

        return $transaction->load(['sender:id,name,email', 'receiver:id,name,email']);
    }

    /**
     * Return paginated transaction history for the authenticated user.
     */
    public function getHistory(User $user): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        return Transaction::with(['sender:id,name,email', 'receiver:id,name,email'])
            ->where('sender_id', $user->id)
            ->orWhere('receiver_id', $user->id)
            ->latest()
            ->paginate(15);
    }
}
