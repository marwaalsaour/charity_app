<?php

/**
 * Azure orphans table is missing sponsorship columns.
 * Flutter POST /orphanssponsor/{id} then fails with:
 *   SQLSTATE[42S22] Unknown column 'is_sponsored'
 *
 * Run this once on the live MySQL (php artisan migrate, or raw SQL).
 */

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orphans', function (Blueprint $table) {
            if (!Schema::hasColumn('orphans', 'is_sponsored')) {
                $table->boolean('is_sponsored')->default(false)->after('father_death_certificate');
            }
            if (!Schema::hasColumn('orphans', 'sponsor_id')) {
                $table->foreignId('sponsor_id')->nullable()->after('is_sponsored')
                    ->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('orphans', 'sponsorship_amount')) {
                $table->decimal('sponsorship_amount', 10, 2)->nullable()->after('sponsor_id');
            }
            if (!Schema::hasColumn('orphans', 'sponsored_at')) {
                $table->timestamp('sponsored_at')->nullable()->after('sponsorship_amount');
            }
            if (!Schema::hasColumn('orphans', 'next_monthly_deduction_at')) {
                $table->timestamp('next_monthly_deduction_at')->nullable()->after('sponsored_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orphans', function (Blueprint $table) {
            if (Schema::hasColumn('orphans', 'sponsor_id')) {
                $table->dropConstrainedForeignId('sponsor_id');
            }
            foreach ([
                'is_sponsored',
                'sponsorship_amount',
                'sponsored_at',
                'next_monthly_deduction_at',
            ] as $column) {
                if (Schema::hasColumn('orphans', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};

/*
Raw SQL if you cannot migrate:

ALTER TABLE orphans
  ADD COLUMN is_sponsored TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN sponsor_id BIGINT UNSIGNED NULL,
  ADD COLUMN sponsorship_amount DECIMAL(10,2) NULL,
  ADD COLUMN sponsored_at TIMESTAMP NULL,
  ADD COLUMN next_monthly_deduction_at TIMESTAMP NULL;

ALTER TABLE orphans
  ADD CONSTRAINT orphans_sponsor_id_foreign
  FOREIGN KEY (sponsor_id) REFERENCES users(id) ON DELETE SET NULL;
*/
