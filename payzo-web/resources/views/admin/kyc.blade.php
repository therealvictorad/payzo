@extends('admin.partials.layout')
@section('title', 'KYC Requests')

@section('content')

@if(session('success'))
    <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif
@if(session('error'))
    <div class="alert alert-danger alert-dismissible fade show">
        <i class="bi bi-exclamation-circle me-2"></i>{{ session('error') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif

<div class="table-card">
    <div class="table-header">
        <h6>
            <i class="bi bi-person-check me-2 text-primary"></i>KYC Requests
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $kycDocuments['total'] ?? 0 }} total
            </span>
        </h6>
        {{-- Pending count badge --}}
        @php $pending = collect($kycDocuments['data'])->where('status','pending')->count(); @endphp
        @if($pending > 0)
            <span style="background:#fef9c3;color:#ca8a04;padding:.3rem .75rem;border-radius:20px;font-size:.75rem;font-weight:600;">
                {{ $pending }} pending on this page
            </span>
        @endif
    </div>

    {{-- Filters --}}
    <form method="GET" action="{{ route('admin.kyc') }}">
        <div class="filter-bar">
            <select name="status" class="form-select">
                <option value="">All Statuses</option>
                <option value="pending"  {{ request('status') === 'pending'  ? 'selected' : '' }}>Pending</option>
                <option value="approved" {{ request('status') === 'approved' ? 'selected' : '' }}>Approved</option>
                <option value="rejected" {{ request('status') === 'rejected' ? 'selected' : '' }}>Rejected</option>
            </select>
            <select name="document_type" class="form-select">
                <option value="">All Document Types</option>
                <option value="nin"             {{ request('document_type') === 'nin'             ? 'selected' : '' }}>NIN</option>
                <option value="bvn"             {{ request('document_type') === 'bvn'             ? 'selected' : '' }}>BVN</option>
                <option value="passport"        {{ request('document_type') === 'passport'        ? 'selected' : '' }}>Passport</option>
                <option value="drivers_license" {{ request('document_type') === 'drivers_license' ? 'selected' : '' }}>Driver's License</option>
            </select>
            <button type="submit" class="btn btn-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            @if(request('status') || request('document_type'))
                <a href="{{ route('admin.kyc') }}" class="btn btn-outline-secondary">
                    <i class="bi bi-x me-1"></i>Clear
                </a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th>
                    <th>User</th>
                    <th>Document Type</th>
                    <th>Full Name</th>
                    <th>KYC Level</th>
                    <th>Status</th>
                    <th>Submitted</th>
                    <th>Reviewed By</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($kycDocuments['data'] as $doc)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $doc['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $doc['user']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $doc['user']['email'] ?? '' }}</div>
                    </td>
                    <td>
                        <span style="background:#f1f5f9;padding:.3rem .65rem;border-radius:6px;font-size:.75rem;font-weight:600;color:#475569;">
                            {{ strtoupper(str_replace('_', ' ', $doc['document_type'])) }}
                        </span>
                    </td>
                    <td style="font-size:.875rem;">{{ $doc['full_name'] }}</td>
                    <td>
                        @php
                            $levelColors = [
                                'tier0' => 'background:#f1f5f9;color:#475569;',
                                'tier1' => 'background:#dbeafe;color:#2563eb;',
                                'tier2' => 'background:#dcfce7;color:#16a34a;',
                            ];
                            $lc = $levelColors[$doc['user']['kyc_level'] ?? 'tier0'] ?? '';
                        @endphp
                        <span style="{{ $lc }}padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                            {{ strtoupper($doc['user']['kyc_level'] ?? 'tier0') }}
                        </span>
                    </td>
                    <td>
                        @if($doc['status'] === 'pending')
                            <span style="background:#fef9c3;color:#ca8a04;padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                <i class="bi bi-clock me-1"></i>Pending
                            </span>
                        @elseif($doc['status'] === 'approved')
                            <span class="badge badge-success" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                <i class="bi bi-check-circle me-1"></i>Approved
                            </span>
                        @else
                            <span class="badge badge-failed" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                <i class="bi bi-x-circle me-1"></i>Rejected
                            </span>
                        @endif
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($doc['created_at'])->format('M d, Y H:i') }}
                    </td>
                    <td style="font-size:.8rem;">
                        @if($doc['reviewer'])
                            <div class="fw-semibold">{{ $doc['reviewer']['name'] }}</div>
                            <div class="text-muted" style="font-size:.75rem;">
                                {{ $doc['reviewed_at'] ? \Carbon\Carbon::parse($doc['reviewed_at'])->format('M d, Y') : '' }}
                            </div>
                        @else
                            <span class="text-muted">—</span>
                        @endif
                    </td>
                    <td>
                        <div class="d-flex gap-1 flex-wrap">
                            {{-- View Document --}}
                            <a href="{{ route('admin.kyc.document', $doc['id']) }}"
                               target="_blank"
                               class="btn btn-sm btn-outline-secondary"
                               style="border-radius:6px;font-size:.75rem;">
                                <i class="bi bi-eye me-1"></i>View
                            </a>

                            @if($doc['status'] === 'pending')
                                {{-- Approve --}}
                                <form method="POST"
                                    action="{{ route('admin.kyc.approve', $doc['id']) }}"
                                    style="display:inline;"
                                    onsubmit="return confirm('Approve KYC for {{ $doc['user']['name'] ?? '' }}? This will upgrade them to tier2.')">
                                    @csrf
                                    <button type="submit" class="btn btn-sm btn-success"
                                        style="border-radius:6px;font-size:.75rem;">
                                        <i class="bi bi-check2 me-1"></i>Approve
                                    </button>
                                </form>

                                {{-- Reject --}}
                                <button type="button"
                                    class="btn btn-sm btn-danger"
                                    style="border-radius:6px;font-size:.75rem;"
                                    data-bs-toggle="modal"
                                    data-bs-target="#rejectModal"
                                    data-doc-id="{{ $doc['id'] }}"
                                    data-doc-user="{{ $doc['user']['name'] ?? '' }}">
                                    <i class="bi bi-x me-1"></i>Reject
                                </button>
                            @endif
                        </div>

                        {{-- Show rejection reason if rejected --}}
                        @if($doc['status'] === 'rejected' && $doc['rejection_reason'])
                            <div class="text-muted mt-1" style="font-size:.72rem;max-width:200px;">
                                <i class="bi bi-info-circle me-1"></i>{{ $doc['rejection_reason'] }}
                            </div>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" class="text-center text-muted py-5">
                        <i class="bi bi-person-check" style="font-size:2rem;opacity:.3;"></i>
                        <div class="mt-2">No KYC submissions found</div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Pagination --}}
    @if(isset($kycDocuments['last_page']) && $kycDocuments['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">
            Showing {{ $kycDocuments['from'] }}–{{ $kycDocuments['to'] }} of {{ $kycDocuments['total'] }}
        </small>
        <div class="d-flex gap-1">
            @if($kycDocuments['current_page'] > 1)
                <a href="?page={{ $kycDocuments['current_page'] - 1 }}&status={{ request('status') }}&document_type={{ request('document_type') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $kycDocuments['current_page'] - 2); $p <= min($kycDocuments['last_page'], $kycDocuments['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&status={{ request('status') }}&document_type={{ request('document_type') }}"
                   class="btn btn-sm {{ $p === $kycDocuments['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($kycDocuments['current_page'] < $kycDocuments['last_page'])
                <a href="?page={{ $kycDocuments['current_page'] + 1 }}&status={{ request('status') }}&document_type={{ request('document_type') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

{{-- Reject Modal --}}
<div class="modal fade" id="rejectModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" style="border-radius:16px;border:none;">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">Reject KYC Submission</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form id="rejectForm" method="POST" action="">
                @csrf
                <div class="modal-body">
                    <p class="text-muted mb-3" id="rejectDescription" style="font-size:.875rem;"></p>
                    <div class="mb-3">
                        <label class="form-label fw-semibold" style="font-size:.85rem;">
                            Rejection Reason <span class="text-danger">*</span>
                        </label>
                        <textarea name="reason" class="form-control" rows="3" required
                            placeholder="e.g. Document is blurry, Name mismatch, Expired document..."
                            style="border-radius:8px;font-size:.875rem;"></textarea>
                        <div class="form-text">This reason will be shown to the user so they can resubmit.</div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal"
                        style="border-radius:8px;">Cancel</button>
                    <button type="submit" class="btn btn-danger" style="border-radius:8px;">
                        <i class="bi bi-x-circle me-1"></i>Reject KYC
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection

@section('scripts')
<script>
    const rejectModal = document.getElementById('rejectModal');
    rejectModal.addEventListener('show.bs.modal', function (e) {
        const btn    = e.relatedTarget;
        const docId  = btn.getAttribute('data-doc-id');
        const user   = btn.getAttribute('data-doc-user');
        document.getElementById('rejectForm').action = `/admin/kyc/${docId}/reject`;
        document.getElementById('rejectDescription').textContent =
            `Rejecting KYC submission for ${user}. Please provide a reason.`;
    });
</script>
@endsection
