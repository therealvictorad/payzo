<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\KycSubmitRequest;
use App\Services\KycService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KycController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly KycService $kycService) {}

    /**
     * POST /api/v1/kyc/submit
     * Submit KYC documents for review.
     */
    public function submit(KycSubmitRequest $request): JsonResponse
    {
        $document = $this->kycService->submit(
            $request->user(),
            $request->validated(),
            $request->file('document')
        );

        return $this->success('KYC submitted successfully. Under review.', [
            'id'            => $document->id,
            'document_type' => $document->document_type,
            'status'        => $document->status,
            'submitted_at'  => $document->created_at,
        ], 201);
    }

    /**
     * GET /api/v1/kyc/status
     * Get current KYC level and status.
     */
    public function status(Request $request): JsonResponse
    {
        $status = $this->kycService->getStatus($request->user());

        return $this->success('KYC status retrieved', $status);
    }
}
