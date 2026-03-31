<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            // Type of transaction
            $table->enum('type', ['transfer', 'airtime', 'bill', 'payment_link', 'card'])
                  ->default('transfer')
                  ->after('status');

            // Flexible JSON column for type-specific metadata
            // e.g. phone_number, network, provider, customer_id, link_code
            $table->json('meta')->nullable()->after('type');

            // receiver_id is nullable for non-transfer types (airtime, bill, etc.)
            $table->foreignId('receiver_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropColumn(['type', 'meta']);
            $table->foreignId('receiver_id')->nullable(false)->change();
        });
    }
};
