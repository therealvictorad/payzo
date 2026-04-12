<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Get user profile
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load('wallet');
        
        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => $user
            ]
        ]);
    }

    /**
     * Update user profile
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nickname' => 'nullable|string|max:255',
            'gender' => ['nullable', 'string', Rule::in(['Male', 'Female', 'Other'])],
            'date_of_birth' => 'nullable|date|before:today',
            'mobile' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $user->update($validated);
        
        // Reload user with wallet for consistent response
        $user->load('wallet');

        return response()->json([
            'status' => 'success',
            'message' => 'Profile updated successfully',
            'data' => [
                'user' => $user
            ]
        ]);
    }
}