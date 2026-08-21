<?php

/**
 * How donor counts are wired for the Flutter app.
 *
 * 1) After POST /donate/request/{id} succeeds, return:
 *    - donated_amount  (sum of morph donations)
 *    - donors_count    (count of morph donations)
 *
 * 2) On GET /getopenaccepted* payloads, each request must include:
 *    - donated_amount
 *    - donors_count
 *    - progress_percentage
 *    (see RequestController::attachDonationProgress)
 *
 * 3) Home KPI: GET /homestats → data.total_donors = Donation::count()
 *
 * Important: the donations table has NO status column. Do NOT filter
 * where('status', 'approved') or donors_count stays 0 forever.
 *
 * Deploy the local Ataa-Project-main RequestController + DonationController
 * + DashboardController::homeStats to Azure, then hot-restart the app.
 */