<?php

namespace Tests\Feature\VirtualCards;

use App\Models\VirtualCard;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class VirtualCardTest extends TestCase
{
    // ── Helpers ───────────────────────────────────────────────────────────────

    private function createCard(string $role = 'user'): TestResponse
    {
        $user = $this->userWithWallet(0, $role);
        return $this->postJson('/api/cards', [], $this->authHeaders($user));
    }

    // ── Create ────────────────────────────────────────────────────────────────

    public function test_user_can_create_a_virtual_card(): void
    {
        $user = $this->userWithWallet();

        $response = $this->postJson('/api/cards', [], $this->authHeaders($user));

        $this->assertSuccessResponse($response, 201);
        $response->assertJsonStructure([
            'data' => ['id', 'card_number', 'expiry', 'cvv', 'card_holder', 'brand', 'status', 'spending_limit'],
        ]);
        $this->assertDatabaseHas('virtual_cards', ['user_id' => $user->id, 'status' => 'active']);
    }

    public function test_card_holder_name_matches_user_name_in_uppercase(): void
    {
        $user = $this->userWithWallet();
        $user->update(['name' => 'John Doe']);

        $this->assertEquals(
            'JOHN DOE',
            $this->postJson('/api/cards', [], $this->authHeaders($user))->json('data.card_holder')
        );
    }

    /** @dataProvider cardFieldFormatProvider */
    public function test_card_fields_have_correct_format(string $field, string $pattern): void
    {
        $data = $this->createCard()->json('data');

        $this->assertMatchesRegularExpression($pattern, (string) $data[$field]);
    }

    public static function cardFieldFormatProvider(): array
    {
        return [
            'card_number is 16 digits'  => ['card_number', '/^\d{16}$/'],
            'expiry is MM/YY format'    => ['expiry',      '/^\d{2}\/\d{2}$/'],
            'cvv is 3 digits'           => ['cvv',         '/^\d{3}$/'],
        ];
    }

    public function test_card_brand_is_visa_or_mastercard(): void
    {
        $this->assertContains($this->createCard()->json('data.brand'), ['visa', 'mastercard']);
    }

    public function test_default_spending_limit_is_500(): void
    {
        $this->assertEquals(500.00, $this->createCard()->json('data.spending_limit'));
    }

    public function test_user_cannot_create_duplicate_active_card(): void
    {
        $user = $this->userWithWallet();

        $this->postJson('/api/cards', [], $this->authHeaders($user));
        $this->postJson('/api/cards', [], $this->authHeaders($user))->assertStatus(422);

        $this->assertDatabaseCount('virtual_cards', 1);
    }

    public function test_create_card_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->postJson('/api/cards'));
    }

    // ── List ──────────────────────────────────────────────────────────────────

    public function test_user_can_list_their_cards(): void
    {
        $user = $this->userWithWallet();
        VirtualCard::factory()->count(2)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/cards', $this->authHeaders($user));

        $this->assertSuccessResponse($response);
        $this->assertCount(2, $response->json('data'));
    }

    public function test_listed_cards_have_masked_sensitive_fields(): void
    {
        $user = $this->userWithWallet();
        $this->postJson('/api/cards', [], $this->authHeaders($user));

        $card = $this->getJson('/api/cards', $this->authHeaders($user))->json('data.0');

        $this->assertEquals('***', $card['masked_cvv']);
        $this->assertArrayNotHasKey('card_number', $card);
        $this->assertArrayHasKey('masked_number', $card);
    }

    public function test_user_only_sees_their_own_cards(): void
    {
        [$user1, $user2] = [$this->userWithWallet(), $this->userWithWallet()];

        VirtualCard::factory()->count(2)->create(['user_id' => $user1->id]);
        VirtualCard::factory()->count(3)->create(['user_id' => $user2->id]);

        $this->assertCount(2, $this->getJson('/api/cards', $this->authHeaders($user1))->json('data'));
    }

    public function test_list_cards_requires_authentication(): void
    {
        $this->assertRequiresAuth($this->getJson('/api/cards'));
    }
}
