<?php

namespace Tests\Feature\Bills;

use App\Models\Transaction;
use Tests\TestCase;

class BillPaymentTest extends TestCase
{
    public function test_user_can_pay_tv_bill_successfully(): void
    {
        $user = $this->userWithWallet(10000.00);

        $response = $this->payBill($user);

        $this->assertSuccessResponse($response, 201);
        $this->assertBalance($user, 5000.00);
        $this->assertTransactionRecorded([
            'sender_id' => $user->id,
            'amount'    => '5000.00',
            'type'      => 'bill',
        ]);
    }

    public function test_user_can_pay_electricity_bill(): void
    {
        $user = $this->userWithWallet(10000.00);

        $this->assertSuccessResponse(
            $this->payBill($user, ['provider' => 'IKEDC', 'customer_id' => 'METER001', 'amount' => 3000.00]),
            201
        );
        $this->assertBalance($user, 7000.00);
    }

    public function test_bill_payment_fails_with_insufficient_balance(): void
    {
        $user = $this->userWithWallet(200.00);

        $this->payBill($user, ['amount' => 5000.00])->assertStatus(422);

        $this->assertBalance($user, 200.00);
        $this->assertNoTransactionCreated();
    }

    /** @dataProvider invalidBillFieldProvider */
    public function test_bill_payment_fails_with_invalid_field(array $override, string $field): void
    {
        $user = $this->userWithWallet(1000000.00);

        $this->assertValidationError($this->payBill($user, $override), $field);
    }

    public static function invalidBillFieldProvider(): array
    {
        return [
            'invalid provider'     => [['provider' => 'NETFLIX'],   'provider'],
            'below minimum amount' => [['amount' => 50.00],          'amount'],
            'above maximum amount' => [['amount' => 600000.00],      'amount'],
        ];
    }

    public function test_bill_payment_fails_with_missing_fields(): void
    {
        $user = $this->userWithWallet(10000.00);

        $this->assertValidationError(
            $this->postJson('/api/bills/pay', [], $this->authHeaders($user)),
            ['provider', 'customer_id', 'amount']
        );
    }

    public function test_bill_payment_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->postJson('/api/bills/pay', []));
    }

    public function test_bill_meta_contains_provider_and_reference(): void
    {
        $user = $this->userWithWallet(10000.00);

        $this->payBill($user, ['provider' => 'GOtv', 'customer_id' => 'GOTV9988', 'amount' => 1500.00]);

        $meta = Transaction::where('sender_id', $user->id)->first()->meta;

        $this->assertEquals('GOtv', $meta['provider']);
        $this->assertEquals('GOTV9988', $meta['customer_id']);
        $this->assertEquals('tv', $meta['category']);
        $this->assertStringStartsWith('BILL-', $meta['reference']);
    }

    /** @dataProvider validProviderProvider */
    public function test_all_valid_providers_are_accepted(string $provider): void
    {
        $user = $this->userWithWallet(10000.00);

        $this->payBill($user, ['provider' => $provider, 'amount' => 500.00])
             ->assertStatus(201);
    }

    public static function validProviderProvider(): array
    {
        return array_combine(
            ['DSTV', 'GOtv', 'Startimes', 'IKEDC', 'EKEDC', 'AEDC', 'IBEDC'],
            array_map(fn ($p) => [$p], ['DSTV', 'GOtv', 'Startimes', 'IKEDC', 'EKEDC', 'AEDC', 'IBEDC'])
        );
    }
}
