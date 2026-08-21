<?php

/**
 * Flutter home + transparency "volunteers" card:
 *
 *   GET /api/approved-general-volunteers   → association volunteers
 *   GET /api/volunteers/summary            → campaign-only volunteers
 *
 * The app sums the two `count` fields.
 *
 * getAllVolunteersSummary() currently returns 403 for non-admins.
 * The public home screen cannot show campaign volunteers until that
 * check is removed (or a count-only route is added for any auth user).
 *
 * In VolunteerController::getAllVolunteersSummary, delete:
 *
 *   if ($user->role !== 'admin') { ... 403 }
 *
 * Keep the query as campaign volunteers only:
 *
 *   Volunteer::where('general_application', 0)->where('status', 'approved')
 *
 * Response stays:
 *
 *   { "success": true, "count": 12, "data": [ ... ] }
 */
