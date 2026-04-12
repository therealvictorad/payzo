<?php

namespace App\Repositories;

use App\Models\KycDocument;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class KycRepository
{
    /**
     * Check if user already has a pending submission.
     */
    public function hasPendingSubmission(User $user): bool
    {
        return KycDocument::where('user_id', $user->id)
            ->where('status', 'pending')
            ->exists();
    }

    /**
     * Get the user's latest non-superseded KYC document.
     */
    public function getLatest(User $user): ?KycDocument
    {
        return KycDocument::where('user_id', $user->id)
            ->where('status', '!=', 'superseded')
            ->latest()
            ->first();
    }

    /**
     * Mark all rejected documents as superseded so they are archived.
     * Called before creating a new submission after a rejection.
     */
    public function supersedePreviousRejections(User $user): void
    {
        KycDocument::where('user_id', $user->id)
            ->where('status', 'rejected')
            ->update(['status' => 'superseded']);
    }

    /**
     * Create a new KYC document record.
     */
    public function create(array $data): KycDocument
    {
        return KycDocument::create($data);
    }

    /**
     * Find a KYC document by ID — loads user relationship.
     */
    public function findOrFail(int $id): KycDocument
    {
        return KycDocument::with('user:id,name,email,kyc_level,kyc_status')
            ->findOrFail($id);
    }

    /**
     * Paginated list for admin — filterable by status and document type.
     * Excludes superseded documents from the admin view by default.
     */
    public function paginate(array $filters = []): LengthAwarePaginator
    {
        $query = KycDocument::with([
            'user:id,name,email,kyc_level,kyc_status',
            'reviewer:id,name,email',
        ])->latest();

        // Default: hide superseded unless explicitly requested
        $status = $filters['status'] ?? null;
        if ($status) {
            $query->where('status', $status);
        } else {
            $query->where('status', '!=', 'superseded');
        }

        if ($type = $filters['document_type'] ?? null) {
            $query->where('document_type', $type);
        }

        return $query->paginate(20);
    }
}
