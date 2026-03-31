<?php

namespace App\Http\Controllers;

use App\Http\Requests\TransferRequest;
use App\Services\TransactionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly TransactionService $transactionService) {}

    /**
     * POST /api/transfer
     * Send money to another user by email.
     */
    public function transfer(TransferRequest $request): JsonResponse
    {
        $transaction = $this->transactionService->transfer(
            $request->user(),
            $request->validated()
        );

        return $this->success('Transfer successful', $transaction, 201);
    }

    /**
     * GET /api/transactions
     * Returns paginated transaction history for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $transactions = $this->transactionService->getHistory($request->user());

        return $this->success('Transactions retrieved', $transactions);
    }
}
