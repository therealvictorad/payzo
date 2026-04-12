<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            // Unique human-readable reference (e.g. TXN-20250115-A3F9K2)
            $table->string('reference')->unique()->nullable()->after('id');

            // Idempotency key supplied by the client to prevent duplicate submissions
            $table->string('idempotency_key')->unique()->nullable()->after('reference');

            // Extend status to include pending and processing states
            // Drop old enum, re-add with full lifecycle
            $table->enum('status', ['pending', 'processing', 'success', 'failed', 'reversed'])
                  ->default('pending')
                  ->change();

            // Indexes for high-traffic queries
            $table->index(['sender_id', 'created_at']);
            $table->index(['receiver_id', 'created_at']);
            $table->index(['type', 'created_at']);
            $table->index(['status', 'created_at']);
            $table->index('reference');
        });

        // Fix the bare orWhere issue — add a composite index that covers the common history query
        Schema::table('wallets', function (Blueprint $table) {
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropColumn(['reference', 'idempotency_key']);
            $table->dropIndex(['sender_id', 'created_at']);
            $table->dropIndex(['receiver_id', 'created_at']);
            $table->dropIndex(['type', 'created_at']);
            $table->dropIndex(['status', 'created_at']);
            $table->dropIndex(['reference']);
        });
    }
};
