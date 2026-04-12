@extends('admin.partials.layout')
@section('title', 'Transactions')

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
        <h6><i class="bi bi-arrow-left-right me-2 text-primary"></i>All Transactions
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $transactions['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.transactions') }}">
        <div class="filter-bar">
            <select name="status" class="form-select">
                <option value="">All Statuses</option>
                <option value="success"  {{ request('status') === 'success'  ? 'selected' : '' }}>Success</option>
                <option value="failed"   {{ request('status') === 'failed'   ? 'selected' : '' }}>Failed</option>
                <option value="reversed" {{ request('status') === 'reversed' ? 'selected' : '' }}>Reversed</option>
                <option value="pending"  {{ request('status') === 'pending'  ? 'selected' : '' }}>Pending</option>
            </select>
            <input type="date" name="date" class="form-control"
                value="{{ request('date') }}" style="max-width:150px;">
            <button type="submit" class="btn btn-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            @if(request('status') || request('date'))
                <a href="{{ route('admin.transactions') }}" class="btn btn-outline-secondary">
                    <i class="bi bi-x me-1"></i>Clear
                </a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>Reference</th>
                    <th>Sender</th>
                    <th>Receiver</th>
                    <th>Amount</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($transactions['data'] as $tx)
                <tr>
                    <td style="font-size:.78rem;font-family:monospace;color:#475569;">
                        {{ $tx['reference'] ?? '—' }}
                    </td>
                    <td>
                        <div class="fw-semibold">{{ $tx['sender']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['sender']['email'] ?? '' }}</div>
                    </td>
                    <td>
                        <div class="fw-semibold">{{ $tx['receiver']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['receiver']['email'] ?? '' }}</div>
                    </td>
                    <td class="fw-semibold">₦{{ number_format($tx['amount'], 2) }}</td>
                    <td>
                        <span style="font-size:.75rem;background:#f1f5f9;padding:.25rem .55rem;border-radius:5px;font-weight:600;color:#475569;">
                            {{ str_replace('_', ' ', strtoupper($tx['type'] ?? 'transfer')) }}
                        </span>
                    </td>
                    <td>
                        @php
                            $statusColors = [
                                'success'  => 'badge-success',
                                'failed'   => 'badge-failed',
                                'reversed' => 'background:#fef9c3;color:#ca8a04;',
                                'pending'  => 'background:#dbeafe;color:#2563eb;',
                            ];
                            $sc = $statusColors[$tx['status']] ?? 'badge-failed';
                        @endphp
                        <span class="badge {{ str_starts_with($sc, 'badge') ? $sc : '' }}"
                            style="{{ !str_starts_with($sc, 'badge') ? $sc : '' }}padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                            {{ ucfirst($tx['status']) }}
                        </span>
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($tx['created_at'])->format('M d, Y H:i') }}
                    </td>
                    <td>
                        @if($tx['status'] === 'success' && $tx['type'] === 'transfer')
                            <form method="POST"
                                action="{{ route('admin.transactions.reverse', $tx['id']) }}"
                                style="display:inline;"
                                onsubmit="return confirm('Reverse transaction {{ $tx['reference'] ?? $tx['id'] }}? This will re-credit the sender and re-debit the receiver.')">
                                @csrf
                                <button type="submit" class="btn btn-sm btn-warning" style="border-radius:6px;font-size:.75rem;">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Reverse
                                </button>
                            </form>
                        @else
                            <span class="text-muted" style="font-size:.75rem;">—</span>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" class="text-center text-muted py-5">No transactions found</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($transactions['last_page']) && $transactions['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $transactions['from'] }}–{{ $transactions['to'] }} of {{ $transactions['total'] }}</small>
        <div class="d-flex gap-1">
            @if($transactions['current_page'] > 1)
                <a href="?page={{ $transactions['current_page'] - 1 }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $transactions['current_page'] - 2); $p <= min($transactions['last_page'], $transactions['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm {{ $p === $transactions['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($transactions['current_page'] < $transactions['last_page'])
                <a href="?page={{ $transactions['current_page'] + 1 }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
