<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Repositories\KycRepository;
use App\Services\KycService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminKycController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly KycService $kycService,
        private readonly KycRepository $kycRepo
    ) {}

    /**
     * GET /api/v1/admin/kyc
     * Paginated list of all KYC submissions.
     */
    public function index(Request $request): JsonResponse
    {
        $documents = $this->kycRepo->paginate(
            $request->only(['status', 'document_type'])
        );

        return $this->success('KYC submissions retrieved', $documents);
    }

    /**
     * POST /api/v1/admin/kyc/{id}/approve
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        $document = $this->kycService->approve($id, $request->user());

        return $this->success('KYC approved. User upgraded to tier2.', [
            'document_id' => $document->id,
            'user_email'  => $document->user->email,
            'kyc_level'   => $document->user->kyc_level,
            'kyc_status'  => $document->user->kyc_status,
        ]);
    }

    /**
     * POST /api/v1/admin/kyc/{id}/reject
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $document = $this->kycService->reject($id, $request->user(), $request->reason);

        return $this->success('KYC rejected.', [
            'document_id'      => $document->id,
            'user_email'       => $document->user->email,
            'rejection_reason' => $document->rejection_reason,
        ]);
    }
}
