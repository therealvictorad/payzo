<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Repositories\WalletRepository;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly WalletRepository $walletRepo) {}

    public function show(Request $request): JsonResponse
    {
        $user    = $request->user();
        $balance = $this->walletRepo->getBalance($user);

        return $this->success('Wallet retrieved', [
            'id'      => $user->wallet->id,
            'user_id' => $user->id,
            'balance' => number_format($balance, 2, '.', ''),
        ]);
    }
}
