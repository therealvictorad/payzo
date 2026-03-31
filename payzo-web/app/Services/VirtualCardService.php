<?php

namespace App\Services;

use App\Models\VirtualCard;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class VirtualCardService
{
    /**
     * Generate a new virtual card for the user.
     * One active card per user maximum.
     */
    public function create(User $user): array
    {
        $activeCard = VirtualCard::where('user_id', $user->id)
            ->where('status', 'active')
            ->first();

        if ($activeCard) {
            throw ValidationException::withMessages([
                'card' => 'You already have an active virtual card.',
            ]);
        }

        $card = VirtualCard::create([
            'user_id'        => $user->id,
            'card_number'    => $this->generateCardNumber(),
            'expiry'         => $this->generateExpiry(),
            'cvv'            => $this->generateCvv(),
            'card_holder'    => strtoupper($user->name),
            'brand'          => collect(['visa', 'mastercard'])->random(),
            'status'         => 'active',
            'spending_limit' => 500.00,
        ]);

        // Return full details ONCE on creation — never again after this
        return [
            'id'             => $card->id,
            'card_number'    => $card->card_number,   // full number shown once
            'expiry'         => $card->expiry,
            'cvv'            => $card->cvv,            // CVV shown once
            'card_holder'    => $card->card_holder,
            'brand'          => $card->brand,
            'status'         => $card->status,
            'spending_limit' => $card->spending_limit,
            'created_at'     => $card->created_at,
        ];
    }

    /**
     * Return user's cards with sensitive fields masked.
     */
    public function getUserCards(User $user)
    {
        return VirtualCard::where('user_id', $user->id)
            ->get()
            ->map(fn ($card) => [
                'id'             => $card->id,
                'masked_number'  => $card->masked_number_attribute,
                'expiry'         => $card->expiry,
                'masked_cvv'     => '***',
                'card_holder'    => $card->card_holder,
                'brand'          => $card->brand,
                'status'         => $card->status,
                'spending_limit' => $card->spending_limit,
                'created_at'     => $card->created_at,
            ]);
    }

    // ─── Generators ───────────────────────────────────────────────────────────

    private function generateCardNumber(): string
    {
        // Visa prefix: 4, Mastercard prefix: 5
        $prefix = collect(['4', '5'])->random();
        return $prefix . implode('', array_map(fn () => rand(0, 9), range(1, 15)));
    }

    private function generateExpiry(): string
    {
        $month = str_pad(rand(1, 12), 2, '0', STR_PAD_LEFT);
        $year  = now()->addYears(rand(2, 5))->format('y');
        return "{$month}/{$year}";
    }

    private function generateCvv(): string
    {
        return str_pad(rand(0, 999), 3, '0', STR_PAD_LEFT);
    }
}
