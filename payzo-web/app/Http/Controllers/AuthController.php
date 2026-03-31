<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Services\AuthService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly AuthService $authService) {}

    /**
     * POST /api/register
     * Supports optional ?ref=CODE query param for referral.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();

        // Allow referral code from either the request body or ?ref= query param
        if (empty($data['referral_code']) && $request->query('ref')) {
            $data['referral_code'] = $request->query('ref');
        }

        $result = $this->authService->register($data);

        return $this->success('Registration successful', $result, 201);
    }

    /**
     * POST /api/login
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login($request->validated());

        if (!$result) {
            return $this->error('Invalid credentials', 401);
        }

        return $this->success('Login successful', $result);
    }

    /**
     * POST /api/logout  (requires auth)
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return $this->success('Logged out successfully');
    }
}
