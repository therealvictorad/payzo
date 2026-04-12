<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('virtual_cards', function (Blueprint $table) {
            // Encrypted values are base64-encoded JSON — much longer than 16/3 chars
            $table->text('card_number')->change();
            $table->text('cvv')->change();
        });
    }

    public function down(): void
    {
        Schema::table('virtual_cards', function (Blueprint $table) {
            $table->string('card_number', 16)->change();
            $table->string('cvv', 3)->change();
        });
    }
};
