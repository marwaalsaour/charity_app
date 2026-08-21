<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Sends push notifications via Firebase Cloud Messaging HTTP v1.
 *
 * Setup:
 * 1. Firebase Console → Project Settings → Service accounts → Generate new private key
 * 2. Store the JSON file outside public/ (e.g. storage/app/firebase/service-account.json)
 * 3. In .env:
 *    FCM_PROJECT_ID=ataa-chairty
 *    FCM_CREDENTIALS=storage/app/firebase/service-account.json
 */
class FcmService
{
    public function sendToToken(
        string $fcmToken,
        string $title,
        string $body,
        array $data = [],
    ): bool {
        if (trim($fcmToken) === '') {
            return false;
        }

        $projectId = config('services.fcm.project_id');
        $accessToken = $this->getAccessToken();

        // FCM data values must be strings.
        $stringData = [];
        foreach ($data as $key => $value) {
            $stringData[(string) $key] = is_scalar($value) ? (string) $value : json_encode($value);
        }

        $payload = [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                // Shown by Android automatically when app is in background/killed.
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'ataa_default_channel',
                        'sound' => 'default',
                    ],
                ],
                'data' => $stringData,
            ],
        ];

        $response = Http::withToken($accessToken)
            ->acceptJson()
            ->post(
                "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send",
                $payload,
            );

        if (!$response->successful()) {
            Log::warning('FCM send failed', [
                'status' => $response->status(),
                'body' => $response->json() ?? $response->body(),
            ]);
            return false;
        }

        return true;
    }

    /**
     * Convenience helpers matching ATAA Flutter notification types.
     */
    public function notifyDonationSuccess(string $fcmToken, string $amount, string $currency = 'USD'): bool
    {
        return $this->sendToToken(
            $fcmToken,
            'تم التبرع بنجاح',
            "شكراً لتبرعك بمبلغ {$amount} {$currency}",
            [
                'type' => 'donationSuccess',
                'role' => 'donor',
                'route' => '/donor/notifications',
            ],
        );
    }

    public function notifyRequestSubmitted(string $fcmToken, string $requestTitle): bool
    {
        return $this->sendToToken(
            $fcmToken,
            'تم إرسال الطلب',
            "تم استلام طلبك: {$requestTitle}",
            [
                'type' => 'requestSubmitted',
                'role' => 'beneficiary',
                'route' => '/beneficiary/notifications',
            ],
        );
    }

    public function notifyBeneficiaryDecision(
        string $fcmToken,
        bool $approved,
        string $requestTitle,
    ): bool {
        return $this->sendToToken(
            $fcmToken,
            $approved ? 'تمت الموافقة على الطلب' : 'تم رفض الطلب',
            $approved
                ? "تمت الموافقة على طلبك: {$requestTitle}"
                : "تم رفض طلبك: {$requestTitle}",
            [
                'type' => $approved ? 'beneficiaryApproved' : 'beneficiaryRejected',
                'role' => 'beneficiary',
                'route' => '/beneficiary/requests',
            ],
        );
    }

    public function notifyCaseFullyFunded(
        string $fcmToken,
        string $requestTitle,
        string $amount = '',
        string $currency = 'SYP',
    ): bool {
        $amountText = $amount !== '' ? " ({$amount} {$currency})" : '';

        return $this->sendToToken(
            $fcmToken,
            'اكتمل مبلغ حالتك',
            "اكتمل المبلغ المطلوب لحالتك: {$requestTitle}{$amountText}. سيتم شحنه إلى محفظتك، أو يمكنك استلامه من مركز الجمعية.",
            [
                'type' => 'caseFullyFunded',
                'role' => 'beneficiary',
                'route' => '/beneficiary/home',
            ],
        );
    }

    private function getAccessToken(): string
    {
        return Cache::remember('fcm_access_token', 3500, function () {
            $credentialsPath = base_path(config('services.fcm.credentials'));
            if (!is_file($credentialsPath)) {
                throw new RuntimeException("FCM credentials not found: {$credentialsPath}");
            }

            $json = json_decode(file_get_contents($credentialsPath), true);
            if (!is_array($json)) {
                throw new RuntimeException('Invalid FCM service account JSON');
            }

            $now = time();
            $header = $this->base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claim = $this->base64UrlEncode(json_encode([
                'iss' => $json['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));

            $unsigned = "{$header}.{$claim}";
            $privateKey = openssl_pkey_get_private($json['private_key']);
            if ($privateKey === false) {
                throw new RuntimeException('Unable to load FCM private key');
            }

            openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256);
            $jwt = "{$unsigned}." . $this->base64UrlEncode($signature);

            $tokenResponse = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if (!$tokenResponse->successful()) {
                throw new RuntimeException('Failed to obtain FCM access token: ' . $tokenResponse->body());
            }

            $accessToken = $tokenResponse->json('access_token');
            if (!$accessToken) {
                throw new RuntimeException('FCM access_token missing in response');
            }

            return $accessToken;
        });
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
