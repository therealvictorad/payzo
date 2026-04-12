<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class PinController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/pin/set
     * Set or update the transaction PIN.
     */
    public function set(Request $request): JsonResponse
    {
        $request->validate([
            'pin'              => ['required', 'digits:4', 'confirmed'],
            'pin_confirmation' => ['required', 'digits:4'],
        ]);

        $request->user()->update([
            'transaction_pin' => $request->pin, // hashed via model cast
        ]);

        return $this->success('Transaction PIN set successfully.');
    }

    /**
     * POST /api/v1/pin/verify
     * Verify PIN before a sensitive action (called client-side before transfer).
     */
    public function verify(Request $request): JsonResponse
    {
        $request->validate([
            'pin' => ['required', 'digits:4'],
        ]);

        $user = $request->user();

        if (! $user->hasTransactionPin()) {
            return $this->error('No transaction PIN set. Please set a PIN first.', 403);
        }

        if (! Hash::check($request->pin, $user->transaction_pin)) {
            throw ValidationException::withMessages([
                'pin' => 'Incorrect transaction PIN.',
            ]);
        }

        return $this->success('PIN verified.');
    }
}
