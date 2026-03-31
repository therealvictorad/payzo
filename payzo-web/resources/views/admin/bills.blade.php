@extends('admin.partials.layout')
@section('title', 'Bill Payments')

@section('content')
<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-receipt me-2 text-warning"></i>Bill Payments
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">{{ $bills['total'] ?? 0 }} total</span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.bills') }}">
        <div class="filter-bar">
            <input type="text" name="search" class="form-control" placeholder="Search user or customer ID..." value="{{ request('search') }}">
            <select name="provider" class="form-select">
                <option value="">All Providers</option>
                @foreach(['DSTV','GOtv','Startimes','IKEDC','EKEDC','AEDC','IBEDC'] as $p)
                    <option value="{{ $p }}" {{ request('provider') === $p ? 'selected' : '' }}>{{ $p }}</option>
                @endforeach
            </select>
            <select name="category" class="form-select">
                <option value="">All Categories</option>
                <option value="tv" {{ request('category') === 'tv' ? 'selected' : '' }}>TV</option>
                <option value="electricity" {{ request('category') === 'electricity' ? 'selected' : '' }}>Electricity</option>
            </select>
            <input type="date" name="date" class="form-control" value="{{ request('date') }}" style="max-width:150px;">
            <button type="submit" class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
            @if(request()->hasAny(['search','provider','category','date']))
                <a href="{{ route('admin.bills') }}" class="btn btn-outline-secondary"><i class="bi bi-x me-1"></i>Clear</a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th><th>User</th><th>Provider</th><th>Category</th><th>Customer ID</th><th>Reference</th><th>Amount</th><th>Status</th><th>Date</th>
                </tr>
            </thead>
            <tbody>
                @forelse($bills['data'] as $tx)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $tx['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $tx['sender']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['sender']['email'] ?? '' }}</div>
                    </td>
                    <td><span class="badge bg-warning text-dark">{{ $tx['meta']['provider'] ?? '—' }}</span></td>
                    <td><span class="badge bg-secondary">{{ ucfirst($tx['meta']['category'] ?? '—') }}</span></td>
                    <td style="font-size:.82rem;">{{ $tx['meta']['customer_id'] ?? '—' }}</td>
                    <td style="font-size:.75rem;color:#64748b;">{{ $tx['meta']['reference'] ?? '—' }}</td>
                    <td class="fw-semibold">₦{{ number_format($tx['amount'], 2) }}</td>
                    <td><span class="badge badge-{{ $tx['status'] }}" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">{{ ucfirst($tx['status']) }}</span></td>
                    <td class="text-muted" style="font-size:.8rem;">{{ \Carbon\Carbon::parse($tx['created_at'])->format('M d, Y H:i') }}</td>
                </tr>
                @empty
                <tr><td colspan="9" class="text-center text-muted py-5">No bill payments found</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($bills['last_page']) && $bills['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $bills['from'] }}–{{ $bills['to'] }} of {{ $bills['total'] }}</small>
        <div class="d-flex gap-1">
            @if($bills['current_page'] > 1)
                <a href="?page={{ $bills['current_page'] - 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-left"></i></a>
            @endif
            @for($p = max(1, $bills['current_page'] - 2); $p <= min($bills['last_page'], $bills['current_page'] + 2); $p++)
                <a href="?page={{ $p }}" class="btn btn-sm {{ $p === $bills['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}" style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($bills['current_page'] < $bills['last_page'])
                <a href="?page={{ $bills['current_page'] + 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-right"></i></a>
            @endif
        </div>
    </div>
    @endif
</div>
@endsection
