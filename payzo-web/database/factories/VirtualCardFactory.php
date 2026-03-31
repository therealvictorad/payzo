<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class VirtualCardFactory extends Factory
{
    public function definition(): array
    {
        $prefix = fake()->randomElement(['4', '5']);

        return [
            'user_id'        => User::factory(),
            'card_number'    => $prefix . fake()->numerify('###############'),
            'expiry'         => fake()->creditCardExpirationDateString(true, 'y'),
            'cvv'            => fake()->numerify('###'),
            'card_holder'    => strtoupper(fake()->name()),
            'brand'          => fake()->randomElement(['visa', 'mastercard']),
            'status'         => 'active',
            'spending_limit' => 500.00,
        ];
    }

    public function frozen(): static
    {
        return $this->state(fn () => ['status' => 'frozen']);
    }

    public function terminated(): static
    {
        return $this->state(fn () => ['status' => 'terminated']);
    }
}
