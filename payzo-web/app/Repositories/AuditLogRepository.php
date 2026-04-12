<?php

namespace App\Repositories;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AuditLogRepository
{
    /**
     * Record an admin action.
     *
     * @param User   $admin      The admin performing the action
     * @param string $action     e.g. 'freeze_user', 'reverse_transaction', 'resolve_fraud'
     * @param object $target     The Eloquent model being acted on
     * @param array  $before     Snapshot of state before the action
     * @param array  $after      Snapshot of state after the action
     * @param string $ip         Request IP address
     */
    public function record(
        User $admin,
        string $action,
        object $target,
        array $before = [],
        array $after = [],
        string $ip = ''
    ): AuditLog {
        return AuditLog::create([
            'admin_id'    => $admin->id,
            'action'      => $action,
            'target_type' => class_basename($target),
            'target_id'   => $target->id,
            'before'      => $before,
            'after'       => $after,
            'ip_address'  => $ip,
        ]);
    }

    public function paginate(int $perPage = 30): LengthAwarePaginator
    {
        return AuditLog::with('admin:id,name,email')
            ->latest()
            ->paginate($perPage);
    }
}
