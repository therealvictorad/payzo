<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add KYC columns to users table
        Schema::table('users', function (Blueprint $table) {
            $table->enum('kyc_level', ['tier0', 'tier1', 'tier2'])
                  ->default('tier0')
                  ->after('role');

            $table->enum('kyc_status', ['none', 'pending', 'verified', 'rejected'])
                  ->default('none')
                  ->after('kyc_level');

            $table->timestamp('kyc_submitted_at')->nullable()->after('kyc_status');

            $table->index('kyc_status');
            $table->index('kyc_level');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['kyc_status']);
            $table->dropIndex(['kyc_level']);
            $table->dropColumn(['kyc_level', 'kyc_status', 'kyc_submitted_at']);
        });
    }
};
