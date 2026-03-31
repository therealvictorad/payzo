<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VirtualCard extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id',
        'card_number',
        'expiry',
        'cvv',
        'card_holder',
        'brand',
        'status',
        'spending_limit',
    ];

    protected $hidden = ['cvv', 'card_number']; // never expose raw in JSON

    protected function casts(): array
    {
        return [
            'spending_limit' => 'decimal:2',
        ];
    }

    // ─── Accessors ────────────────────────────────────────────────────────────

    /** Returns masked card: **** **** **** 4242 */
    public function getMaskedNumberAttribute(): string
    {
        return '**** **** **** ' . substr($this->card_number, -4);
    }

    /** Returns masked CVV: *** */
    public function getMaskedCvvAttribute(): string
    {
        return '***';
    }

    // ─── Relationships ────────────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
