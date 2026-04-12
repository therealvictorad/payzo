<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\BillPayRequest;
use App\Services\BillService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class BillController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly BillService $billService) {}

    public function pay(BillPayRequest $request): JsonResponse
    {
        $transaction = $this->billService->pay(
            $request->user(),
            $request->validated()
        );

        return $this->success('Bill payment successful', $transaction, 201);
    }
}
