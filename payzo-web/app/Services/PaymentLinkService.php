<?php

namespace App\Services;

use App\Models\PaymentLink;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PaymentLinkService
{
    /**
     * Create a new payment link for the authenticated user.
     */
    public function create(User $user, array $data): PaymentLink
    {
        return PaymentLink::create([
            'user_id'     => $user->id,
            'code'        => $this->generateCode(),
            'amount'      => $data['amount'],
            'description' => $data['description'] ?? null,
            'status'      => 'active',
        ]);
    }

    /**
     * Pay a payment link using the payer's wallet.
     * Transfers funds from payer → link owner.
     */
    public function pay(string $code, User $payer): array
    {
        $link = PaymentLink::where('code', $code)->firstOrFail();

        if ($link->status !== 'active') {
            throw ValidationException::withMessages([
                'code' => "This payment link is {$link->status}.",
            ]);
        }

        if ($link->user_id === $payer->id) {
            throw ValidationException::withMessages([
                'code' => 'You cannot pay your own payment link.',
            ]);
        }

        if ($payer->wallet()->value('balance') < $link->amount) {
            throw ValidationException::withMessages([
                'amount' => 'Insufficient wallet balance.',
            ]);
        }

        $transaction = DB::transaction(function () use ($link, $payer) {
            // Deduct from payer
            $payer->wallet()->lockForUpdate()->first()->decrement('balance', $link->amount);

            // Credit link owner
            $link->owner->wallet()->lockForUpdate()->first()->increment('balance', $link->amount);

            // Record transaction
            $transaction = Transaction::create([
                'sender_id'   => $payer->id,
                'receiver_id' => $link->user_id,
                'amount'      => $link->amount,
                'status'      => 'success',
                'type'        => 'payment_link',
                'meta'        => [
                    'link_code'   => $link->code,
                    'description' => $link->description,
                ],
            ]);

            // Mark link as paid
            $link->update([
                'status'  => 'paid',
                'paid_by' => $payer->id,
                'paid_at' => now(),
            ]);

            return $transaction;
        });

        return [
            'transaction'  => $transaction->load(['sender:id,name,email', 'receiver:id,name,email']),
            'payment_link' => $link->fresh(),
        ];
    }

    /**
     * Get all payment links for a user.
     */
    public function getUserLinks(User $user)
    {
        return PaymentLink::where('user_id', $user->id)
            ->with('payer:id,name,email')
            ->latest()
            ->paginate(15);
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    private function generateCode(): string
    {
        do {
            $code = 'PAY-' . strtoupper(Str::random(8));
        } while (PaymentLink::where('code', $code)->exists());

        return $code;
    }
}
