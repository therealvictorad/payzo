<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Crypt;

class VirtualCard extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'card_number',   // stored encrypted
        'expiry',
        'cvv',           // stored encrypted
        'card_holder',
        'brand',
        'status',
        'spending_limit',
    ];

    // Never expose raw encrypted values in JSON output
    protected $hidden = ['card_number', 'cvv'];

    protected function casts(): array
    {
        return [
            'spending_limit' => 'decimal:2',
        ];
    }

    // ─── Encryption Mutators ──────────────────────────────────────────────────

    /**
     * Always encrypt before saving to DB.
     */
    public function setCardNumberAttribute(string $value): void
    {
        $this->attributes['card_number'] = Crypt::encryptString($value);
    }

    public function setCvvAttribute(string $value): void
    {
        $this->attributes['cvv'] = Crypt::encryptString($value);
    }

    // ─── Decryption Accessors ─────────────────────────────────────────────────

    /**
     * Decrypt on read — only used internally (e.g. on card creation response).
     * Never returned in standard JSON because 'card_number' is in $hidden.
     */
    public function getDecryptedCardNumber(): string
    {
        return Crypt::decryptString($this->attributes['card_number']);
    }

    public function getDecryptedCvv(): string
    {
        return Crypt::decryptString($this->attributes['cvv']);
    }

    // ─── Safe Accessors ───────────────────────────────────────────────────────

    /** Returns masked card: **** **** **** 4242 */
    public function getMaskedNumberAttribute(): string
    {
        $full = $this->getDecryptedCardNumber();
        return '**** **** **** ' . substr($full, -4);
    }

    // ─── Relationships ────────────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
