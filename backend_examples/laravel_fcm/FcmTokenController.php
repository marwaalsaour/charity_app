<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FcmService;
use Illuminate\Http\Request;

/**
 * Example endpoints for ATAA Flutter client.
 *
 * Routes (api.php):
 *   POST /api/updateFcmToken          -> updateFcmToken  (auth:sanctum)
 *   POST /api/notifications/test-push -> testPush        (auth:sanctum) optional for QA
 */
class FcmTokenController extends Controller
{
    public function updateFcmToken(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string', 'max:4096'],
        ]);

        $user = $request->user();
        $user->fcm_token = $validated['fcm_token'];
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated',
        ]);
    }

    /**
     * Optional: send a test push to the authenticated user's saved token.
     * Remove or protect in production.
     */
    public function testPush(Request $request, FcmService $fcm)
    {
        $user = $request->user();
        if (!$user->fcm_token) {
            return response()->json([
                'success' => false,
                'message' => 'No fcm_token saved for this user',
            ], 422);
        }

        $ok = $fcm->sendToToken(
            $user->fcm_token,
            'اختبار إشعار ATAA',
            'إذا رأيت هذا الإشعار فـ Push يعمل في الخلفية.',
            [
                'type' => 'general',
                'role' => $user->user_category === 'beneficiary' ? 'beneficiary' : 'donor',
                'route' => $user->user_category === 'beneficiary'
                    ? '/beneficiary/notifications'
                    : '/donor/notifications',
            ],
        );

        return response()->json([
            'success' => $ok,
            'message' => $ok ? 'Push sent' : 'Push failed — check logs',
        ], $ok ? 200 : 500);
    }
}
