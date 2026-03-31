@extends('admin.partials.layout')
@section('title', 'Payment Links')

@section('content')
<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-link-45deg me-2 text-success"></i>Payment Links
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">{{ $paymentLinks['total'] ?? 0 }} total</span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.payment-links') }}">
        <div class="filter-bar">
            <input type="text" name="search" class="form-control" placeholder="Search user or code..." value="{{ request('search') }}">
            <select name="status" class="form-select">
                <option value="">All Statuses</option>
                <option value="active"  {{ request('status') === 'active'  ? 'selected' : '' }}>Active</option>
                <option value="paid"    {{ request('status') === 'paid'    ? 'selected' : '' }}>Paid</option>
                <option value="expired" {{ request('status') === 'expired' ? 'selected' : '' }}>Expired</option>
            </select>
            <input type="date" name="date" class="form-control" value="{{ request('date') }}" style="max-width:150px;">
            <button type="submit" class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
            @if(request()->hasAny(['search','status','date']))
                <a href="{{ route('admin.payment-links') }}" class="btn btn-outline-secondary"><i class="bi bi-x me-1"></i>Clear</a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th><th>Owner</th><th>Code</th><th>Description</th><th>Amount</th><th>Status</th><th>Paid By</th><th>Paid At</th><th>Created</th>
                </tr>
            </thead>
            <tbody>
                @forelse($paymentLinks['data'] as $link)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $link['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $link['owner']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $link['owner']['email'] ?? '' }}</div>
                    </td>
                    <td><code style="font-size:.78rem;background:#f1f5f9;padding:.2rem .5rem;border-radius:4px;">{{ $link['code'] }}</code></td>
                    <td class="text-muted" style="font-size:.82rem;">{{ $link['description'] ?? '—' }}</td>
                    <td class="fw-semibold">₦{{ number_format($link['amount'], 2) }}</td>
                    <td>
                        @php
                            $statusColor = ['active' => 'primary', 'paid' => 'success', 'expired' => 'secondary'][$link['status']] ?? 'secondary';
                        @endphp
                        <span class="badge bg-{{ $statusColor }}" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;">{{ ucfirst($link['status']) }}</span>
                    </td>
                    <td style="font-size:.82rem;">{{ $link['payer']['name'] ?? '—' }}</td>
                    <td class="text-muted" style="font-size:.8rem;">{{ $link['paid_at'] ? \Carbon\Carbon::parse($link['paid_at'])->format('M d, H:i') : '—' }}</td>
                    <td class="text-muted" style="font-size:.8rem;">{{ \Carbon\Carbon::parse($link['created_at'])->format('M d, Y') }}</td>
                </tr>
                @empty
                <tr><td colspan="9" class="text-center text-muted py-5">No payment links found</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($paymentLinks['last_page']) && $paymentLinks['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $paymentLinks['from'] }}–{{ $paymentLinks['to'] }} of {{ $paymentLinks['total'] }}</small>
        <div class="d-flex gap-1">
            @if($paymentLinks['current_page'] > 1)
                <a href="?page={{ $paymentLinks['current_page'] - 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-left"></i></a>
            @endif
            @for($p = max(1, $paymentLinks['current_page'] - 2); $p <= min($paymentLinks['last_page'], $paymentLinks['current_page'] + 2); $p++)
                <a href="?page={{ $p }}" class="btn btn-sm {{ $p === $paymentLinks['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}" style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($paymentLinks['current_page'] < $paymentLinks['last_page'])
                <a href="?page={{ $paymentLinks['current_page'] + 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-right"></i></a>
            @endif
        </div>
    </div>
    @endif
</div>
@endsection
