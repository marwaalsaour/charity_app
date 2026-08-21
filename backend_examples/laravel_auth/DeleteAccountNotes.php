<?php

/**
 * Delete account — live Ataa-Project (Azure) already has:
 *
 *   Route::delete('/deleteMyAccount', [UserController::class, 'deleteMyAccount']);
 *   Route::delete('/deleteUser/{id}', [UserController::class, 'deleteUser']);
 *
 * Flutter: DELETE /api/deleteMyAccount  (Bearer token)
 * Fallback: DELETE /api/deleteUser/{id}
 *
 * deleteMyAccount() deletes the authenticated user (and their tokens).
 * The example below also cleans related rows if foreign keys block $user->delete().
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

trait DeleteAccountExample
{
    public function deleteAccount(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $role = $user->role ?? $user->user_category ?? '';
        if (in_array($role, ['admin', 'sub_admin'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'This account cannot be deleted from the app.',
            ], 403);
        }

        try {
            DB::transaction(function () use ($user) {
                $userId = $user->id;

                if (method_exists($user, 'tokens')) {
                    $user->tokens()->delete();
                }

                if (Schema::hasTable('donors')) {
                    $donorIds = DB::table('donors')->where('user_id', $userId)->pluck('id');
                    if ($donorIds->isNotEmpty() && Schema::hasTable('donations')) {
                        DB::table('donations')->whereIn('donor_id', $donorIds)->delete();
                    }
                    DB::table('donors')->where('user_id', $userId)->delete();
                }

                if (Schema::hasTable('requests')) {
                    $requestIds = DB::table('requests')->where('user_id', $userId)->pluck('id');
                    $nested = [
                        'patients' => 'App\\Models\\Patient',
                        'orphans' => 'App\\Models\\Orphan',
                        'school_students' => 'App\\Models\\SchoolStudent',
                        'university_students' => 'App\\Models\\UniversityStudent',
                    ];
                    foreach ($nested as $table => $morphType) {
                        if ($requestIds->isEmpty() || !Schema::hasTable($table)) {
                            continue;
                        }
                        $ids = DB::table($table)->whereIn('request_id', $requestIds)->pluck('id');
                        if ($ids->isNotEmpty() && Schema::hasTable('donations')) {
                            DB::table('donations')
                                ->where('donationable_type', $morphType)
                                ->whereIn('donationable_id', $ids)
                                ->delete();
                        }
                        DB::table($table)->whereIn('request_id', $requestIds)->delete();
                    }
                    DB::table('requests')->where('user_id', $userId)->delete();
                }

                foreach ([
                    'volunteer_applications',
                    'volunteer_hours',
                    'user_notifications',
                    'orphan_sponsorships',
                    'orphans_sponsorships',
                    'orphan_sponsors',
                ] as $table) {
                    if (Schema::hasTable($table) && Schema::hasColumn($table, 'user_id')) {
                        DB::table($table)->where('user_id', $userId)->delete();
                    }
                }

                foreach (['profile_image', 'national_id', 'international_passport'] as $field) {
                    $path = $user->{$field} ?? null;
                    if (is_string($path) && $path !== '') {
                        Storage::disk('public')->delete($path);
                    }
                }

                $user->delete();
            });

            return response()->json([
                'success' => true,
                'message' => 'Account deleted successfully.',
            ], 200);
        } catch (\Throwable $e) {
            Log::error('deleteAccount failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete account.',
            ], 500);
        }
    }
}
