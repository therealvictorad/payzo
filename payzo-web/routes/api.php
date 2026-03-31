<?php

use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BillController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\PaymentLinkController;
use App\Http\Controllers\TopupController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\VirtualCardController;
use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

// ─── Public Routes ────────────────────────────────────────────────────────────

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

// ─── Authenticated Routes ─────────────────────────────────────────────────────

Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);

    // Wallet
    Route::get('/wallet', [WalletController::class, 'show']);

    // Transfers & history
    Route::post('/transfer',    [TransactionController::class, 'transfer']);
    Route::get('/transactions', [TransactionController::class, 'index']);

    // Mobile top-up (airtime & data)
    Route::post('/topup', [TopupController::class, 'topup']);

    // Bill payments
    Route::post('/bills/pay', [BillController::class, 'pay']);

    // Payment links
    Route::post('/payment-links',       [PaymentLinkController::class, 'create']);
    Route::get('/payment-links',        [PaymentLinkController::class, 'index']);
    Route::post('/pay/{code}',          [PaymentLinkController::class, 'pay']);

    // Virtual cards
    Route::post('/cards', [VirtualCardController::class, 'create']);
    Route::get('/cards',  [VirtualCardController::class, 'index']);

    // ─── Admin Only ───────────────────────────────────────────────────────────
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/users',         [AdminController::class, 'users']);
        Route::get('/transactions',  [AdminController::class, 'transactions']);
        Route::get('/fraud-logs',    [AdminController::class, 'fraudLogs']);
        Route::get('/topups',        [AdminController::class, 'topups']);
        Route::get('/bills',         [AdminController::class, 'bills']);
        Route::get('/payment-links', [AdminController::class, 'paymentLinks']);
        Route::get('/cards',         [AdminController::class, 'cards']);
    });
});

// ─── Paystack Payments ───────────────────────────────────────────────────────
// Webhook must be outside auth middleware (Paystack calls it directly)
Route::post('/payments/webhook', [PaymentController::class, 'handleWebhook']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/payments/initialize',          [PaymentController::class, 'initializePayment']);
    Route::get('/payments/verify/{reference}',   [PaymentController::class, 'verifyPayment']);
});

// ─── Status Check ─────────────────────────────────────────────────────────────
Route::get('/status', fn () => response()->json(['status' => 'ok']));
