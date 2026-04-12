<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kyc_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->enum('document_type', ['nin', 'bvn', 'passport', 'drivers_license']);

            // Stored in storage/app/private/kyc/ — not publicly accessible
            $table->string('document_path');

            // Optional: BVN/NIN number entered by user (mock — not verified externally)
            $table->string('document_number')->nullable();

            $table->string('full_name');
            $table->date('date_of_birth');
            $table->string('address')->nullable();

            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('rejection_reason')->nullable();

            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();

            $table->timestamps();

            // Indexes
            $table->index(['user_id', 'status']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kyc_documents');
    }
};
