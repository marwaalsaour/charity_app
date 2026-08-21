<?php

/**
 * Example: call FcmService after a business event (donation / request decision).
 *
 * Place similar logic in your DonationController / RequestController / Observer / Job.
 */

use App\Models\User;
use App\Services\FcmService;

/** After a donation is recorded for a donor: */
function exampleAfterDonation(User $donor, float $amount, string $currency, FcmService $fcm): void
{
    if (!$donor->fcm_token) {
        return;
    }

    $fcm->notifyDonationSuccess(
        $donor->fcm_token,
        number_format($amount, 0, '.', ''),
        $currency,
    );
}

/** After admin approves/rejects a beneficiary request: */
function exampleAfterRequestDecision(
    User $beneficiary,
    bool $approved,
    string $requestTitle,
    FcmService $fcm,
): void {
    if (!$beneficiary->fcm_token) {
        return;
    }

    $fcm->notifyBeneficiaryDecision(
        $beneficiary->fcm_token,
        $approved,
        $requestTitle,
    );
}

/** After a donation makes donated_amount >= required_amount: */
function exampleAfterCaseFullyFunded(
    User $beneficiary,
    string $requestTitle,
    float $amount,
    string $currency,
    FcmService $fcm,
): void {
    if (!$beneficiary->fcm_token) {
        return;
    }

    $fcm->notifyCaseFullyFunded(
        $beneficiary->fcm_token,
        $requestTitle,
        number_format($amount, 0, '.', ''),
        $currency,
    );
}
