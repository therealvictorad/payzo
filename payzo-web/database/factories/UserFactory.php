<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'name'              => fake()->name(),
            'email'             => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password'          => static::$password ??= Hash::make('password'),
            'role'              => 'user',
            'referral_code'     => null,
            'referred_by'       => null,
            'remember_token'    => Str::random(10),
        ];
    }

    /** Produce an agent user with a unique referral code. */
    public function agent(): static
    {
        return $this->state(fn () => [
            'role'          => 'agent',
            'referral_code' => Str::upper(Str::random(8)),
        ]);
    }

    /** Produce an admin user. */
    public function admin(): static
    {
        return $this->state(fn () => [
            'role' => 'admin',
        ]);
    }

    /** Mark email as unverified. */
    public function unverified(): static
    {
        return $this->state(fn () => ['email_verified_at' => null]);
    }
}
