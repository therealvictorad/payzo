<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add superseded status to kyc_documents so old submissions are archived
        Schema::table('kyc_documents', function (Blueprint $table) {
            $table->enum('status', ['pending', 'approved', 'rejected', 'superseded'])
                  ->default('pending')
                  ->change();

            // Index for daily aggregation query in TransactionService
            // covers: WHERE sender_id = ? AND status = 'success' AND created_at >= today
        });

        // Add composite index on transactions for daily limit aggregation
        Schema::table('transactions', function (Blueprint $table) {
            $table->index(['sender_id', 'status', 'created_at'], 'tx_daily_limit_idx');
        });
    }

    public function down(): void
    {
        Schema::table('kyc_documents', function (Blueprint $table) {
            $table->enum('status', ['pending', 'approved', 'rejected'])
                  ->default('pending')
                  ->change();
        });

        Schema::table('transactions', function (Blueprint $table) {
            $table->dropIndex('tx_daily_limit_idx');
        });
    }
};
