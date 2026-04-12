<?php

namespace App\Services;

use App\Exceptions\DuplicateTransactionException;
use App\Exceptions\FraudBlockException;
use App\Exceptions\InsufficientBalanceException;
use App\Jobs\EvaluateFraud;
use App\Jobs\SendTransactionNotification;
use App\Models\Transaction;
use App\Models\User;
use App\Repositories\TransactionRepository;
use App\Repositories\WalletRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TransactionService
{
    public function __construct(
        private readonly FraudService $fraudService,
        private readonly TransactionRepository $txRepo,
        private readonly WalletRepository $walletRepo
    ) {}

    /**
     * Transfer money from sender to receiver.
     *
     * @throws DuplicateTransactionException
     * @throws InsufficientBalanceException
     * @throws FraudBlockException
     * @throws ValidationException
     */
    public function transfer(User $sender, array $data, ?string $idempotencyKey = null): Transaction
    {
        // ── Idempotency check ─────────────────────────────────────────────────
        if ($idempotencyKey) {
            $existing = $this->txRepo->findByIdempotencyKey($idempotencyKey);
            if ($existing) {
                if ($existing->status === 'success') {
                    return $existing->load(['sender:id,name,email', 'receiver:id,name,email']);
                }
                if (in_array($existing->status, ['pending', 'processing'])) {
                    throw DuplicateTransactionException::make();
                }
            }
        }

        $receiver = User::where('email', $data['receiver_email'])->firstOrFail();
        $amount   = (float) $data['amount'];

        // ── Self-transfer guard ───────────────────────────────────────────────
        if ($sender->id === $receiver->id) {
            throw ValidationException::withMessages([
                'receiver_email' => 'You cannot transfer money to yourself.',
            ]);
        }

        // ── Fraud pre-check (blocking) ────────────────────────────────────────
        $this->fraudService->preCheck($sender, $amount, $receiver);

        // ── KYC enforcement (per-transaction + daily cumulative) ──────────────
        $this->enforceKycLimits($sender, $amount);

        // ── Balance check + debit/credit inside DB transaction ────────────────
        $transaction = DB::transaction(function () use ($sender, $receiver, $amount, $idempotencyKey) {
            if (! $this->walletRepo->hasSufficientBalance($sender, $amount)) {
                throw InsufficientBalanceException::make();
            }

            $this->walletRepo->debit($sender, $amount);
            $this->walletRepo->credit($receiver, $amount);

            return Transaction::create([
                'reference'       => $this->txRepo->generateReference(),
                'idempotency_key' => $idempotencyKey,
                'sender_id'       => $sender->id,
                'receiver_id'     => $receiver->id,
                'amount'          => $amount,
                'status'          => 'success',
                'type'            => 'transfer',
            ]);
        });

        // ── Async post-processing ─────────────────────────────────────────────
        EvaluateFraud::dispatch($sender, $transaction);
        SendTransactionNotification::dispatch($transaction, 'sender');
        SendTransactionNotification::dispatch($transaction, 'receiver');

        return $transaction->load(['sender:id,name,email', 'receiver:id,name,email']);
    }

    /**
     * Reverse a completed transfer — admin action only.
     *
     * @throws ValidationException
     */
    public function reverse(Transaction $transaction, User $admin): Transaction
    {
        if ($transaction->status !== 'success') {
            throw ValidationException::withMessages([
                'transaction' => 'Only successful transactions can be reversed.',
            ]);
        }

        if ($transaction->type !== 'transfer') {
            throw ValidationException::withMessages([
                'transaction' => 'Only wallet transfers can be reversed.',
            ]);
        }

        DB::transaction(function () use ($transaction) {
            $this->walletRepo->credit($transaction->sender, $transaction->amount);

            if (! $this->walletRepo->hasSufficientBalance($transaction->receiver, $transaction->amount)) {
                throw ValidationException::withMessages([
                    'transaction' => 'Receiver has insufficient balance for reversal.',
                ]);
            }

            $this->walletRepo->debit($transaction->receiver, $transaction->amount);
            $transaction->update(['status' => 'reversed']);
        });

        return $transaction->fresh();
    }

    public function getHistory(User $user): LengthAwarePaginator
    {
        return $this->txRepo->getHistory($user);
    }

    // ── Private ───────────────────────────────────────────────────────────────

    /**
     * Enforce both per-transaction and daily cumulative KYC limits.
     *
     * Per-transaction:
     *   tier0 → ₦10,000
     *   tier1 → ₦200,000
     *   tier2 → ₦5,000,000
     *
     * Daily cumulative:
     *   tier0 → ₦20,000/day
     *   tier1 → ₦500,000/day
     *   tier2 → ₦20,000,000/day
     *
     * @throws ValidationException
     */
    private function enforceKycLimits(User $sender, float $amount): void
    {
        $perTxLimit  = $sender->kyc_limit;
        $dailyLimit  = $sender->kyc_daily_limit;
        $tier        = $sender->kyc_level;

        // 1. Per-transaction check
        if ($amount > $perTxLimit) {
            throw ValidationException::withMessages([
                'amount' => sprintf(
                    'Single transaction limit for %s is ₦%s. Verify your account to increase limits.',
                    strtoupper($tier),
                    number_format($perTxLimit, 2)
                ),
            ]);
        }

        // 2. Daily cumulative check — query via repository (hits the index)
        $todayTotal = $this->txRepo->getDailyTotalSent($sender);

        if (($todayTotal + $amount) > $dailyLimit) {
            $remaining = max(0, $dailyLimit - $todayTotal);
            throw ValidationException::withMessages([
                'amount' => sprintf(
                    'Daily limit for %s is ₦%s. You have ₦%s remaining today. Verify your account to increase limits.',
                    strtoupper($tier),
                    number_format($dailyLimit, 2),
                    number_format($remaining, 2)
                ),
            ]);
        }
    }
}
