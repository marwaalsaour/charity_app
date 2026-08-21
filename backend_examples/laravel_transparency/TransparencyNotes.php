<?php

/**
 * Transparency file for the Flutter app (ملف الشفافية).
 *
 * Public endpoint consumed by the donor app:
 *   GET /api/transparency
 *
 * Admin (dashboard) should be able to update:
 *   - total donations amount + currency
 *   - beneficiaries count
 *   - volunteers count
 *   - campaigns count
 *   - annual report (year, summary ar/en, PDF file)
 *   - financial report (period, summary ar/en, PDF file)
 *   - transparency policy body (ar/en)
 *   - case verification process body (ar/en)
 *
 * Suggested JSON:
 *
 * {
 *   "success": true,
 *   "data": {
 *     "stats": {
 *       "total_donations": 12500,
 *       "currency": "USD",
 *       "beneficiaries": 86,
 *       "volunteers": 24,
 *       "campaigns": 12,
 *       "updated_at": "2026-08-18T10:00:00Z"
 *     },
 *     "annual_report": {
 *       "year": "2026",
 *       "summary_ar": "...",
 *       "summary_en": "...",
 *       "file_url": "https://.../storage/reports/annual-2026.pdf"
 *     },
 *     "financial_report": {
 *       "period": "2026",
 *       "summary_ar": "...",
 *       "summary_en": "...",
 *       "file_url": "https://.../storage/reports/financial-2026.pdf"
 *     },
 *     "policy_body_ar": "...",
 *     "policy_body_en": "...",
 *     "verification_body_ar": "...",
 *     "verification_body_en": "..."
 *   }
 * }
 *
 * Flat keys also work (annual_report_file, total_donations, ...).
 *
 * Total donations in the app is NOT an admin-typed number.
 * The Flutter client sums donated_amount from all cases plus
 * amount_collected from all campaigns, then displays USD.
 *
 * Do not require donor auth for GET /transparency — it is a public file.
 */
