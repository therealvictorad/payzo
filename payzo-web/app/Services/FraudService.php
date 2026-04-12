<?php

namespace App\Services;

use App\Exceptions\FraudBlockException;
use App\Models\FraudLog;
use App\Models\Transaction;
use App\Models\User;

class FraudService
{
    // ─── Rule identifiers ─────────────────────────────────────────────────────
    const LARGE_TRANSACTION  = 'LARGE_TRANSACTION';
    const RAPID_TRANSACTIONS = 'RAPID_TRANSACTIONS';
    const UNUSUAL_TIME       = 'UNUSUAL_TIME';
    const FROZEN_RECIPIENT   = 'FROZEN_RECIPIENT';

    // ─── Dynamic thresholds (override via config/fraud.php or .env) ──────────
    private function largeTransactionThreshold(): float
    {
        return (float) config('fraud.large_transaction_threshold', 50000);
    }

    private function rapidTransactionLimit(): int
    {
        return (int) config('fraud.rapid_transaction_limit', 5);
    }

    private function rapidTransactionWindow(): int
    {
        return (int) config('fraud.rapid_transaction_window_seconds', 60);
    }

    // ─── Pre-transaction blocking check ──────────────────────────────────────

    /**
     * Run synchronous checks BEFORE the transaction is committed.
     * Throws FraudBlockException to abort the transaction if HIGH risk is detected.
     *
     * @throws FraudBlockException
     */
    public function preCheck(User $sender, float $amount, ?User $receiver = null): void
    {
        // Block if sender account is frozen
        if ($sender->isFrozen()) {
            throw FraudBlockException::make();
        }

        // Block if receiver account is frozen
        if ($receiver && $receiver->isFrozen()) {
            throw FraudBlockException::make();
        }

        // Block if sender already has an open HIGH-risk fraud log
        $hasOpenHighRisk = FraudLog::where('user_id', $sender->id)
            ->where('risk_level', 'HIGH')
            ->where('resolution', 'open')
            ->exists();

        if ($hasOpenHighRisk) {
            throw FraudBlockException::make();
        }
    }

    // ─── Post-transaction async evaluation ───────────────────────────────────

    /**
     * Evaluate all fraud rules after a transaction is committed.
     * Called from the EvaluateFraud queued job — never on the HTTP thread.
     */
    public function evaluate(User $sender, Transaction $transaction): void
    {
        $this->checkLargeTransaction($sender, $transaction);
        $this->checkRapidTransactions($sender, $transaction);
        $this->checkUnusualTime($sender, $transaction);
    }

    // ─── Rules ────────────────────────────────────────────────────────────────

    private function checkLargeTransaction(User $sender, Transaction $transaction): void
    {
        if ($transaction->amount >= $this->largeTransactionThreshold()) {
            $this->log($sender, $transaction, self::LARGE_TRANSACTION, 'HIGH');
        }
    }

    private function checkRapidTransactions(User $sender, Transaction $transaction): void
    {
        $window = now()->subSeconds($this->rapidTransactionWindow());

        $recentCount = Transaction::where('sender_id', $sender->id)
            ->where('created_at', '>=', $window)
            ->count();

        if ($recentCount > $this->rapidTransactionLimit()) {
            $this->log($sender, $transaction, self::RAPID_TRANSACTIONS, 'MEDIUM');
        }
    }

    private function checkUnusualTime(User $sender, Transaction $transaction): void
    {
        $hour = now()->hour;

        if ($hour >= 0 && $hour < 4) {
            $this->log($sender, $transaction, self::UNUSUAL_TIME, 'LOW');
        }
    }

    private function log(User $sender, Transaction $transaction, string $rule, string $riskLevel): void
    {
        FraudLog::create([
            'user_id'        => $sender->id,
            'transaction_id' => $transaction->id,
            'rule_triggered' => $rule,
            'risk_level'     => $riskLevel,
            'resolution'     => 'open',
        ]);
    }
}
