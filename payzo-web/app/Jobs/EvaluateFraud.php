<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Models\User;
use App\Services\FraudService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class EvaluateFraud implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 10; // seconds between retries

    public function __construct(
        private readonly User $sender,
        private readonly Transaction $transaction
    ) {}

    public function handle(FraudService $fraudService): void
    {
        $fraudService->evaluate($this->sender, $this->transaction);
    }
}
