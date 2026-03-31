<?php

namespace App\Http\Controllers;

use App\Services\WalletService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly WalletService $walletService) {}

    /**
     * GET /api/wallet
     * Returns the authenticated user's wallet balance.
     */
    public function show(Request $request): JsonResponse
    {
        $wallet = $this->walletService->getWallet($request->user());

        return $this->success('Wallet retrieved', $wallet);
    }
}
