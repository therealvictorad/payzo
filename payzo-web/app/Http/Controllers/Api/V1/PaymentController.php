<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessWebhook;
use App\Models\PaystackTransaction;
use App\Repositories\WalletRepository;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    use ApiResponse;

    private string $secret;
    private string $baseUrl = 'https://api.paystack.co';

    public function __construct(private readonly WalletRepository $walletRepo)
    {
        $this->secret = config('services.paystack.secret');
    }

    public function initializePayment(Request $request): JsonResponse
    {
        $request->validate([
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

        if ($response->json('data.status') === 'success') {
            // Dispatch to queue — same handler as webhook
            ProcessWebhook::dispatch([
                'event' => 'charge.success',
                'data'  => ['reference' => $reference],
            ]);
        } else {
            $transaction->update(['status' => 'failed']);
        }

        return $this->success('Payment verified', ['status' => $transaction->fresh()->status]);
    }

    /**
     * Paystack webhook — validate signature, dispatch to queue immediately.
     * Must respond within 5 seconds or Paystack retries.
     */
    public function handleWebhook(Request $request): JsonResponse
    {
        $signature = $request->header('x-paystack-signature');
        $payload   = $request->getContent();

        if (hash_hmac('sha512', $payload, $this->secret) !== $signature) {
            return response()->json(['message' => 'Invalid signature'], 401);
        }

        // Dispatch to queue — return 200 immediately
        ProcessWebhook::dispatch($request->json()->all());

        return response()->json(['message' => 'Webhook received'], 200);
    }
}
