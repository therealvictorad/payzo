<?php

namespace Tests\Feature\PaymentLinks;

use App\Models\PaymentLink;
use Tests\TestCase;

class PaymentLinkTest extends TestCase
{
    // ── Create ────────────────────────────────────────────────────────────────

    public function test_user_can_create_payment_link(): void
    {
        $user = $this->userWithWallet();

        $response = $this->postJson('/api/payment-links', [
            'amount'      => 500.00,
            'description' => 'Invoice #001',
        ], $this->authHeaders($user));

        $this->assertSuccessResponse($response, 201);
        $response->assertJsonStructure([
            'data' => ['id', 'code', 'amount', 'status', 'description'],
        ]);
        $this->assertDatabaseHas('payment_links', [
            'user_id' => $user->id,
            'amount'  => '500.00',
            'status'  => 'active',
        ]);
    }

    public function test_payment_link_code_is_unique_and_prefixed(): void
    {
        $user = $this->userWithWallet();

        $code = $this->postJson('/api/payment-links', ['amount' => 100.00], $this->authHeaders($user))
                     ->json('data.code');

        $this->assertStringStartsWith('PAY-', $code);
    }

    public function test_payment_link_description_is_optional(): void
    {
        $user = $this->userWithWallet();

        $this->assertSuccessResponse(
            $this->postJson('/api/payment-links', ['amount' => 100.00], $this->authHeaders($user)),
            201
        );
    }

    /** @dataProvider invalidPaymentLinkAmountProvider */
    public function test_create_payment_link_fails_with_invalid_amount(int|float|string $amount): void
    {
        $user = $this->userWithWallet();

        $this->assertValidationError(
            $this->postJson('/api/payment-links', ['amount' => $amount], $this->authHeaders($user)),
            'amount'
        );
    }

    public static function invalidPaymentLinkAmountProvider(): array
    {
        return [
            'zero amount'    => [0],
            'missing amount' => [''],
        ];
    }

    public function test_create_payment_link_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->postJson('/api/payment-links', ['amount' => 100]));
    }

    // ── List ──────────────────────────────────────────────────────────────────

    public function test_user_can_list_their_payment_links(): void
    {
        $user = $this->userWithWallet();
        PaymentLink::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/payment-links', $this->authHeaders($user));

        $this->assertSuccessResponse($response);
        $this->assertEquals(3, $response->json('data.total'));
    }

    public function test_user_only_sees_their_own_payment_links(): void
    {
        [$user1, $user2] = [$this->userWithWallet(), $this->userWithWallet()];

        PaymentLink::factory()->count(2)->create(['user_id' => $user1->id]);
        PaymentLink::factory()->count(3)->create(['user_id' => $user2->id]);

        $this->assertEquals(2, $this->getJson('/api/payment-links', $this->authHeaders($user1))
                                    ->json('data.total'));
    }

    public function test_list_payment_links_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->getJson('/api/payment-links'));
    }

    // ── Pay ───────────────────────────────────────────────────────────────────

    public function test_payer_can_pay_a_payment_link(): void
    {
        $owner = $this->userWithWallet(0.00);
        $payer = $this->userWithWallet(1000.00);
        $link  = $this->activeLink($owner, 300.00);

        $response = $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($payer));

        $this->assertSuccessResponse($response, 201);
        $this->assertBalance($payer, 700.00);
        $this->assertBalance($owner, 300.00);
        $this->assertDatabaseHas('payment_links', [
            'id'      => $link->id,
            'status'  => 'paid',
            'paid_by' => $payer->id,
        ]);
        $this->assertTransactionRecorded([
            'sender_id'   => $payer->id,
            'receiver_id' => $owner->id,
            'amount'      => '300.00',
            'type'        => 'payment_link',
        ]);
    }

    public function test_payment_link_cannot_be_paid_twice(): void
    {
        $owner = $this->userWithWallet(0.00);
        $payer = $this->userWithWallet(2000.00);
        $link  = $this->activeLink($owner, 300.00);

        $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($payer));
        $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($payer))->assertStatus(422);

        $this->assertBalance($owner, 300.00); // received once, not twice
    }

    public function test_user_cannot_pay_their_own_payment_link(): void
    {
        $user = $this->userWithWallet(1000.00);
        $link = $this->activeLink($user, 100.00);

        $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($user))->assertStatus(422);

        $this->assertBalance($user, 1000.00);
    }

    public function test_payment_link_fails_with_insufficient_balance(): void
    {
        $owner = $this->userWithWallet(0.00);
        $payer = $this->userWithWallet(50.00);
        $link  = $this->activeLink($owner, 500.00);

        $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($payer))->assertStatus(422);

        $this->assertBalance($payer, 50.00);
        $this->assertBalance($owner, 0.00);
    }

    public function test_paying_nonexistent_link_returns_404(): void
    {
        $payer = $this->userWithWallet(1000.00);

        $this->postJson('/api/pay/PAY-INVALID', [], $this->authHeaders($payer))->assertStatus(404);
    }

    public function test_pay_payment_link_requires_authentication(): void
    {
        $link = $this->activeLink($this->userWithWallet());

        $this->assertRequiresAuth($this->postJson("/api/pay/{$link->code}"));
    }

    public function test_correct_user_receives_funds_from_payment_link(): void
    {
        $owner = $this->userWithWallet(0.00);
        $payer = $this->userWithWallet(1000.00);
        $other = $this->userWithWallet(0.00);
        $link  = $this->activeLink($owner, 200.00);

        $this->postJson("/api/pay/{$link->code}", [], $this->authHeaders($payer));

        $this->assertBalance($owner, 200.00);
        $this->assertBalance($other, 0.00); // unrelated user untouched
    }
}
