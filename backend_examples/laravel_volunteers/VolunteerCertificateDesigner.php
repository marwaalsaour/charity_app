<?php

/**
 * Volunteer certificate — match the Flutter app design.
 *
 * Flutter source of truth:
 *   lib/features/profile/data/volunteer_certificate_pdf.dart
 *
 * App endpoint:
 *   GET /api/volunteer/certificate   (auth:sanctum)
 *   returns application/pdf
 *
 * Copy:
 *   1) resources/views/certificates/volunteer.blade.php
 *      ← backend_examples/laravel_volunteers/certificates/volunteer.blade.php
 *   2) Put Cairo.ttf in storage/fonts/Cairo.ttf
 *      (same file as Flutter assets/fonts/Cairo.ttf)
 *   3) Put logo-green.png in public/images/logo-green.png
 *   4) composer require simplesoftwareio/simple-qrcode
 *
 * DomPDF:
 *   Pdf::loadView(...)->setPaper('a4', 'landscape')
 *   config/dompdf.php → isRemoteEnabled = true (for logo/QR data URIs)
 *
 * Design tokens:
 *   primary       #1A5C52
 *   primaryDark   #0F3D35
 *   gold          #C9A227
 *   cream         #FBF7EE
 *   ivory         #FFFDF8
 *   A4 landscape, double frame (gold + dark green), corner L ornaments,
 *   logo, bilingual org name, gold title, volunteer name, hours pill,
 *   footer: issue date | certificate no. | QR + unique code | signature
 */

namespace App\Support;

class VolunteerCertificateDesigner
{
    public static function uniqueCode(string $volunteerName, int $userId = 0, ?string $phone = null, ?string $email = null): string
    {
        $seed = implode('|', [
            'ataa.volunteer.certificate.v1',
            (string) $userId,
            mb_strtolower(trim($volunteerName)),
            preg_replace('/\D/', '', (string) $phone),
            mb_strtolower(trim((string) $email)),
        ]);

        $a = self::fnv1a($seed);
        $b = self::fnv1a($seed, true);

        return sprintf(
            'ATAA-%s-%s-%s',
            self::hex16($a, 16),
            self::hex16($a, 0),
            self::hex16($b, 16)
        );
    }

    public static function serialNumber(int $userId, string $uniqueCode): string
    {
        if ($userId > 0) {
            return 'VOL-' . str_pad((string) $userId, 6, '0', STR_PAD_LEFT);
        }

        $compact = preg_replace('/[^A-Z0-9]/', '', $uniqueCode);
        $tail = strlen($compact) >= 10 ? substr($compact, 4, 6) : $compact;

        return 'VOL-' . $tail;
    }

    public static function qrPayload(string $serial, string $uniqueCode, string $volunteerName, int $hours): string
    {
        return implode('|', ['ATAA', $serial, $uniqueCode, $volunteerName, $hours]);
    }

    public static function arabicDate(\DateTimeInterface $issuedAt): string
    {
        $months = [
            1 => 'يناير', 2 => 'فبراير', 3 => 'مارس', 4 => 'أبريل',
            5 => 'مايو', 6 => 'يونيو', 7 => 'يوليو', 8 => 'أغسطس',
            9 => 'سبتمبر', 10 => 'أكتوبر', 11 => 'نوفمبر', 12 => 'ديسمبر',
        ];

        return $issuedAt->format('j') . ' ' . $months[(int) $issuedAt->format('n')] . ' ' . $issuedAt->format('Y');
    }

    public static function copy(bool $isArabic, int $hours): array
    {
        if ($isArabic) {
            return [
                'title' => 'شهادة تطوع',
                'honor' => 'تُمنح هذه الشهادة إلى',
                'body' => 'تقديراً لجهود التطوع مع جمعية عطاء بعد إتمام مئة ساعة تطوع معتمدة.',
                'hours_label' => $hours . ' ساعة تطوع',
                'date_label' => 'تاريخ الإصدار',
                'number_label' => 'رقم الشهادة',
                'code_label' => 'رمز المتطوع',
                'authorized_label' => 'التوقيع المعتمد',
                'seal' => 'جمعية عطاء',
            ];
        }

        return [
            'title' => 'Certificate of Volunteering',
            'honor' => 'This certificate is awarded to',
            'body' => 'In recognition of volunteer service with ATAA after completing one hundred certified hours.',
            'hours_label' => $hours . ' volunteer hours',
            'date_label' => 'Date of issue',
            'number_label' => 'Certificate No.',
            'code_label' => 'Volunteer code',
            'authorized_label' => 'Authorized signature',
            'seal' => 'ATAA Association',
        ];
    }

    private static function fnv1a(string $bytes, bool $reversed = false): int
    {
        $hash = 0x811c9dc5;
        $len = strlen($bytes);
        $start = $reversed ? $len - 1 : 0;
        $end = $reversed ? -1 : $len;
        $step = $reversed ? -1 : 1;

        for ($i = $start; $i !== $end; $i += $step) {
            $hash ^= ord($bytes[$i]);
            $hash = ($hash * 0x01000193) & 0xFFFFFFFF;
        }

        return $hash;
    }

    private static function hex16(int $value, int $shift): string
    {
        return strtoupper(str_pad(dechex(($value >> $shift) & 0xFFFF), 4, '0', STR_PAD_LEFT));
    }
}

/*
 |--------------------------------------------------------------------------
 | Drop into VolunteerController::issueVolunteerCertificate
 |--------------------------------------------------------------------------
 |
 | use App\Support\VolunteerCertificateDesigner;
 | use Barryvdh\DomPDF\Facade\Pdf;
 | use SimpleSoftwareIO\QrCode\Facades\QrCode;
 |
 | $isArabic = str_starts_with(strtolower((string) request()->header('Accept-Language', 'ar')), 'ar');
 | $hours = (int) round($totalHours);
 | $name = trim($user->first_name . ' ' . $user->last_name);
 | $code = VolunteerCertificateDesigner::uniqueCode($name, (int) $user->id, $user->phone, $user->email);
 | $serial = VolunteerCertificateDesigner::serialNumber((int) $user->id, $code);
 | $issuedAt = $volunteer->certificate_issued_at ?? now();
 | $payload = VolunteerCertificateDesigner::qrPayload($serial, $code, $name, $hours);
 | $qrPng = QrCode::format('png')->size(140)->margin(0)->generate($payload);
 | $copy = VolunteerCertificateDesigner::copy($isArabic, $hours);
 |
 | $pdf = Pdf::loadView('certificates.volunteer', array_merge($copy, [
 |     'is_arabic' => $isArabic,
 |     'volunteer_name' => $name,
 |     'certificate_number' => $serial,
 |     'unique_code' => $code,
 |     'issued_at_label' => $isArabic
 |         ? VolunteerCertificateDesigner::arabicDate($issuedAt)
 |         : $issuedAt->format('F j, Y'),
 |     'qr_src' => 'data:image/png;base64,' . base64_encode($qrPng),
 |     'logo_src' => public_path('images/logo-green.png'),
 |     'font_path' => storage_path('fonts/Cairo.ttf'),
 | ]))->setPaper('a4', 'landscape');
 |
 | return $pdf->download('ataa-volunteer-certificate.pdf');
 |
 | Keep existing 404 / 403 rules:
 |   no volunteer profile → 404 JSON { success:false, message:"Volunteer profile not found." }
 |   hours < 100 → 403 JSON { success:false, message:"At least 100 volunteer hours are required." }
 */
