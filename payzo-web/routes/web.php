<?php

use App\Http\Controllers\AdminDashboardController;
use Illuminate\Support\Facades\Route;

// ─── Admin Login ──────────────────────────────────────────────────────────────
Route::get( '/admin/login',  [AdminDashboardController::class, 'loginForm'])->name('admin.login');
Route::post('/admin/login',  [AdminDashboardController::class, 'loginPost'])->name('admin.login.post');
Route::post('/admin/logout', [AdminDashboardController::class, 'logout'])->name('admin.logout');

// ─── Protected Dashboard Routes ───────────────────────────────────────────────
Route::middleware('admin.dash')->prefix('admin')->group(function () {
    Route::get('/',             [AdminDashboardController::class, 'dashboard'])->name('admin.dashboard');
    Route::get('/users',        [AdminDashboardController::class, 'users'])->name('admin.users');
    Route::get('/transactions', [AdminDashboardController::class, 'transactions'])->name('admin.transactions');
    Route::get('/fraud-logs',   [AdminDashboardController::class, 'fraudLogs'])->name('admin.fraud-logs');
    Route::get('/topups',       [AdminDashboardController::class, 'topups'])->name('admin.topups');
    Route::get('/bills',        [AdminDashboardController::class, 'bills'])->name('admin.bills');
    Route::get('/payment-links',[AdminDashboardController::class, 'paymentLinks'])->name('admin.payment-links');
    Route::get('/cards',        [AdminDashboardController::class, 'cards'])->name('admin.cards');
});

// Redirect root to dashboard
Route::get('/', fn () => redirect()->route('admin.dashboard'));
