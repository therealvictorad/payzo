<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'referral_code',
        'referred_by',
        'is_frozen',
        'transaction_pin',
        'kyc_level',
        'kyc_status',
        'kyc_submitted_at',
        'nickname',
        'gender',
        'date_of_birth',
        'mobile',
        'address',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'transaction_pin',
    ];

    protected $appends = ['has_transaction_pin'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'transaction_pin'   => 'hashed',
            'is_frozen'         => 'boolean',
            'kyc_submitted_at'  => 'datetime',
        ];
    }

    // ─── Relationships ────────────────────────────────────────────────────────

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    public function sentTransactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'sender_id');
    }

    public function receivedTransactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'receiver_id');
    }

    public function fraudLogs(): HasMany
    {
        return $this->hasMany(FraudLog::class);
    }

    public function referrer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'referred_by');
    }

    public function referrals(): HasMany
    {
        return $this->hasMany(User::class, 'referred_by');
    }

    public function kycDocuments(): HasMany
    {
        return $this->hasMany(KycDocument::class);
    }

    public function latestKyc(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(KycDocument::class)->latestOfMany();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isAgent(): bool
    {
        return $this->role === 'agent';
    }

    public function isFrozen(): bool
    {
        return (bool) $this->is_frozen;
    }

    public function hasVerifiedEmail(): bool
    {
        return $this->email_verified_at !== null;
    }

    public function hasTransactionPin(): bool
    {
        return $this->transaction_pin !== null;
    }

    public function getHasTransactionPinAttribute(): bool
    {
        return $this->hasTransactionPin();
    }

    public function isKycVerified(): bool
    {
        return $this->kyc_status === 'verified';
    }

    /**
     * Per-transaction limit by tier.
     * tier0 = unverified email  → \u20a610,000 per transaction
     * tier1 = email verified    → \u20a6200,000 per transaction
     * tier2 = KYC approved      → \u20a65,000,000 per transaction
     */
    public function getKycLimitAttribute(): float
    {
        return match($this->kyc_level) {
            'tier0' => 10000.00,
            'tier1' => 200000.00,
            'tier2' => 5000000.00,
            default => 10000.00,
        };
    }

    /**
     * Daily cumulative limit by tier.
     * tier0 → \u20a620,000/day
     * tier1 → \u20a6500,000/day
     * tier2 → \u20a620,000,000/day
     */
    public function getKycDailyLimitAttribute(): float
    {
        return match($this->kyc_level) {
            'tier0' => 20000.00,
            'tier1' => 500000.00,
            'tier2' => 20000000.00,
            default => 20000.00,
        };
    }
}
