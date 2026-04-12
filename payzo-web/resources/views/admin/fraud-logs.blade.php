@extends('admin.partials.layout')
@section('title', 'Fraud Logs')

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
        <h6><i class="bi bi-shield-exclamation me-2 text-danger"></i>Fraud Logs
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $fraudLogs['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.fraud-logs') }}">
        <div class="filter-bar">
            <select name="risk_level" class="form-select">
                <option value="">All Risk Levels</option>
                <option value="HIGH"   {{ request('risk_level') === 'HIGH'   ? 'selected' : '' }}>High</option>
                <option value="MEDIUM" {{ request('risk_level') === 'MEDIUM' ? 'selected' : '' }}>Medium</option>
                <option value="LOW"    {{ request('risk_level') === 'LOW'    ? 'selected' : '' }}>Low</option>
            </select>
            <select name="resolution" class="form-select">
                <option value="">All Resolutions</option>
                <option value="open"      {{ request('resolution') === 'open'      ? 'selected' : '' }}>Open</option>
                <option value="resolved"  {{ request('resolution') === 'resolved'  ? 'selected' : '' }}>Resolved</option>
                <option value="escalated" {{ request('resolution') === 'escalated' ? 'selected' : '' }}>Escalated</option>
            </select>
            <select name="rule" class="form-select">
                <option value="">All Rules</option>
                <option value="LARGE_TRANSACTION"  {{ request('rule') === 'LARGE_TRANSACTION'  ? 'selected' : '' }}>Large Transaction</option>
                <option value="RAPID_TRANSACTIONS" {{ request('rule') === 'RAPID_TRANSACTIONS' ? 'selected' : '' }}>Rapid Transactions</option>
                <option value="UNUSUAL_TIME"       {{ request('rule') === 'UNUSUAL_TIME'       ? 'selected' : '' }}>Unusual Time</option>
            </select>
            <button type="submit" class="btn btn-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            @if(request('risk_level') || request('resolution') || request('rule'))
                <a href="{{ route('admin.fraud-logs') }}" class="btn btn-outline-secondary">
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
                    <th>Reference</th>
                    <th>Amount</th>
                    <th>Rule</th>
                    <th>Risk</th>
                    <th>Resolution</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($fraudLogs['data'] as $log)
                <tr class="{{ $log['risk_level'] === 'HIGH' && $log['resolution'] === 'open' ? 'risk-high' : '' }}">
                    <td class="text-muted" style="font-size:.8rem;">{{ $log['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $log['user']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $log['user']['email'] ?? '' }}</div>
                    </td>
                    <td style="font-size:.78rem;font-family:monospace;color:#475569;">
                        {{ $log['transaction']['reference'] ?? '#' . $log['transaction_id'] }}
                    </td>
                    <td class="fw-semibold">₦{{ number_format($log['transaction']['amount'] ?? 0, 2) }}</td>
                    <td>
                        <span style="font-size:.75rem;background:#f1f5f9;padding:.25rem .55rem;border-radius:5px;font-weight:600;color:#475569;">
                            {{ str_replace('_', ' ', $log['rule_triggered']) }}
                        </span>
                    </td>
                    <td>
                        <span class="badge badge-{{ strtolower($log['risk_level']) }}"
                            style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                            {{ $log['risk_level'] }}
                        </span>
                    </td>
                    <td>
                        @if($log['resolution'] === 'open')
                            <span style="background:#fef9c3;color:#ca8a04;padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                Open
                            </span>
                        @elseif($log['resolution'] === 'resolved')
                            <span class="badge badge-success" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                Resolved
                            </span>
                        @else
                            <span class="badge badge-high" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                Escalated
                            </span>
                        @endif
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($log['created_at'])->format('M d, Y H:i') }}
                    </td>
                    <td>
                        @if($log['resolution'] === 'open')
                            <button type="button" class="btn btn-sm btn-outline-primary"
                                style="border-radius:6px;font-size:.75rem;"
                                data-bs-toggle="modal"
                                data-bs-target="#resolveModal"
                                data-log-id="{{ $log['id'] }}"
                                data-log-rule="{{ str_replace('_', ' ', $log['rule_triggered']) }}"
                                data-log-user="{{ $log['user']['name'] ?? '' }}">
                                <i class="bi bi-check2-circle me-1"></i>Resolve
                            </button>
                        @else
                            <span class="text-muted" style="font-size:.75rem;">—</span>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" class="text-center text-muted py-5">No fraud logs found</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($fraudLogs['last_page']) && $fraudLogs['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $fraudLogs['from'] }}–{{ $fraudLogs['to'] }} of {{ $fraudLogs['total'] }}</small>
        <div class="d-flex gap-1">
            @if($fraudLogs['current_page'] > 1)
                <a href="?page={{ $fraudLogs['current_page'] - 1 }}&risk_level={{ request('risk_level') }}&resolution={{ request('resolution') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $fraudLogs['current_page'] - 2); $p <= min($fraudLogs['last_page'], $fraudLogs['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&risk_level={{ request('risk_level') }}&resolution={{ request('resolution') }}"
                   class="btn btn-sm {{ $p === $fraudLogs['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($fraudLogs['current_page'] < $fraudLogs['last_page'])
                <a href="?page={{ $fraudLogs['current_page'] + 1 }}&risk_level={{ request('risk_level') }}&resolution={{ request('resolution') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

{{-- Resolve Modal --}}
<div class="modal fade" id="resolveModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" style="border-radius:16px;border:none;">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-700">Resolve Fraud Alert</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form id="resolveForm" method="POST" action="">
                @csrf
                <div class="modal-body">
                    <p class="text-muted mb-3" id="resolveDescription" style="font-size:.875rem;"></p>
                    <div class="mb-3">
                        <label class="form-label fw-semibold" style="font-size:.85rem;">Resolution</label>
                        <select name="resolution" class="form-select" required>
                            <option value="resolved">✅ Resolved — Verified legitimate</option>
                            <option value="escalated">🚨 Escalated — Requires further action</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold" style="font-size:.85rem;">Note <span class="text-muted fw-normal">(optional)</span></label>
                        <textarea name="resolution_note" class="form-control" rows="3"
                            placeholder="Add a note about this resolution..." style="border-radius:8px;font-size:.875rem;"></textarea>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" style="border-radius:8px;">Cancel</button>
                    <button type="submit" class="btn btn-primary" style="border-radius:8px;">
                        <i class="bi bi-check2-circle me-1"></i>Submit Resolution
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection

@section('scripts')
<script>
    const resolveModal = document.getElementById('resolveModal');
    resolveModal.addEventListener('show.bs.modal', function (e) {
        const btn    = e.relatedTarget;
        const logId  = btn.getAttribute('data-log-id');
        const rule   = btn.getAttribute('data-log-rule');
        const user   = btn.getAttribute('data-log-user');
        document.getElementById('resolveForm').action = `/admin/fraud-logs/${logId}/resolve`;
        document.getElementById('resolveDescription').textContent =
            `Resolving fraud alert for ${user} — Rule: ${rule}`;
    });
</script>
@endsection
