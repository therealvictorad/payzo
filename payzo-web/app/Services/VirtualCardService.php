<?php

namespace App\Services;

use App\Models\VirtualCard;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class VirtualCardService
{
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

        $rawNumber = $this->generateCardNumber();
        $rawCvv    = $this->generateCvv();

        // Model mutators encrypt card_number and cvv before saving
        $card = VirtualCard::create([
            'user_id'        => $user->id,
            'card_number'    => $rawNumber,
            'expiry'         => $this->generateExpiry(),
            'cvv'            => $rawCvv,
            'card_holder'    => strtoupper($user->name),
            'brand'          => collect(['visa', 'mastercard'])->random(),
            'status'         => 'active',
            'spending_limit' => 500.00,
        ]);

        // Return full details ONCE on creation — raw values before encryption
        return [
            'id'             => $card->id,
            'card_number'    => $rawNumber,   // plaintext shown once only
            'expiry'         => $card->expiry,
            'cvv'            => $rawCvv,       // plaintext shown once only
            'card_holder'    => $card->card_holder,
            'brand'          => $card->brand,
            'status'         => $card->status,
            'spending_limit' => $card->spending_limit,
            'created_at'     => $card->created_at,
        ];
    }

    public function getUserCards(User $user): \Illuminate\Support\Collection
    {
        return VirtualCard::where('user_id', $user->id)
            ->get()
            ->map(fn ($card) => [
                'id'             => $card->id,
                'masked_number'  => $card->masked_number,  // uses accessor
                'expiry'         => $card->expiry,
                'masked_cvv'     => '***',
                'card_holder'    => $card->card_holder,
                'brand'          => $card->brand,
                'status'         => $card->status,
                'spending_limit' => $card->spending_limit,
                'created_at'     => $card->created_at,
            ]);
    }

    private function generateCardNumber(): string
    {
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
