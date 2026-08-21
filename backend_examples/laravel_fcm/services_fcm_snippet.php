<?php

/**
 * Add to config/services.php:
 *
 * 'fcm' => [
 *     'project_id' => env('FCM_PROJECT_ID'),
 *     'credentials' => env('FCM_CREDENTIALS', 'storage/app/firebase/service-account.json'),
 * ],
 *
 * Add to .env:
 * FCM_PROJECT_ID=ataa-chairty
 * FCM_CREDENTIALS=storage/app/firebase/service-account.json
 *
 * Migration snippet for users table:
 * $table->string('fcm_token', 512)->nullable();
 *
 * routes/api.php (examples):
 * Route::middleware('auth:sanctum')->group(function () {
 *     Route::post('/updateFcmToken', [FcmTokenController::class, 'updateFcmToken']);
 *     Route::post('/notifications/test-push', [FcmTokenController::class, 'testPush']);
 * });
 */

return [
    'fcm' => [
        'project_id' => env('FCM_PROJECT_ID'),
        'credentials' => env('FCM_CREDENTIALS', 'storage/app/firebase/service-account.json'),
    ],
];
