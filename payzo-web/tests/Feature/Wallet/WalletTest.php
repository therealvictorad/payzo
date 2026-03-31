<?php

namespace Tests\Feature\Wallet;

use Tests\TestCase;

class WalletTest extends TestCase
{
    public function test_authenticated_user_can_view_wallet(): void
    {
        $user = $this->userWithWallet(2500.00);

        $response = $this->getJson('/api/wallet', $this->authHeaders($user));

        $this->assertSuccessResponse($response);
        $response->assertJsonPath('data.balance', '2500.00')
                 ->assertJsonPath('data.user_id', $user->id);
    }

    public function test_wallet_reflects_balance_changes(): void
    {
        $user = $this->userWithWallet(500.00);
        $user->wallet->decrement('balance', 200.00);

        $this->getJson('/api/wallet', $this->authHeaders($user))
             ->assertJsonPath('data.balance', '300.00');
    }

    public function test_unauthenticated_user_cannot_view_wallet(): void
    {
        $this->assertRequiresAuth($this->getJson('/api/wallet'));
    }

    public function test_wallet_is_auto_created_on_registration(): void
    {
        $this->postJson('/api/register', [
            'name'                  => 'New User',
            'email'                 => 'newuser@example.com',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $this->assertDatabaseHas('wallets', ['balance' => '0.00']);
    }

    public function test_each_user_has_exactly_one_wallet(): void
    {
        $user = $this->userWithWallet();

        $this->assertEquals(1, $user->wallet()->count());
    }
}
