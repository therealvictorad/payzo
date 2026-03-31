@extends('admin.partials.layout')
@section('title', 'Fraud Logs')

@section('content')

<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-shield-exclamation me-2 text-danger"></i>Fraud Logs
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $fraudLogs['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    {{-- Filters --}}
    <form method="GET" action="{{ route('admin.fraud-logs') }}">
        <div class="filter-bar">
            <select name="risk_level" class="form-select">
                <option value="">All Risk Levels</option>
                <option value="HIGH"   {{ request('risk_level') === 'HIGH'   ? 'selected' : '' }}>High</option>
                <option value="MEDIUM" {{ request('risk_level') === 'MEDIUM' ? 'selected' : '' }}>Medium</option>
                <option value="LOW"    {{ request('risk_level') === 'LOW'    ? 'selected' : '' }}>Low</option>
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
            @if(request('risk_level') || request('rule'))
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
                    <th>Transaction ID</th>
                    <th>Amount</th>
                    <th>Rule Triggered</th>
                    <th>Risk Level</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                @forelse($fraudLogs['data'] as $log)
                <tr class="{{ $log['risk_level'] === 'HIGH' ? 'risk-high' : '' }}">
                    <td class="text-muted" style="font-size:.8rem;">{{ $log['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $log['user']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $log['user']['email'] ?? '' }}</div>
                    </td>
                    <td>
                        <span class="text-muted" style="font-size:.82rem;">#{{ $log['transaction_id'] }}</span>
                    </td>
                    <td class="fw-semibold">
                        ₦{{ number_format($log['transaction']['amount'] ?? 0, 2) }}
                    </td>
                    <td>
                        <span style="font-size:.78rem; background:#f1f5f9; padding:.3rem .6rem; border-radius:6px; font-weight:600; color:#475569;">
                            {{ str_replace('_', ' ', $log['rule_triggered']) }}
                        </span>
                    </td>
                    <td>
                        <span class="badge badge-{{ strtolower($log['risk_level']) }}" style="padding:.3rem .65rem; border-radius:6px; font-size:.72rem; font-weight:600;">
                            {{ $log['risk_level'] }}
                        </span>
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($log['created_at'])->format('M d, Y H:i') }}
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="7" class="text-center text-muted py-5">No fraud logs found</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Pagination --}}
    @if(isset($fraudLogs['last_page']) && $fraudLogs['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">
            Showing {{ $fraudLogs['from'] }}–{{ $fraudLogs['to'] }} of {{ $fraudLogs['total'] }}
        </small>
        <div class="d-flex gap-1">
            @if($fraudLogs['current_page'] > 1)
                <a href="?page={{ $fraudLogs['current_page'] - 1 }}&risk_level={{ request('risk_level') }}&rule={{ request('rule') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $fraudLogs['current_page'] - 2); $p <= min($fraudLogs['last_page'], $fraudLogs['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&risk_level={{ request('risk_level') }}&rule={{ request('rule') }}"
                   class="btn btn-sm {{ $p === $fraudLogs['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($fraudLogs['current_page'] < $fraudLogs['last_page'])
                <a href="?page={{ $fraudLogs['current_page'] + 1 }}&risk_level={{ request('risk_level') }}&rule={{ request('rule') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
