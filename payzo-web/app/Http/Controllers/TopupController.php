<?php

namespace App\Http\Controllers;

use App\Http\Requests\TopupRequest;
use App\Services\TopupService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TopupController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly TopupService $topupService) {}

    /**
     * POST /api/topup
     */
    public function topup(TopupRequest $request): JsonResponse
    {
        $transaction = $this->topupService->process(
            $request->user(),
            $request->validated()
        );

        return $this->success('Top-up successful', $transaction, 201);
    }
}
