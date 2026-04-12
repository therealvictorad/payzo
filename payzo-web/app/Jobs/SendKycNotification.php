<?php

namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Mail\Message;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendKycNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public function __construct(
        private readonly User $user,
        private readonly string $outcome,  // 'approved' | 'rejected'
        private readonly ?string $reason = null
    ) {}

    public function handle(): void
    {
        if ($this->outcome === 'approved') {
            $subject = 'Your Payzo account has been verified ✅';
            $body    = "Hi {$this->user->name},\n\n"
                     . "Your identity verification has been approved.\n"
                     . "You now have full access to Payzo with higher transaction limits.\n\n"
                     . "Thank you for verifying your account.\n\nPayzo Team";
        } else {
            $subject = 'Your Payzo KYC submission was rejected';
            $body    = "Hi {$this->user->name},\n\n"
                     . "Unfortunately, your identity verification was rejected.\n\n"
                     . "Reason: {$this->reason}\n\n"
                     . "Please resubmit with a clearer document in the Payzo app.\n\nPayzo Team";
        }

        Mail::raw($body, function (Message $msg) use ($subject) {
            $msg->to($this->user->email, $this->user->name)->subject($subject);
        });
    }
}
