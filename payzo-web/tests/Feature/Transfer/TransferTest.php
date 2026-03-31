<?php

namespace Tests\Feature\Transfer;

use Tests\TestCase;

class TransferTest extends TestCase
{
    public function test_user_can_transfer_money_successfully(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(1000.00, 0.00);

        $response = $this->transfer($sender, $receiver, 250.00);

        $this->assertSuccessResponse($response, 201);
        $this->assertBalance($sender, 750.00);
        $this->assertBalance($receiver, 250.00);
        $this->assertTransactionRecorded([
            'sender_id'   => $sender->id,
            'receiver_id' => $receiver->id,
            'amount'      => '250.00',
            'type'        => 'transfer',
        ]);
    }

    public function test_transfer_fails_with_insufficient_balance(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(100.00, 0.00);

        $this->transfer($sender, $receiver, 500.00)->assertStatus(422);

        $this->assertBalance($sender, 100.00);
        $this->assertBalance($receiver, 0.00);
        $this->assertNoTransactionCreated();
    }

    public function test_transfer_fails_when_sending_to_self(): void
    {
        $user = $this->userWithWallet(500.00);

        $this->postJson('/api/transfer', [
            'receiver_email' => $user->email,
            'amount'         => 100.00,
        ], $this->authHeaders($user))->assertStatus(422);

        $this->assertBalance($user, 500.00);
    }

    /** @dataProvider invalidAmountProvider */
    public function test_transfer_fails_with_invalid_amount(int|float $amount): void
    {
        [$sender, $receiver] = $this->senderAndReceiver();

        $this->assertValidationError(
            $this->postJson('/api/transfer', [
                'receiver_email' => $receiver->email,
                'amount'         => $amount,
            ], $this->authHeaders($sender)),
            'amount'
        );
    }

    public static function invalidAmountProvider(): array
    {
        return [
            'zero'     => [0],
            'negative' => [-50.00],
        ];
    }

    public function test_transfer_fails_with_nonexistent_receiver_email(): void
    {
        $sender = $this->userWithWallet(500.00);

        $this->assertValidationError(
            $this->postJson('/api/transfer', [
                'receiver_email' => 'ghost@example.com',
                'amount'         => 100.00,
            ], $this->authHeaders($sender)),
            'receiver_email'
        );
    }

    public function test_transfer_fails_with_missing_fields(): void
    {
        $sender = $this->userWithWallet();

        $this->assertValidationError(
            $this->postJson('/api/transfer', [], $this->authHeaders($sender)),
            ['receiver_email', 'amount']
        );
    }

    public function test_transfer_requires_authentication(): void
    {
        $receiver = $this->userWithWallet();

        $this->assertRequiresAuth(
            $this->postJson('/api/transfer', [
                'receiver_email' => $receiver->email,
                'amount'         => 100.00,
            ])
        );
    }

    public function test_transfer_with_exact_balance_succeeds(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(100.00, 0.00);

        $this->transfer($sender, $receiver, 100.00)->assertStatus(201);

        $this->assertBalance($sender, 0.00);
        $this->assertBalance($receiver, 100.00);
    }

    public function test_transfer_response_includes_sender_and_receiver_details(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(500.00, 0.00);

        $this->transfer($sender, $receiver, 50.00)->assertJsonStructure([
            'data' => [
                'id', 'amount', 'status',
                'sender'   => ['id', 'name', 'email'],
                'receiver' => ['id', 'name', 'email'],
            ],
        ]);
    }

    public function test_transaction_history_returns_paginated_results(): void
    {
        [$sender, $receiver] = $this->senderAndReceiver(5000.00, 0.00);

        foreach (range(1, 3) as $i) {
            $this->transfer($sender, $receiver, 10.00);
        }

        $response = $this->getJson('/api/transactions', $this->authHeaders($sender));

        $this->assertSuccessResponse($response);
        $response->assertJsonStructure(['data' => ['data', 'total', 'per_page']]);
        $this->assertEquals(3, $response->json('data.total'));
    }

    public function test_transaction_history_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->getJson('/api/transactions'));
    }

    public function test_sequential_transfers_cannot_overdraw_wallet(): void
    {
        [$sender, $receiver1] = $this->senderAndReceiver(100.00, 0.00);
        $receiver2 = $this->userWithWallet(0.00);

        $this->transfer($sender, $receiver1, 100.00)->assertStatus(201);
        $this->assertBalance($sender, 0.00);

        $this->transfer($sender, $receiver2, 0.01)->assertStatus(422);

        // Total money in system must equal the original 100
        $total = (float) $sender->wallet->fresh()->balance
               + (float) $receiver1->wallet->fresh()->balance
               + (float) $receiver2->wallet->fresh()->balance;

        $this->assertEquals(100.00, $total);
    }
}
