@extends('admin.partials.layout')
@section('title', 'Top-ups')

@section('content')
<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-phone me-2 text-primary"></i>Airtime & Data Top-ups
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">{{ $topups['total'] ?? 0 }} total</span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.topups') }}">
        <div class="filter-bar">
            <input type="text" name="search" class="form-control" placeholder="Search phone or user..." value="{{ request('search') }}">
            <select name="network" class="form-select">
                <option value="">All Networks</option>
                @foreach(['MTN','Airtel','Glo','9mobile'] as $n)
                    <option value="{{ $n }}" {{ request('network') === $n ? 'selected' : '' }}>{{ $n }}</option>
                @endforeach
            </select>
            <input type="date" name="date" class="form-control" value="{{ request('date') }}" style="max-width:150px;">
            <button type="submit" class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
            @if(request()->hasAny(['search','network','date']))
                <a href="{{ route('admin.topups') }}" class="btn btn-outline-secondary"><i class="bi bi-x me-1"></i>Clear</a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th><th>User</th><th>Phone</th><th>Network</th><th>Type</th><th>Amount</th><th>Status</th><th>Date</th>
                </tr>
            </thead>
            <tbody>
                @forelse($topups['data'] as $tx)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $tx['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $tx['sender']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $tx['sender']['email'] ?? '' }}</div>
                    </td>
                    <td>{{ $tx['meta']['phone_number'] ?? '—' }}</td>
                    <td><span class="badge bg-secondary">{{ $tx['meta']['network'] ?? '—' }}</span></td>
                    <td><span class="badge bg-info text-dark">{{ ucfirst($tx['meta']['topup_type'] ?? '—') }}</span></td>
                    <td class="fw-semibold">₦{{ number_format($tx['amount'], 2) }}</td>
                    <td><span class="badge badge-{{ $tx['status'] }}" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">{{ ucfirst($tx['status']) }}</span></td>
                    <td class="text-muted" style="font-size:.8rem;">{{ \Carbon\Carbon::parse($tx['created_at'])->format('M d, Y H:i') }}</td>
                </tr>
                @empty
                <tr><td colspan="8" class="text-center text-muted py-5">No top-ups found</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($topups['last_page']) && $topups['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $topups['from'] }}–{{ $topups['to'] }} of {{ $topups['total'] }}</small>
        <div class="d-flex gap-1">
            @if($topups['current_page'] > 1)
                <a href="?page={{ $topups['current_page'] - 1 }}&search={{ request('search') }}&network={{ request('network') }}&date={{ request('date') }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-left"></i></a>
            @endif
            @for($p = max(1, $topups['current_page'] - 2); $p <= min($topups['last_page'], $topups['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&search={{ request('search') }}&network={{ request('network') }}&date={{ request('date') }}" class="btn btn-sm {{ $p === $topups['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}" style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($topups['current_page'] < $topups['last_page'])
                <a href="?page={{ $topups['current_page'] + 1 }}&search={{ request('search') }}&network={{ request('network') }}&date={{ request('date') }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-right"></i></a>
            @endif
        </div>
    </div>
    @endif
</div>
@endsection
