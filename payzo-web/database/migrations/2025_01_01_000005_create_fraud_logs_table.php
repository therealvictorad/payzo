<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fraud_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('transaction_id')->constrained()->cascadeOnDelete();
            $table->string('rule_triggered'); // e.g. LARGE_TRANSACTION, RAPID_TRANSACTIONS, UNUSUAL_TIME
            $table->enum('risk_level', ['LOW', 'MEDIUM', 'HIGH']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fraud_logs');
    }
};
