<?php

namespace App\Http\Controllers;

use App\Http\Requests\BillPayRequest;
use App\Services\BillService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class BillController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly BillService $billService) {}

    /**
     * POST /api/bills/pay
     */
    public function pay(BillPayRequest $request): JsonResponse
    {
        $transaction = $this->billService->pay(
            $request->user(),
            $request->validated()
        );

        return $this->success('Bill payment successful', $transaction, 201);
    }
}
