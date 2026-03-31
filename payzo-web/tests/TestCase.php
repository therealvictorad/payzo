<?php

namespace Tests;

use App\Models\PaymentLink;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Testing\TestResponse;

abstract class TestCase extends BaseTestCase
{
    // Declared once here — never repeat in subclasses
    use RefreshDatabase;

    // ── User / Wallet Factories ───────────────────────────────────────────────

    protected function userWithWallet(float $balance = 1000.00, string $role = 'user'): User
    {
        $user = User::factory()->create(['role' => $role]);
        Wallet::create(['user_id' => $user->id, 'balance' => $balance]);
        return $user->fresh(['wallet']);
    }

    protected function adminWithWallet(float $balance = 0): User
    {
        return $this->userWithWallet($balance, 'admin');
    }

    protected function agentWithWallet(float $balance = 0): User
    {
        return $this->userWithWallet($balance, 'agent');
    }

    /** Create a sender + receiver pair — the most common test setup. */
    protected function senderAndReceiver(float $senderBalance = 1000.00, float $receiverBalance = 0.00): array
    {
        return [
            $this->userWithWallet($senderBalance),
            $this->userWithWallet($receiverBalance),
        ];
    }

    // ── Auth Helpers ──────────────────────────────────────────────────────────

    protected function authHeaders(User $user): array
    {
        return ['Authorization' => 'Bearer ' . $user->createToken('test-token')->plainTextToken];
    }

    // ── API Action Helpers ────────────────────────────────────────────────────

    /** POST /api/transfer and return the response. */
    protected function transfer(User $sender, User $receiver, float $amount): TestResponse
    {
        return $this->postJson('/api/transfer', [
            'receiver_email' => $receiver->email,
            'amount'         => $amount,
        ], $this->authHeaders($sender));
    }

    /** POST /api/topup and return the response. */
    protected function topup(User $user, array $overrides = []): TestResponse
    {
        return $this->postJson('/api/topup', array_merge([
            'phone_number' => '08012345678',
            'network'      => 'MTN',
            'type'         => 'airtime',
            'amount'       => 200.00,
        ], $overrides), $this->authHeaders($user));
    }

    /** POST /api/bills/pay and return the response. */
    protected function payBill(User $user, array $overrides = []): TestResponse
    {
        return $this->postJson('/api/bills/pay', array_merge([
            'provider'    => 'DSTV',
            'customer_id' => 'CUST123456',
            'amount'      => 5000.00,
        ], $overrides), $this->authHeaders($user));
    }

    /** Create an active PaymentLink owned by $owner. */
    protected function activeLink(User $owner, float $amount = 300.00): PaymentLink
    {
        return PaymentLink::factory()->create([
            'user_id' => $owner->id,
            'amount'  => $amount,
            'status'  => 'active',
        ]);
    }

    // ── Balance Assertions ────────────────────────────────────────────────────

    protected function assertBalance(User $user, float $expected): void
    {
        $this->assertEquals(
            number_format($expected, 2, '.', ''),
            $user->wallet->fresh()->balance,
            "Expected {$user->email} to have balance {$expected}"
        );
    }

    protected function assertBalancesUnchanged(User ...$users): void
    {
        foreach ($users as $user) {
            $original = (float) $user->wallet->balance;
            $this->assertBalance($user, $original);
        }
    }

    // ── Transaction Assertions ────────────────────────────────────────────────

    protected function assertTransactionRecorded(array $attributes): void
    {
        $this->assertDatabaseHas('transactions', array_merge(['status' => 'success'], $attributes));
    }

    protected function assertNoTransactionCreated(): void
    {
        $this->assertDatabaseCount('transactions', 0);
    }

    // ── Response Assertions ───────────────────────────────────────────────────

    protected function assertSuccessResponse(TestResponse $response, int $status = 200): void
    {
        $response->assertStatus($status)->assertJsonPath('status', 'success');
    }

    protected function assertErrorResponse(TestResponse $response, int $status): void
    {
        $response->assertStatus($status)->assertJsonPath('status', 'error');
    }

    protected function assertValidationError(TestResponse $response, string|array $fields): void
    {
        $response->assertStatus(422)->assertJsonValidationErrors((array) $fields);
    }

    protected function assertRequiresAuth(TestResponse $response): void
    {
        $response->assertStatus(401);
    }

    protected function assertForbidden(TestResponse $response): void
    {
        $response->assertStatus(403);
    }

    // ── Time Helpers ──────────────────────────────────────────────────────────

    /** Run $callback with Carbon frozen at the given hour, then reset. */
    protected function atHour(int $hour, callable $callback): void
    {
        Carbon::setTestNow(Carbon::today()->setHour($hour));
        try {
            $callback();
        } finally {
            Carbon::setTestNow();
        }
    }

    // ── Fraud Assertions ──────────────────────────────────────────────────────

    protected function assertFraudLogged(User $user, string $rule, string $riskLevel): void
    {
        $this->assertDatabaseHas('fraud_logs', [
            'user_id'        => $user->id,
            'rule_triggered' => $rule,
            'risk_level'     => $riskLevel,
        ]);
    }

    protected function assertFraudNotLogged(User $user, string $rule): void
    {
        $this->assertDatabaseMissing('fraud_logs', [
            'user_id'        => $user->id,
            'rule_triggered' => $rule,
        ]);
    }

    protected function assertFraudLinkedToTransaction(Transaction $transaction, string $rule): void
    {
        $this->assertDatabaseHas('fraud_logs', [
            'transaction_id' => $transaction->id,
            'rule_triggered' => $rule,
        ]);
    }
}
