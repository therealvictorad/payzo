<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PaymentLinkFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id'     => User::factory(),
            'code'        => 'PAY-' . strtoupper(Str::random(8)),
            'amount'      => fake()->randomFloat(2, 100, 5000),
            'description' => fake()->optional()->sentence(),
            'status'      => 'active',
            'paid_by'     => null,
            'paid_at'     => null,
        ];
    }

    public function paid(): static
    {
        return $this->state(fn () => [
            'status'  => 'paid',
            'paid_by' => User::factory(),
            'paid_at' => now(),
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn () => ['status' => 'expired']);
    }
}
