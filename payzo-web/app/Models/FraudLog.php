<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FraudLog extends Model
{
    protected $fillable = ['user_id', 'transaction_id', 'rule_triggered', 'risk_level'];

    // ─── Relationships ────────────────────────────────────────────────────────

    /** The user associated with this fraud event */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** The transaction that triggered this fraud event */
    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }
}
