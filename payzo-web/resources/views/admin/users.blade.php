@extends('admin.partials.layout')
@section('title', 'Users')

@section('content')

@if(session('success'))
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif
@if(session('error'))
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <i class="bi bi-exclamation-circle me-2"></i>{{ session('error') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif

<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-people me-2 text-primary"></i>All Users
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $users['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    <form method="GET" action="{{ route('admin.users') }}">
        <div class="filter-bar">
            <input type="text" name="search" class="form-control"
                placeholder="Search name or email..." value="{{ request('search') }}">
            <select name="role" class="form-select">
                <option value="">All Roles</option>
                <option value="user"  {{ request('role') === 'user'  ? 'selected' : '' }}>User</option>
                <option value="agent" {{ request('role') === 'agent' ? 'selected' : '' }}>Agent</option>
                <option value="admin" {{ request('role') === 'admin' ? 'selected' : '' }}>Admin</option>
            </select>
            <select name="frozen" class="form-select">
                <option value="">All Accounts</option>
                <option value="1" {{ request('frozen') === '1' ? 'selected' : '' }}>Frozen Only</option>
            </select>
            <button type="submit" class="btn btn-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            @if(request('search') || request('role') || request('frozen'))
                <a href="{{ route('admin.users') }}" class="btn btn-outline-secondary">
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
                    <th>Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Balance</th>
                    <th>Status</th>
                    <th>Joined</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($users['data'] as $user)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $user['id'] }}</td>
                    <td class="fw-semibold">{{ $user['name'] }}</td>
                    <td class="text-muted" style="font-size:.82rem;">{{ $user['email'] }}</td>
                    <td>
                        <span class="badge badge-{{ $user['role'] }}"
                            style="padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                            {{ ucfirst($user['role']) }}
                        </span>
                    </td>
                    <td class="fw-semibold">₦{{ number_format($user['wallet']['balance'] ?? 0, 2) }}</td>
                    <td>
                        @if($user['is_frozen'])
                            <span class="badge" style="background:#fee2e2;color:#dc2626;padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                <i class="bi bi-lock-fill me-1"></i>Frozen
                            </span>
                        @else
                            <span class="badge" style="background:#dcfce7;color:#16a34a;padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                                <i class="bi bi-unlock-fill me-1"></i>Active
                            </span>
                        @endif
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($user['created_at'])->format('M d, Y') }}
                    </td>
                    <td>
                        @if($user['role'] !== 'admin')
                            @if($user['is_frozen'])
                                <form method="POST"
                                    action="{{ route('admin.users.unfreeze', $user['id']) }}"
                                    style="display:inline;"
                                    onsubmit="return confirm('Unfreeze {{ $user['name'] }}?')">
                                    @csrf
                                    <button type="submit" class="btn btn-sm btn-success" style="border-radius:6px;font-size:.75rem;">
                                        <i class="bi bi-unlock me-1"></i>Unfreeze
                                    </button>
                                </form>
                            @else
                                <form method="POST"
                                    action="{{ route('admin.users.freeze', $user['id']) }}"
                                    style="display:inline;"
                                    onsubmit="return confirm('Freeze {{ $user['name'] }}? They will not be able to transact.')">
                                    @csrf
                                    <button type="submit" class="btn btn-sm btn-danger" style="border-radius:6px;font-size:.75rem;">
                                        <i class="bi bi-lock me-1"></i>Freeze
                                    </button>
                                </form>
                            @endif
                        @else
                            <span class="text-muted" style="font-size:.75rem;">—</span>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" class="text-center text-muted py-5">No users found</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($users['last_page']) && $users['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $users['from'] }}–{{ $users['to'] }} of {{ $users['total'] }}</small>
        <div class="d-flex gap-1">
            @if($users['current_page'] > 1)
                <a href="?page={{ $users['current_page'] - 1 }}&search={{ request('search') }}&role={{ request('role') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $users['current_page'] - 2); $p <= min($users['last_page'], $users['current_page'] + 2); $p++)
                <a href="?page={{ $p }}&search={{ request('search') }}&role={{ request('role') }}"
                   class="btn btn-sm {{ $p === $users['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($users['current_page'] < $users['last_page'])
                <a href="?page={{ $users['current_page'] + 1 }}&search={{ request('search') }}&role={{ request('role') }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
