<?php

namespace Tests\Feature\Fraud;

use App\Models\Transaction;
use Tests\TestCase;

class FraudDetectionTest extends TestCase
{
    public function test_large_transaction_triggers_fraud_log(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->transfer($sender, $receiver, 1500.00);

        $this->assertFraudLogged($sender, 'LARGE_TRANSACTION', 'HIGH');
    }

    public function test_transaction_exactly_at_threshold_does_not_trigger_large_transaction_flag(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->transfer($sender, $receiver, 1000.00); // exactly 1000 — NOT > 1000

        $this->assertFraudNotLogged($sender, 'LARGE_TRANSACTION');
    }

    public function test_rapid_transactions_trigger_fraud_log(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(10000.00);

        foreach (range(1, 6) as $i) {
            $this->transfer($sender, $receiver, 10.00);
        }

        $this->assertFraudLogged($sender, 'RAPID_TRANSACTIONS', 'MEDIUM');
    }

    public function test_five_transactions_do_not_trigger_rapid_flag(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(10000.00);

        foreach (range(1, 5) as $i) { // exactly 5 — rule is > 5
            $this->transfer($sender, $receiver, 10.00);
        }

        $this->assertFraudNotLogged($sender, 'RAPID_TRANSACTIONS');
    }

    public function test_unusual_time_triggers_fraud_log(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->atHour(2, fn () => $this->transfer($sender, $receiver, 100.00));

        $this->assertFraudLogged($sender, 'UNUSUAL_TIME', 'LOW');
    }

    public function test_normal_daytime_transaction_does_not_trigger_unusual_time(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->atHour(10, fn () => $this->transfer($sender, $receiver, 100.00));

        $this->assertFraudNotLogged($sender, 'UNUSUAL_TIME');
    }

    public function test_fraud_log_is_linked_to_correct_transaction(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->transfer($sender, $receiver, 1500.00);

        $transaction = Transaction::where('sender_id', $sender->id)->first();

        $this->assertFraudLinkedToTransaction($transaction, 'LARGE_TRANSACTION');
    }

    public function test_fraud_detection_does_not_block_the_transaction(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        $this->transfer($sender, $receiver, 2000.00)->assertStatus(201);

        $this->assertBalance($sender, 3000.00);
        $this->assertBalance($receiver, 2000.00);
    }

    public function test_multiple_fraud_rules_can_trigger_on_same_transaction(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00);

        // 2 AM + amount > 1000 → both rules fire
        $this->atHour(2, fn () => $this->transfer($sender, $receiver, 1500.00));

        $transaction = Transaction::where('sender_id', $sender->id)->first();

        $this->assertFraudLinkedToTransaction($transaction, 'LARGE_TRANSACTION');
        $this->assertFraudLinkedToTransaction($transaction, 'UNUSUAL_TIME');
    }
}
