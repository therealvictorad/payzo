<?php

namespace App\Services;

use App\Models\FraudLog;
use App\Models\Transaction;
use App\Models\User;

class FraudService
{
    // Fraud rules constants
    const LARGE_TRANSACTION  = 'LARGE_TRANSACTION';
    const RAPID_TRANSACTIONS = 'RAPID_TRANSACTIONS';
    const UNUSUAL_TIME       = 'UNUSUAL_TIME';

    /**
     * Evaluate all fraud rules against the given transaction.
     * Logs any triggered rules — does NOT block the transaction.
     */
    public function evaluate(User $sender, Transaction $transaction): void
    {
        $this->checkLargeTransaction($sender, $transaction);
        $this->checkRapidTransactions($sender, $transaction);
        $this->checkUnusualTime($sender, $transaction);
    }

    /**
     * Flag transactions with amount > 1000 as HIGH risk.
     */
    private function checkLargeTransaction(User $sender, Transaction $transaction): void
    {
        if ($transaction->amount > 1000) {
            $this->log($sender, $transaction, self::LARGE_TRANSACTION, 'HIGH');
        }
    }

    /**
     * Flag if sender makes more than 5 transactions within 1 minute (MEDIUM risk).
     */
    private function checkRapidTransactions(User $sender, Transaction $transaction): void
    {
        $recentCount = Transaction::where('sender_id', $sender->id)
            ->where('created_at', '>=', now()->subMinute())
            ->count();

        if ($recentCount > 5) {
            $this->log($sender, $transaction, self::RAPID_TRANSACTIONS, 'MEDIUM');
        }
    }

    /**
     * Flag transactions made between 12AM and 4AM as LOW risk.
     */
    private function checkUnusualTime(User $sender, Transaction $transaction): void
    {
        $hour = now()->hour;

        if ($hour >= 0 && $hour < 4) {
            $this->log($sender, $transaction, self::UNUSUAL_TIME, 'LOW');
        }
    }

    /**
     * Persist a fraud log entry.
     */
    private function log(User $sender, Transaction $transaction, string $rule, string $riskLevel): void
    {
        FraudLog::create([
            'user_id'        => $sender->id,
            'transaction_id' => $transaction->id,
            'rule_triggered' => $rule,
            'risk_level'     => $riskLevel,
        ]);
    }
}
