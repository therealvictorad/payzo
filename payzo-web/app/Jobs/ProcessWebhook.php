<?php

namespace App\Jobs;

use App\Models\PaystackTransaction;
use App\Repositories\WalletRepository;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;
    public int $backoff = 30;

    public function __construct(private readonly array $payload) {}

    public function handle(WalletRepository $walletRepo): void
    {
        $event     = $this->payload['event'] ?? null;
        $data      = $this->payload['data'] ?? [];
        $reference = $data['reference'] ?? null;

        if ($event !== 'charge.success' || ! $reference) {
            return;
        }

        DB::transaction(function () use ($reference, $data, $walletRepo) {
            $tx = PaystackTransaction::where('reference', $reference)
                ->where('status', '!=', 'success')
                ->lockForUpdate()
                ->first();

            if (! $tx) {
                return; // Already processed — idempotent
            }

            $tx->update(['status' => 'success']);

            $walletRepo->credit($tx->user, $tx->amount / 100); // kobo → naira
        });
    }

    public function failed(\Throwable $e): void
    {
        Log::error('ProcessWebhook job failed', [
            'payload' => $this->payload,
            'error'   => $e->getMessage(),
        ]);
    }
}
