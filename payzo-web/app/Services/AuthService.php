<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;

class AuthService
{
    /**
     * Register a new user, auto-create their wallet, and handle referral linking.
     */
    public function register(array $data): array
    {
        $referrer = null;

        // Resolve referrer from referral_code if provided
        if (!empty($data['referral_code'])) {
            $referrer = User::where('referral_code', $data['referral_code'])->first();
        }

        $user = User::create([
            'name'          => $data['name'],
            'email'         => $data['email'],
            'password'      => $data['password'], // hashed automatically via cast
            'role'          => $data['role'] ?? 'user',
            'referred_by'   => $referrer?->id,
            // Agents get a unique referral code; regular users do not
            'referral_code' => ($data['role'] ?? 'user') === 'agent' ? Str::upper(Str::random(8)) : null,
        ]);

        // Auto-create wallet with zero balance
        $user->wallet()->create(['balance' => 0.00]);

        $token = $user->createToken('api-token')->plainTextToken;

        return ['user' => $user->load('wallet'), 'token' => $token];
    }

    /**
     * Validate credentials and return an API token.
     */
    public function login(array $credentials): ?array
    {
        if (!Auth::attempt(['email' => $credentials['email'], 'password' => $credentials['password']])) {
            return null;
        }

        /** @var User $user */
        $user = Auth::user();

        // Revoke all previous tokens for a clean session
        $user->tokens()->delete();

        $token = $user->createToken('api-token')->plainTextToken;

        return ['user' => $user->load('wallet'), 'token' => $token];
    }

    /**
     * Revoke the current user's token (logout).
     */
    public function logout(User $user): void
    {
        $user->currentAccessToken()->delete();
    }
}
