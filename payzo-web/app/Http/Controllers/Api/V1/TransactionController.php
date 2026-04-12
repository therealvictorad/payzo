<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\TransferRequest;
use App\Services\TransactionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly TransactionService $transactionService) {}

    /**
     * POST /api/v1/transfer
     *
     * Clients should send a unique Idempotency-Key header with every request.
     * If the same key is sent twice, the original result is returned safely.
     */
    public function transfer(TransferRequest $request): JsonResponse
    {
        $idempotencyKey = $request->header('Idempotency-Key');

        $transaction = $this->transactionService->transfer(
            $request->user(),
            $request->validated(),
            $idempotencyKey
        );

        return $this->success('Transfer successful', $transaction, 201);
    }

    /**
     * GET /api/v1/transactions
     */
    public function index(Request $request): JsonResponse
    {
        $transactions = $this->transactionService->getHistory($request->user());

        return $this->success('Transactions retrieved', $transactions);
    }
}
