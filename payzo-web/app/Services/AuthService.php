<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class AuthService
{
    public function register(array $data): array
    {
        $referrer = null;

        if (! empty($data['referral_code'])) {
            $referrer = User::where('referral_code', $data['referral_code'])->first();
        }

        $user = User::create([
            'name'          => $data['name'],
            'email'         => $data['email'],
            'password'      => $data['password'],
            'role'          => $data['role'] ?? 'user',
            'referred_by'   => $referrer?->id,
            'referral_code' => ($data['role'] ?? 'user') === 'agent'
                                   ? Str::upper(Str::random(8))
                                   : null,
        ]);

        $user->wallet()->create(['balance' => 0.00]);

        // Send email verification
        $user->sendEmailVerificationNotification();

        // Named token — device-specific, does not revoke other sessions
        $token = $user->createToken('mobile-app')->plainTextToken;

        return ['user' => $user->load('wallet'), 'token' => $token];
    }

    public function login(array $credentials): ?array
    {
        if (! Auth::attempt([
            'email'    => $credentials['email'],
            'password' => $credentials['password'],
        ])) {
            return null;
        }

        /** @var User $user */
        $user = Auth::user();

        // Only revoke tokens named 'mobile-app' — leaves admin dashboard tokens intact
        $user->tokens()->where('name', 'mobile-app')->delete();

        // Auto-upgrade to tier1 when email is verified and user is still on tier0
        if ($user->hasVerifiedEmail() && $user->kyc_level === 'tier0') {
            $user->update(['kyc_level' => 'tier1']);
        }

        $token = $user->createToken('mobile-app')->plainTextToken;

        return ['user' => $user->load('wallet'), 'token' => $token];
    }

    public function logout(User $user): void
    {
        // Only revoke the token used in this request
        $user->currentAccessToken()->delete();
    }
}
