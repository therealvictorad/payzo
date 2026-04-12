@extends('admin.partials.layout')
@section('title', 'Audit Logs')

@section('content')

<div class="table-card">
    <div class="table-header">
        <h6><i class="bi bi-journal-text me-2 text-primary"></i>Audit Logs
            <span class="text-muted fw-normal ms-2" style="font-size:.8rem;">
                {{ $auditLogs['total'] ?? 0 }} total
            </span>
        </h6>
    </div>

    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Admin</th>
                    <th>Action</th>
                    <th>Target</th>
                    <th>Before</th>
                    <th>After</th>
                    <th>IP</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                @forelse($auditLogs['data'] as $log)
                <tr>
                    <td class="text-muted" style="font-size:.8rem;">{{ $log['id'] }}</td>
                    <td>
                        <div class="fw-semibold">{{ $log['admin']['name'] ?? '—' }}</div>
                        <div class="text-muted" style="font-size:.75rem;">{{ $log['admin']['email'] ?? '' }}</div>
                    </td>
                    <td>
                        @php
                            $actionColors = [
                                'freeze_user'        => 'background:#fee2e2;color:#dc2626;',
                                'unfreeze_user'      => 'background:#dcfce7;color:#16a34a;',
                                'reverse_transaction'=> 'background:#fef9c3;color:#ca8a04;',
                                'resolve_fraud_log'  => 'background:#dbeafe;color:#2563eb;',
                            ];
                            $ac = $actionColors[$log['action']] ?? 'background:#f1f5f9;color:#475569;';
                        @endphp
                        <span style="{{ $ac }}padding:.3rem .65rem;border-radius:6px;font-size:.72rem;font-weight:600;">
                            {{ str_replace('_', ' ', strtoupper($log['action'])) }}
                        </span>
                    </td>
                    <td style="font-size:.82rem;">
                        <span class="fw-semibold">{{ $log['target_type'] }}</span>
                        <span class="text-muted"> #{{ $log['target_id'] }}</span>
                    </td>
                    <td>
                        <code style="font-size:.72rem;background:#f8fafc;padding:.2rem .4rem;border-radius:4px;color:#64748b;">
                            {{ json_encode($log['before']) }}
                        </code>
                    </td>
                    <td>
                        <code style="font-size:.72rem;background:#f0fdf4;padding:.2rem .4rem;border-radius:4px;color:#16a34a;">
                            {{ json_encode($log['after']) }}
                        </code>
                    </td>
                    <td class="text-muted" style="font-size:.8rem;">{{ $log['ip_address'] }}</td>
                    <td class="text-muted" style="font-size:.8rem;">
                        {{ \Carbon\Carbon::parse($log['created_at'])->format('M d, Y H:i') }}
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" class="text-center text-muted py-5">No audit logs yet</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if(isset($auditLogs['last_page']) && $auditLogs['last_page'] > 1)
    <div class="d-flex align-items-center justify-content-between px-4 py-3 border-top">
        <small class="text-muted">Showing {{ $auditLogs['from'] }}–{{ $auditLogs['to'] }} of {{ $auditLogs['total'] }}</small>
        <div class="d-flex gap-1">
            @if($auditLogs['current_page'] > 1)
                <a href="?page={{ $auditLogs['current_page'] - 1 }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-left"></i>
                </a>
            @endif
            @for($p = max(1, $auditLogs['current_page'] - 2); $p <= min($auditLogs['last_page'], $auditLogs['current_page'] + 2); $p++)
                <a href="?page={{ $p }}"
                   class="btn btn-sm {{ $p === $auditLogs['current_page'] ? 'btn-primary' : 'btn-outline-secondary' }}"
                   style="border-radius:6px;">{{ $p }}</a>
            @endfor
            @if($auditLogs['current_page'] < $auditLogs['last_page'])
                <a href="?page={{ $auditLogs['current_page'] + 1 }}"
                   class="btn btn-sm btn-outline-secondary" style="border-radius:6px;">
                    <i class="bi bi-chevron-right"></i>
                </a>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
