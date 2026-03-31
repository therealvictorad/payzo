<?php

namespace Tests\Feature\Topup;

use App\Models\Transaction;
use Tests\TestCase;

class TopupTest extends TestCase
{
    public function test_user_can_topup_airtime_successfully(): void
    {
        $user = $this->userWithWallet(1000.00);

        $response = $this->topup($user);

        $this->assertSuccessResponse($response, 201);
        $this->assertBalance($user, 800.00);
        $this->assertTransactionRecorded([
            'sender_id' => $user->id,
            'amount'    => '200.00',
            'type'      => 'airtime',
        ]);
    }

    public function test_user_can_topup_data_successfully(): void
    {
        $user = $this->userWithWallet(1000.00);

        $this->assertSuccessResponse($this->topup($user, ['type' => 'data', 'amount' => 500.00]), 201);
        $this->assertBalance($user, 500.00);
    }

    public function test_topup_fails_with_insufficient_balance(): void
    {
        $user = $this->userWithWallet(100.00);

        $this->topup($user, ['amount' => 500.00])->assertStatus(422);

        $this->assertBalance($user, 100.00);
        $this->assertNoTransactionCreated();
    }

    /** @dataProvider invalidTopupFieldProvider */
    public function test_topup_fails_with_invalid_field(array $override, string $field): void
    {
        $user = $this->userWithWallet(1000.00);

        $this->assertValidationError($this->topup($user, $override), $field);
    }

    public static function invalidTopupFieldProvider(): array
    {
        return [
            'invalid network'      => [['network' => 'FAKE_NETWORK'], 'network'],
            'invalid type'         => [['type' => 'crypto'],           'type'],
            'below minimum amount' => [['amount' => 10.00],            'amount'],
            'above maximum amount' => [['amount' => 60000.00],         'amount'],
            'invalid phone number' => [['phone_number' => 'not-phone'],'phone_number'],
        ];
    }

    public function test_topup_fails_with_missing_fields(): void
    {
        $user = $this->userWithWallet(1000.00);

        $this->assertValidationError(
            $this->postJson('/api/topup', [], $this->authHeaders($user)),
            ['phone_number', 'network', 'type', 'amount']
        );
    }

    public function test_topup_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->postJson('/api/topup', []));
    }

    public function test_topup_meta_contains_correct_data(): void
    {
        $user = $this->userWithWallet(1000.00);

        $this->topup($user, [
            'phone_number' => '08099887766',
            'network'      => 'Airtel',
            'type'         => 'airtime',
            'amount'       => 100.00,
        ]);

        $meta = Transaction::where('sender_id', $user->id)->first()->meta;

        $this->assertEquals('08099887766', $meta['phone_number']);
        $this->assertEquals('Airtel', $meta['network']);
        $this->assertEquals('airtime', $meta['topup_type']);
    }
}
