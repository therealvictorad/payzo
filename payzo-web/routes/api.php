<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BillController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\PaymentLinkController;
use App\Http\Controllers\Api\V1\TopupController;
use App\Http\Controllers\Api\V1\TransactionController;
use App\Http\Controllers\Api\V1\UserController;
use App\Http\Controllers\Api\V1\VirtualCardController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Controllers\Api\V1\PinController;
use App\Http\Controllers\Api\V1\Admin\AdminController;
use App\Http\Controllers\Api\V1\Admin\AdminKycController;
use App\Http\Controllers\Api\V1\KycController;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// ─── Status ───────────────────────────────────────────────────────────────────
Route::get('/status', fn () => response()->json(['status' => 'ok', 'version' => 'v1']));

// ─── Paystack Webhook (no auth — Paystack calls this directly) ────────────────
Route::post('/v1/payments/webhook', [PaymentController::class, 'handleWebhook']);

// ─── V1 Public ────────────────────────────────────────────────────────────────
Route::prefix('v1')->group(function () {

    Route::middleware('throttle:10,1')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login',    [AuthController::class, 'login']);
    });

    // ─── Authenticated ────────────────────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('/logout', [AuthController::class, 'logout']);

        // User Profile
        Route::get('/user/profile', [UserController::class, 'profile']);
        Route::put('/user/profile', [UserController::class, 'updateProfile']);

        // Email verification
        Route::post('/email/verification-notification', function (Request $request) {
            $request->user()->sendEmailVerificationNotification();
            return response()->json(['status' => 'success', 'message' => 'Verification email sent.']);
        })->middleware('throttle:3,1');

        Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
            $request->fulfill();
            return response()->json(['status' => 'success', 'message' => 'Email verified successfully.']);
        })->middleware('signed')->name('verification.verify');

        // Wallet
        Route::get('/wallet', [WalletController::class, 'show']);

        // Transaction PIN
        Route::post('/pin/set',    [PinController::class, 'set']);
        Route::post('/pin/verify', [PinController::class, 'verify']);

        // Transfers & history — require verified email + unfrozen account
        Route::middleware(['email.verified', 'not.frozen'])->group(function () {
            Route::post('/transfer',    [TransactionController::class, 'transfer']);
            Route::post('/topup',       [TopupController::class, 'topup']);
            Route::post('/bills/pay',   [BillController::class, 'pay']);
            Route::post('/payment-links',  [PaymentLinkController::class, 'create']);
            Route::post('/pay/{code}',     [PaymentLinkController::class, 'pay']);
            Route::post('/cards',          [VirtualCardController::class, 'create']);
        });

        // Read-only — no email/freeze gate needed
        Route::get('/transactions',    [TransactionController::class, 'index']);
        Route::get('/payment-links',   [PaymentLinkController::class, 'index']);
        Route::get('/cards',           [VirtualCardController::class, 'index']);

        // Paystack
        Route::post('/payments/initialize',        [PaymentController::class, 'initializePayment']);
        Route::get('/payments/verify/{reference}', [PaymentController::class, 'verifyPayment']);

        // KYC
        Route::get('/kyc/status', [KycController::class, 'status']); // no email gate — needed before verification
        Route::middleware('email.verified')->group(function () {
            Route::post('/kyc/submit', [KycController::class, 'submit']);
        });

        // ─── Admin Only ───────────────────────────────────────────────────────
        Route::middleware('role:admin')->prefix('admin')->group(function () {
            Route::get('/users',              [AdminController::class, 'users']);
            Route::get('/transactions',       [AdminController::class, 'transactions']);
            Route::get('/fraud-logs',         [AdminController::class, 'fraudLogs']);
            Route::get('/topups',             [AdminController::class, 'topups']);
            Route::get('/bills',              [AdminController::class, 'bills']);
            Route::get('/payment-links',      [AdminController::class, 'paymentLinks']);
            Route::get('/cards',              [AdminController::class, 'cards']);

            // Write actions (new)
            Route::post('/users/{user}/freeze',          [AdminController::class, 'freezeUser']);
            Route::post('/users/{user}/unfreeze',        [AdminController::class, 'unfreezeUser']);
            Route::post('/transactions/{tx}/reverse',    [AdminController::class, 'reverseTransaction']);
            Route::post('/fraud-logs/{log}/resolve',     [AdminController::class, 'resolveFraudLog']);
            Route::get('/audit-logs',                    [AdminController::class, 'auditLogs']);

            // KYC management
            Route::get('/kyc',                           [AdminKycController::class, 'index']);
            Route::post('/kyc/{id}/approve',             [AdminKycController::class, 'approve']);
            Route::post('/kyc/{id}/reject',              [AdminKycController::class, 'reject']);
        });
    });
});
