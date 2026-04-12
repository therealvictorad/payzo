<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // User account freeze flag
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_frozen')->default(false)->after('role');
            $table->boolean('email_verified_enforced')->default(false)->after('is_frozen');
            $table->string('transaction_pin')->nullable()->after('email_verified_enforced'); // hashed
        });

        // Fraud log resolution
        Schema::table('fraud_logs', function (Blueprint $table) {
            $table->enum('resolution', ['open', 'resolved', 'escalated'])->default('open')->after('risk_level');
            $table->text('resolution_note')->nullable()->after('resolution');
            $table->foreignId('resolved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
        });

        // Admin audit trail
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnDelete();
            $table->string('action');           // e.g. freeze_user, reverse_transaction
            $table->string('target_type');      // e.g. User, Transaction
            $table->unsignedBigInteger('target_id');
            $table->json('before')->nullable(); // snapshot before change
            $table->json('after')->nullable();  // snapshot after change
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            $table->index(['target_type', 'target_id']);
            $table->index(['admin_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['is_frozen', 'email_verified_enforced', 'transaction_pin']);
        });
        Schema::table('fraud_logs', function (Blueprint $table) {
            $table->dropColumn(['resolution', 'resolution_note', 'resolved_by', 'resolved_at']);
        });
        Schema::dropIfExists('audit_logs');
    }
};
