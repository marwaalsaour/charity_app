<?php

/**
 * Beneficiary case funding + payout (wallet vs association center).
 *
 * Flutter expects:
 *
 * 1) GET /myrequests items should include:
 *    - required_amount
 *    - donated_amount
 *    - donors_count
 *    - currency (optional, default SYP)
 *    - payout_preference: unset | wallet | association_center
 *
 * 2) When donated_amount >= required_amount, push FCM:
 *    type = caseFullyFunded
 *    role = beneficiary
 *    route = /beneficiary/home
 *    (see FcmService::notifyCaseFullyFunded)
 *
 * 3) POST /requests/{id}/payout-preference
 *    body: { "preference": "wallet" | "association_center" }
 *
 *    If preference is wallet, credit the beneficiary user balances
 *    (same balances field used by GET /userprofile).
 *
 *    If preference is association_center, mark the disbursement as
 *    pickup-at-center so staff can hand the amount over in person.
 *
 * Example trigger after a successful POST /donate/request/{id}:
 *
 *   $request->refresh();
 *   $required = (float) $request->required_amount;
 *   $raised = (float) $request->donated_amount;
 *   if ($required > 0 && $raised >= $required) {
 *       $beneficiary = $request->beneficiary?->user;
 *       if ($beneficiary?->fcm_token) {
 *           app(FcmService::class)->notifyCaseFullyFunded(
 *               $beneficiary->fcm_token,
 *               $request->title ?? (string) $request->id,
 *               number_format($required, 0, '.', ''),
 *               $request->currency ?? 'SYP',
 *           );
 *       }
 *   }
 */
