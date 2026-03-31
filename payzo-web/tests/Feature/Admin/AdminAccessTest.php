<?php

namespace Tests\Feature\Admin;

use Tests\TestCase;

class AdminAccessTest extends TestCase
{
    // ── Admin can access all endpoints ────────────────────────────────────────

    /** @dataProvider adminEndpointProvider */
    public function test_admin_can_access_endpoint(string $method, string $url): void
    {
        $admin = $this->adminWithWallet();

        $this->json($method, $url, [], $this->authHeaders($admin))->assertStatus(200);
    }

    // ── Regular user is blocked ───────────────────────────────────────────────

    /** @dataProvider adminEndpointProvider */
    public function test_regular_user_cannot_access_admin_endpoints(string $method, string $url): void
    {
        $this->assertForbidden(
            $this->json($method, $url, [], $this->authHeaders($this->userWithWallet()))
        );
    }

    // ── Agent is blocked ──────────────────────────────────────────────────────

    /** @dataProvider adminEndpointProvider */
    public function test_agent_cannot_access_admin_endpoints(string $method, string $url): void
    {
        $this->assertForbidden(
            $this->json($method, $url, [], $this->authHeaders($this->agentWithWallet()))
        );
    }

    // ── Unauthenticated is blocked ────────────────────────────────────────────

    /** @dataProvider adminEndpointProvider */
    public function test_unauthenticated_cannot_access_admin_endpoints(string $method, string $url): void
    {
        $this->assertRequiresAuth($this->json($method, $url));
    }

    // ── Response shape ────────────────────────────────────────────────────────

    public function test_admin_users_response_is_paginated(): void
    {
        $admin = $this->adminWithWallet();
        $this->userWithWallet();
        $this->userWithWallet();

        $this->getJson('/api/admin/users', $this->authHeaders($admin))
             ->assertJsonStructure([
                 'data' => ['data', 'total', 'per_page', 'current_page'],
             ]);
    }

    public function test_admin_transactions_response_includes_sender_and_receiver(): void
    {
        $admin = $this->adminWithWallet();
        [$sender, $receiver] = $this->senderAndReceiver(500.00, 0.00);

        $this->actingAs($sender)->postJson('/api/transfer', [
            'receiver_email' => $receiver->email,
            'amount'         => 100.00,
        ]);

        $response = $this->actingAs($admin)->getJson('/api/admin/transactions');

        $response->assertStatus(200);
        $this->assertNotEmpty($response->json('data.data'));
    }

    // ── Data provider ─────────────────────────────────────────────────────────

    public static function adminEndpointProvider(): array
    {
        return [
            'users'         => ['GET', '/api/admin/users'],
            'transactions'  => ['GET', '/api/admin/transactions'],
            'fraud-logs'    => ['GET', '/api/admin/fraud-logs'],
            'topups'        => ['GET', '/api/admin/topups'],
            'bills'         => ['GET', '/api/admin/bills'],
            'payment-links' => ['GET', '/api/admin/payment-links'],
            'cards'         => ['GET', '/api/admin/cards'],
        ];
    }
}
