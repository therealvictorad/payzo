@extends('admin.partials.layout')
@section('title', 'Dashboard')

@section('content')

{{-- Stat Cards --}}
<div class="row g-3 mb-4">
    <div class="col-sm-6 col-xl-3">
        <div class="stat-card">
            <div class="icon-wrap" style="background:#ede9fe;">
                <i class="bi bi-people-fill" style="color:#7c3aed;"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['total_users']) }}</div>
            <div class="stat-label">Total Users</div>
        </div>
    </div>
    <div class="col-sm-6 col-xl-3">
        <div class="stat-card">
            <div class="icon-wrap" style="background:#dbeafe;">
                <i class="bi bi-arrow-left-right" style="color:#2563eb;"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['total_transactions']) }}</div>
            <div class="stat-label">Total Transactions</div>
        </div>
    </div>
    <div class="col-sm-6 col-xl-3">
        <div class="stat-card">
            <div class="icon-wrap" style="background:#fee2e2;">
                <i class="bi bi-shield-exclamation" style="color:#dc2626;"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['fraud_alerts']) }}</div>
            <div class="stat-label">Fraud Alerts</div>
        </div>
    </div>
    <div class="col-sm-6 col-xl-3">
        <div class="stat-card">
            <div class="icon-wrap" style="background:#dcfce7;">
                <i class="bi bi-cash-stack" style="color:#16a34a;"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['total_volume'], 2) }}</div>
            <div class="stat-label">Total Volume (₦)</div>
        </div>
    </div>
</div>

<div class="row g-3">
    {{-- Recent Transactions --}}
    <div class="col-xl-7">
        <div class="table-card">
            <div class="table-header">
                <h6><i class="bi bi-arrow-left-right me-2 text-primary"></i>Recent Transactions</h6>
                <a href="{{ route('admin.transactions') }}" class="btn btn-sm btn-outline-primary" style="font-size:.75rem; border-radius:8px;">
                    View All
                </a>
            </div>
            <div class="table-responsive">
                <table class="table mb-0">
                    <thead>
                        <tr>
                            <th>Sender</th>
                            <th>Receiver</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($recentTransactions as $tx)
                        <tr>
                            <td>{{ $tx['sender']['name'] ?? '—' }}</td>
                            <td>{{ $tx['receiver']['name'] ?? '—' }}</td>
                            <td class="fw-600">₦{{ number_format($tx['amount'], 2) }}</td>
                            <td>
                                <span class="badge badge-{{ $tx['status'] }}" style="padding:.3rem .65rem; border-radius:6px; font-size:.72rem; font-weight:600;">
                                    {{ ucfirst($tx['status']) }}
                                </span>
                            </td>
                            <td class="text-muted" style="font-size:.8rem;">
                                {{ \Carbon\Carbon::parse($tx['created_at'])->format('M d, H:i') }}
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="5" class="text-center text-muted py-4">No transactions yet</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- Recent Fraud Logs --}}
    <div class="col-xl-5">
        <div class="table-card">
            <div class="table-header">
                <h6><i class="bi bi-shield-exclamation me-2 text-danger"></i>Recent Fraud Alerts</h6>
                <a href="{{ route('admin.fraud-logs') }}" class="btn btn-sm btn-outline-danger" style="font-size:.75rem; border-radius:8px;">
                    View All
                </a>
            </div>
            <div class="table-responsive">
                <table class="table mb-0">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Rule</th>
                            <th>Risk</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($recentFraud as $log)
                        <tr class="{{ $log['risk_level'] === 'HIGH' ? 'risk-high' : '' }}">
                            <td>{{ $log['user']['name'] ?? '—' }}</td>
                            <td style="font-size:.75rem;">{{ str_replace('_', ' ', $log['rule_triggered']) }}</td>
                            <td>
                                <span class="badge badge-{{ strtolower($log['risk_level']) }}" style="padding:.3rem .65rem; border-radius:6px; font-size:.72rem; font-weight:600;">
                                    {{ $log['risk_level'] }}
                                </span>
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="3" class="text-center text-muted py-4">No fraud alerts</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@endsection
