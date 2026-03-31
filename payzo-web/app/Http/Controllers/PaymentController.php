<?php

namespace App\Http\Controllers;

use App\Models\PaystackTransaction;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    use ApiResponse;

    private string $secret;
    private string $baseUrl = 'https://api.paystack.co';

    public function __construct()
    {
        $this->secret = config('services.paystack.secret');
    }

    public function initializePayment(Request $request): JsonResponse
    {
        $request->validate([
            'email'  => 'required|email',
            'amount' => 'required|integer|min:100',
        ]);

        $reference = 'PAY-' . strtoupper(Str::random(12));
        $user      = $request->user();

        $response = Http::withToken($this->secret)
            ->post("{$this->baseUrl}/transaction/initialize", [
                'email'     => $user->email,
                'amount'    => $request->amount,
                'reference' => $reference,
            ]);

        if (! $response->successful() || ! $response->json('status')) {
            return $this->error($response->json('message', 'Payment initialization failed'), 502);
        }

        PaystackTransaction::create([
            'user_id'   => $user->id,
            'reference' => $reference,
            'amount'    => $request->amount,
            'status'    => 'pending',
        ]);

        return $this->success('Payment initialized', [
            'authorization_url' => $response->json('data.authorization_url'),
            'reference'         => $reference,
        ]);
    }

    public function verifyPayment(string $reference): JsonResponse
    {
        $transaction = PaystackTransaction::where('reference', $reference)->firstOrFail();

        $response = Http::withToken($this->secret)
            ->get("{$this->baseUrl}/transaction/verify/{$reference}");

        if (! $response->successful() || ! $response->json('status')) {
            return $this->error($response->json('message', 'Verification failed'), 502);
        }

        $paystackStatus = $response->json('data.status');

        if ($paystackStatus === 'success') {
            $this->creditWallet($transaction);
        } else {
            $transaction->update(['status' => 'failed']);
        }

        return $this->success('Payment verified', ['status' => $transaction->fresh()->status]);
    }

    public function handleWebhook(Request $request): JsonResponse
    {
        $signature = $request->header('x-paystack-signature');
        $payload   = $request->getContent();

        if (hash_hmac('sha512', $payload, $this->secret) !== $signature) {
            return response()->json(['message' => 'Invalid signature'], 401);
        }

        $event = $request->json('event');
        $data  = $request->json('data');

        if ($event === 'charge.success') {
            $transaction = PaystackTransaction::where('reference', $data['reference'] ?? '')->first();

            if ($transaction && $transaction->status !== 'success') {
                $this->creditWallet($transaction);
            }
        }

        return response()->json(['message' => 'Webhook received'], 200);
    }

    private function creditWallet(PaystackTransaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            // Re-fetch with lock to prevent race conditions
            $tx = PaystackTransaction::where('id', $transaction->id)
                ->where('status', '!=', 'success')
                ->lockForUpdate()
                ->first();

            if (! $tx) {
                return; // Already credited
            }

            $tx->update(['status' => 'success']);

            $tx->user->wallet()->increment('balance', $tx->amount / 100); // convert kobo to naira
        });
    }
}
