<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('virtual_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('card_number', 16);              // masked on retrieval
            $table->string('expiry');                       // MM/YY
            $table->string('cvv', 3);                       // masked on retrieval
            $table->string('card_holder');
            $table->enum('brand', ['visa', 'mastercard'])->default('visa');
            $table->enum('status', ['active', 'frozen', 'terminated'])->default('active');
            $table->decimal('spending_limit', 15, 2)->default(500.00);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('virtual_cards');
    }
};
