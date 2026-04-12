<?php

namespace App\Services;

use App\Jobs\SendKycNotification;
use App\Models\KycDocument;
use App\Models\User;
use App\Repositories\AuditLogRepository;
use App\Repositories\KycRepository;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class KycService
{
    public function __construct(
        private readonly KycRepository $kycRepo,
        private readonly AuditLogRepository $auditRepo
    ) {}

    /**
     * Submit KYC documents.
     *
     * Rules:
     * - Already verified → block
     * - Already pending  → block (no duplicate submissions)
     * - Previously rejected → mark old submission as superseded, allow new one
     *
     * @throws ValidationException
     */
    public function submit(User $user, array $data, UploadedFile $file): KycDocument
    {
        if ($user->kyc_status === 'verified') {
            throw ValidationException::withMessages([
                'kyc' => 'Your account is already verified.',
            ]);
        }

        if ($this->kycRepo->hasPendingSubmission($user)) {
            throw ValidationException::withMessages([
                'kyc' => 'You already have a pending KYC submission. Please wait for review.',
            ]);
        }

        // If resubmitting after rejection — archive the old rejected document
        if ($user->kyc_status === 'rejected') {
            $this->kycRepo->supersedePreviousRejections($user);
        }

        // Store file in private disk — never publicly accessible
        // Path: storage/app/private/kyc/{user_id}/{timestamp}_{filename}
        $filename = time() . '_' . $file->getClientOriginalName();
        $path     = $file->storeAs("kyc/{$user->id}", $filename, 'private');

        $document = $this->kycRepo->create([
            'user_id'         => $user->id,
            'document_type'   => $data['document_type'],
            'document_path'   => $path,
            'document_number' => $data['document_number'],
            'full_name'       => $data['full_name'],
            'date_of_birth'   => $data['date_of_birth'],
            'address'         => $data['address'] ?? null,
            'status'          => 'pending',
        ]);

        $user->update([
            'kyc_status'       => 'pending',
            'kyc_submitted_at' => now(),
        ]);

        return $document;
    }

    /**
     * Get KYC status for the authenticated user.
     * Returns tier info, limits, and latest document state.
     */
    public function getStatus(User $user): array
    {
        $latest = $this->kycRepo->getLatest($user);

        return [
            'kyc_level'         => $user->kyc_level,
            'kyc_status'        => $user->kyc_status,
            'kyc_submitted_at'  => $user->kyc_submitted_at,
            'per_tx_limit'      => $user->kyc_limit,
            'daily_limit'       => $user->kyc_daily_limit,
            'latest_document'   => $latest ? [
                'id'               => $latest->id,
                'document_type'    => $latest->document_type,
                'status'           => $latest->status,
                'rejection_reason' => $latest->rejection_reason,
                'submitted_at'     => $latest->created_at,
                'reviewed_at'      => $latest->reviewed_at,
            ] : null,
        ];
    }

    /**
     * Admin approves a KYC submission.
     * Upgrades user to tier2 + verified.
     * Logs the action and dispatches notification.
     *
     * @throws ValidationException
     */
    public function approve(int $documentId, User $admin): KycDocument
    {
        $document = $this->kycRepo->findOrFail($documentId);

        // Safety: only pending documents can be approved
        if (! $document->isPending()) {
            throw ValidationException::withMessages([
                'kyc' => 'Only pending submissions can be approved. This one is already ' . $document->status . '.',
            ]);
        }

        $document->update([
            'status'      => 'approved',
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
        ]);

        $document->user->update([
            'kyc_level'  => 'tier2',
            'kyc_status' => 'verified',
        ]);

        // Audit log
        $this->auditRepo->record(
            $admin, 'approve_kyc', $document,
            ['status' => 'pending'],
            ['status' => 'approved', 'kyc_level' => 'tier2'],
            request()->ip()
        );

        // Notify user (queued)
        SendKycNotification::dispatch($document->user, 'approved');

        return $document->fresh('user');
    }

    /**
     * Admin rejects a KYC submission.
     * User can resubmit after rejection.
     *
     * @throws ValidationException
     */
    public function reject(int $documentId, User $admin, string $reason): KycDocument
    {
        $document = $this->kycRepo->findOrFail($documentId);

        // Safety: only pending documents can be rejected
        if (! $document->isPending()) {
            throw ValidationException::withMessages([
                'kyc' => 'Only pending submissions can be rejected. This one is already ' . $document->status . '.',
            ]);
        }

        $document->update([
            'status'           => 'rejected',
            'rejection_reason' => $reason,
            'reviewed_by'      => $admin->id,
            'reviewed_at'      => now(),
        ]);

        $document->user->update([
            'kyc_status' => 'rejected',
        ]);

        // Audit log
        $this->auditRepo->record(
            $admin, 'reject_kyc', $document,
            ['status' => 'pending'],
            ['status' => 'rejected', 'reason' => $reason],
            request()->ip()
        );

        // Notify user (queued)
        SendKycNotification::dispatch($document->user, 'rejected', $reason);

        return $document->fresh('user');
    }

    /**
     * Generate a temporary signed URL for admins to view a KYC document.
     * Valid for 10 minutes only — never a permanent public URL.
     */
    public function getDocumentUrl(KycDocument $document): string
    {
        // Verify the file actually exists before generating URL
        if (! Storage::disk('private')->exists($document->document_path)) {
            throw ValidationException::withMessages([
                'document' => 'Document file not found in storage.',
            ]);
        }

        return Storage::disk('private')->temporaryUrl(
            $document->document_path,
            now()->addMinutes(10)
        );
    }
}
