<?php

namespace App\Http\Controllers;

use App\Http\Requests\PaymentLinkRequest;
use App\Services\PaymentLinkService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentLinkController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly PaymentLinkService $paymentLinkService) {}

    /**
     * POST /api/payment-links
     */
    public function create(PaymentLinkRequest $request): JsonResponse
    {
        $link = $this->paymentLinkService->create(
            $request->user(),
            $request->validated()
        );

        return $this->success('Payment link created', $link, 201);
    }

    /**
     * GET /api/payment-links
     */
    public function index(Request $request): JsonResponse
    {
        $links = $this->paymentLinkService->getUserLinks($request->user());

        return $this->success('Payment links retrieved', $links);
    }

    /**
     * POST /api/pay/{code}  — public endpoint, payer must be authenticated
     */
    public function pay(Request $request, string $code): JsonResponse
    {
        $result = $this->paymentLinkService->pay($code, $request->user());

        return $this->success('Payment successful', $result, 201);
    }
}
