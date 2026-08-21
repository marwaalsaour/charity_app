<?php

/**
 * Fix sponsorOrphan so the URL id can be either:
 *   - orphans.id
 *   - requests.id (request_id on the orphan row)
 *
 * Flutter may send the case/request id. GitHub currently does:
 *   Orphan::findOrFail($orphanId)
 * which 404s when that number is the request id, or when nested JSON
 * had a stale/wrong orphan id.
 *
 * Replace RequestController::sponsorOrphan with this lookup.
 */

namespace App\Http\Controllers;

use App\Models\Orphan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

trait SponsorOrphanLookup
{
    public function sponsorOrphan(Request $request, $orphanId)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $requestId = $request->input('request_id');

        $orphan = Orphan::find($orphanId)
            ?? Orphan::where('request_id', $orphanId)->first()
            ?? (is_numeric($requestId)
                ? Orphan::where('request_id', (int) $requestId)->first()
                : null);

        if (!$orphan) {
            return response()->json([
                'success' => false,
                'message' => 'Orphan record not found for this case.',
            ], 404);
        }

        $result = $orphan->sponsorOrphan($user);

        return response()->json($result, $result['success'] ? 200 : 400);
    }
}
