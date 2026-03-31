@extends('admin.partials.layout')
@section('title', 'Virtual Cards')

@section('content')
<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-credit-card me-2 text-info"></i>Virtual Cards
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">{{ $cards['total'] ?? 0 }} total</span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.cards') }}">
        <div class="filter-bar">
            <input type="text" name="search" class="form-control" placeholder="Search user..." value="{{ request('search') }}">
            <select name="brand" class="form-select">
                <option value="">All Brands</option>
                <option value="visa"       {{ request('brand') === 'visa'       ? 'selected' : '' }}>Visa</option>
                <option value="mastercard" {{ request('brand') === 'mastercard' ? 'selected' : '' }}>Mastercard</option>
            </select>
            <select name="status" class="form-select">
                <option value="">All Statuses</option>
                <option value="active"     {{ request('status') === 'active'     ? 'selected' : '' }}>Active</option>
                <option value="frozen"     {{ request('status') === 'frozen'     ? 'selected' : '' }}>Frozen</option>
                <option value="terminated" {{ request('status') === 'terminated' ? 'selected' : '' }}>Terminated</option>
            </select>
            <button type="submit" class="btn btn-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
            @if(request()->hasAny(['search','brand','status']))
                <a href="{{ route('admin.cards') }}" class="btn btn-outline-secondary"><i class="bi bi-x me-1"></i>Clear</a>
            @endif
        </div>
    </form>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th><th>Card Holder</th><th>User</th><th>Masked Number</th><th>Brand</th><th>Expiry</th><th>Limit</th><th>Status</th><th>Created</th>
                </tr>
            </thead>
            <tbody>
                @forelse($cards['data'] as $card)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $card['id'] }}</td>
                    <td class="fw-semibold">{{ $card['card_holder'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $card['user']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $card['user']['email'] ?? '' }}</div>
                    </td>
                    <td><code style="font-size:.82rem;letter-spacing:1px;">{{ $card['masked_number'] ?? '**** **** **** ****' }}</code></td>
                    <td>
                        <span class="badge {{ $card['brand'] === 'visa' ? 'bg-primary' : 'bg-danger' }}" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;">
                            {{ strtoupper($card['brand']) }}
                        </span>
                    </td>
                    <td style="font-size:.82rem;">{{ $card['expiry'] }}</td>
                    <td class="fw-semibold">₦{{ number_format($card['spending_limit'], 2) }}</td>
                    <td>
                        @php
                            $sc = ['active' => 'success', 'frozen' => 'warning', 'terminated' => 'danger'][$card['status']] ?? 'secondary';
                        @endphp
                        <span class="badge bg-{{ $sc }}" style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;">{{ ucfirst($card['status']) }}</span>
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">{{ \Carbon\Carbon::parse($card['created_at'])->format('M d, Y') }}</td>
                </tr>
                @empty
                <tr><td colspan="9" class="text-center text-muted py-5">No virtual cards found</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($cards['last_page']) && $cards['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $cards['from'] }}–{{ $cards['to'] }} of {{ $cards['total'] }}</small>
        <div class="d-flex gap-1">
            @if($cards['current_page'] > 1)
                <a href="?page={{ $cards['current_page'] - 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-left"></i></a>
            @endif
            @for($p = max(1, $cards['current_page'] - 2); $p <= min($cards['last_page'], $cards['current_page'] + 2); $p++)
                <a href="?page={{ $p }}" class="btn btn-sm {{ $p === $cards['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}" style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($cards['current_page'] < $cards['last_page'])
                <a href="?page={{ $cards['current_page'] + 1 }}" class="btn btn-sm btn-outline-secondary" style="border-radius:6px;"><i class="bi bi-chevron-right"></i></a>
            @endif
        </div>
    </div>
    @endif
</div>
@endsection
