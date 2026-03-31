@extends('admin.partials.layout')
@section('title', 'Transactions')

@section('content')

<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-arrow-left-right me-2 text-primary"></i>All Transactions
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $transactions['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    {{-- Filters --}}
    <form method="GET" action="{{ route('admin.transactions') }}">
        <div class="filter-bar">
            <input
                type="text"
                name="search"
                class="form-control"
                placeholder="Sender or receiver name..."
                value="{{ request('search') }}"
            >
            <select name="status" class="form-select">
                <option value="">All Statuses</option>
                <option value="success" {{ request('status') === 'success' ? 'selected' : '' }}>Success</option>
                <option value="failed"  {{ request('status') === 'failed'  ? 'selected' : '' }}>Failed</option>
            </select>
            <input
                type="date"
                name="date"
                class="form-control"
                value="{{ request('date') }}"
                style="max-width:150px;"
            >
            <button type="submit" class="btn btn-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            @if(request('search') || request('status') || request('date'))
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
                    <th>#</th>
                    <th>Sender</th>
                    <th>Receiver</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                @forelse($transactions['data'] as $tx)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $tx['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $tx['sender']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['sender']['email'] ?? '' }}</div>
                    </td>
                    <td>
                        <div class="fw-semibold">{{ $tx['receiver']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['receiver']['email'] ?? '' }}</div>
                    </td>
                    <td class="fw-semibold" style="color:#1e293b;">
                        ₦{{ number_format($tx['amount'], 2) }}
                    </td>
                    <td>
                        <span class="badge badge-{{ $tx['status'] }}" style="padding:.3rem .65rem; border-radius:6px; font-size:.72rem; font-weight:600;">
                            {{ ucfirst($tx['status']) }}
                        </span>
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($tx['created_at'])->format('M d, Y H:i') }}
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center text-muted py-5">No transactions found</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Pagination --}}
    @if(isset($transactions['last_page']) && $transactions['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">
            Showing {{ $transactions['from'] }}–{{ $transactions['to'] }} of {{ $transactions['total'] }}
        </small>
        <div class="d-flex gap-1">
            @if($transactions['current_page'] > 1)
                <a href="?page={{ $transactions['current_page'] - 1 }}&search={{ request('search') }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $transactions['current_page'] - 2); $p <= min($transactions['last_page'], $transactions['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&search={{ request('search') }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm {{ $p === $transactions['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($transactions['current_page'] < $transactions['last_page'])
                <a href="?page={{ $transactions['current_page'] + 1 }}&search={{ request('search') }}&status={{ request('status') }}&date={{ request('date') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
