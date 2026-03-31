<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Tests\TestCase;

class RegisterTest extends TestCase
{
    // ── Helpers ───────────────────────────────────────────────────────────────

    private function registerPayload(array $overrides = []): array
    {
        return array_merge([
            'name'                  => 'John Doe',
            'email'                 => 'john@example.com',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ], $overrides);
    }

    private function register(array $overrides = [])
    {
        return $this->postJson('/api/register', $this->registerPayload($overrides));
    }

    // ── Register ──────────────────────────────────────────────────────────────

    public function test_user_can_register_successfully(): void
    {
        $response = $this->register();

        $this->assertSuccessResponse($response, 201);
        $response->assertJsonStructure([
            'data' => ['user' => ['id', 'name', 'email', 'role', 'wallet'], 'token'],
        ]);
        $this->assertDatabaseHas('users', ['email' => 'john@example.com', 'role' => 'user']);
        $this->assertDatabaseHas('wallets', ['balance' => '0.00']);
    }

    public function test_agent_can_register_with_role(): void
    {
        $response = $this->register(['email' => 'agent@example.com', 'role' => 'agent']);

        $this->assertSuccessResponse($response, 201);
        $this->assertDatabaseHas('users', ['email' => 'agent@example.com', 'role' => 'agent']);

        $user = User::where('email', 'agent@example.com')->first();
        $this->assertNotNull($user->referral_code);
    }

    public function test_admin_role_cannot_be_self_registered(): void
    {
        $response = $this->register(['email' => 'fake@example.com', 'role' => 'admin']);

        $response->assertStatus(422);
        $this->assertDatabaseMissing('users', ['email' => 'fake@example.com']);
    }

    public function test_register_with_valid_referral_code(): void
    {
        $agent = User::factory()->create(['role' => 'agent', 'referral_code' => 'AGENT001']);

        $response = $this->register([
            'email'         => 'referred@example.com',
            'referral_code' => 'AGENT001',
        ]);

        $this->assertSuccessResponse($response, 201);
        $this->assertDatabaseHas('users', [
            'email'       => 'referred@example.com',
            'referred_by' => $agent->id,
        ]);
    }

    public function test_register_with_invalid_referral_code_fails(): void
    {
        $this->assertValidationError(
            $this->register(['referral_code' => 'INVALID99']),
            'referral_code'
        );
    }

    public function test_register_fails_with_duplicate_email(): void
    {
        User::factory()->create(['email' => 'john@example.com']);

        $this->assertValidationError($this->register(), 'email');
    }

    public function test_register_fails_with_missing_fields(): void
    {
        $this->assertValidationError(
            $this->postJson('/api/register', []),
            ['name', 'email', 'password']
        );
    }

    public function test_register_fails_with_password_too_short(): void
    {
        $this->assertValidationError(
            $this->register(['password' => '123', 'password_confirmation' => '123']),
            'password'
        );
    }

    public function test_register_fails_when_passwords_do_not_match(): void
    {
        $this->assertValidationError(
            $this->register(['password_confirmation' => 'different123']),
            'password'
        );
    }

    public function test_register_fails_with_invalid_email_format(): void
    {
        $this->assertValidationError(
            $this->register(['email' => 'not-an-email']),
            'email'
        );
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    public function test_user_can_login_with_valid_credentials(): void
    {
        $user = $this->userWithWallet();

        $response = $this->postJson('/api/login', [
            'email'    => $user->email,
            'password' => 'password',
        ]);

        $this->assertSuccessResponse($response);
        $response->assertJsonStructure(['data' => ['user', 'token']]);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $user = $this->userWithWallet();

        $this->assertErrorResponse(
            $this->postJson('/api/login', ['email' => $user->email, 'password' => 'wrong']),
            401
        );
    }

    public function test_login_fails_with_nonexistent_email(): void
    {
        $this->postJson('/api/login', [
            'email'    => 'ghost@example.com',
            'password' => 'password',
        ])->assertStatus(401);
    }

    public function test_login_fails_with_missing_fields(): void
    {
        $this->assertValidationError(
            $this->postJson('/api/login', []),
            ['email', 'password']
        );
    }

    public function test_login_revokes_previous_tokens(): void
    {
        $user = $this->userWithWallet();
        $user->createToken('old-token');
        $this->assertEquals(1, $user->tokens()->count());

        $this->postJson('/api/login', ['email' => $user->email, 'password' => 'password']);

        $this->assertEquals(1, $user->fresh()->tokens()->count());
    }

    // ── Logout ────────────────────────────────────────────────────────────────

    public function test_user_can_logout(): void
    {
        $user = $this->userWithWallet();

        $this->assertSuccessResponse(
            $this->postJson('/api/logout', [], $this->authHeaders($user))
        );
        $this->assertEquals(0, $user->fresh()->tokens()->count());
    }

    public function test_logout_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->postJson('/api/logout'));
    }
}
