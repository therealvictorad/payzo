<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Mail\Message;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendTransactionNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public function __construct(
        private readonly Transaction $transaction,
        private readonly string $recipientType // 'sender' | 'receiver'
    ) {}

    public function handle(): void
    {
        $tx   = $this->transaction->load(['sender:id,name,email', 'receiver:id,name,email']);
        $user = $this->recipientType === 'sender' ? $tx->sender : $tx->receiver;

        if (! $user) {
            return;
        }

        $subject = $this->recipientType === 'sender'
            ? "You sent ₦{$tx->amount} — Ref: {$tx->reference}"
            : "You received ₦{$tx->amount} — Ref: {$tx->reference}";

        $body = $this->recipientType === 'sender'
            ? "Your transfer of ₦{$tx->amount} to {$tx->receiver?->email} was successful.\nReference: {$tx->reference}"
            : "You received ₦{$tx->amount} from {$tx->sender?->name}.\nReference: {$tx->reference}";

        Mail::raw($body, function (Message $msg) use ($user, $subject) {
            $msg->to($user->email, $user->name)->subject($subject);
        });
    }
}
