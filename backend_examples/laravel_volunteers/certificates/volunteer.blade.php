<!DOCTYPE html>
<html lang="{{ $is_arabic ? 'ar' : 'en' }}" dir="{{ $is_arabic ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="utf-8">
    <title>Volunteer Certificate</title>
    <style>
        @page { margin: 16px; size: A4 landscape; }

        @font-face {
            font-family: 'Cairo';
            font-style: normal;
            font-weight: 400;
            src: url('{{ $font_path }}') format('truetype');
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            color: #0F3D35;
            font-family: 'Cairo', DejaVu Sans, sans-serif;
        }

        .page {
            position: relative;
            width: 100%;
            height: 100%;
            background: #FBF7EE;
            padding: 9px;
        }

        .gold-frame {
            border: 3.8px solid #C9A227;
            padding: 6px;
            height: 100%;
        }

        .inner {
            position: relative;
            border: 1.2px solid #0F3D35;
            background: #FFFDF8;
            height: 100%;
            padding: 18px 36px 16px 36px;
            text-align: center;
        }

        .corner {
            position: absolute;
            width: 22px;
            height: 22px;
        }
        .tl { top: 18px; left: 18px; border-top: 1.6px solid #C9A227; border-left: 1.6px solid #C9A227; }
        .tr { top: 18px; right: 18px; border-top: 1.6px solid #C9A227; border-right: 1.6px solid #C9A227; }
        .bl { bottom: 18px; left: 18px; border-bottom: 1.6px solid #C9A227; border-left: 1.6px solid #C9A227; }
        .br { bottom: 18px; right: 18px; border-bottom: 1.6px solid #C9A227; border-right: 1.6px solid #C9A227; }

        .logo { width: 46px; height: 46px; margin: 0 auto 6px auto; }
        .logo img { width: 46px; height: 46px; }

        .org-ar { color: #1A5C52; font-size: 14px; margin: 0; }
        .org-en {
            color: #616161;
            font-size: 9px;
            letter-spacing: 0.8px;
            margin: 2px 0 10px 0;
            direction: ltr;
            unicode-bidi: embed;
        }

        .divider { margin: 0 auto 10px auto; }
        .divider td { vertical-align: middle; }
        .gold-line { width: 64px; height: 1px; background: #C9A227; }
        .gold-dot {
            width: 7px;
            height: 7px;
            background: #C9A227;
            border-radius: 50%;
        }

        .title { color: #C9A227; font-size: 30px; margin: 10px 0; }
        .honor { color: #1A5C52; font-size: 12px; margin: 0 0 8px 0; }
        .name { color: #0F3D35; font-size: 24px; margin: 0 0 6px 0; }
        .name-line {
            width: 180px;
            height: 1.2px;
            background: #C9A227;
            margin: 0 auto 10px auto;
        }
        .body {
            width: 520px;
            margin: 0 auto 12px auto;
            color: #424242;
            font-size: 11.5px;
            line-height: 1.6;
        }

        .hours {
            display: inline-block;
            padding: 6px 16px;
            color: #0F3D35;
            font-size: 12px;
            background: #F7EDD0;
            border: 1px solid #C9A227;
            border-radius: 16px;
        }

        .footer {
            width: 100%;
            margin-top: 28px;
            border-collapse: collapse;
        }
        .footer td {
            vertical-align: bottom;
            width: 25%;
            padding: 0 6px;
        }
        .label { color: #616161; font-size: 8px; margin: 0 0 4px 0; }
        .value { color: #0F3D35; font-size: 10px; margin: 0; }
        .code {
            color: #0F3D35;
            font-size: 9px;
            letter-spacing: 0.4px;
            direction: ltr;
            unicode-bidi: embed;
            margin: 0;
        }
        .ltr { direction: ltr; unicode-bidi: embed; }

        .qr-box {
            border: 0.9px solid #C9A227;
            border-radius: 6px;
            padding: 6px 10px 6px 8px;
            display: inline-block;
        }
        .qr-box table { border-collapse: collapse; }
        .qr-box td { vertical-align: middle; padding: 0; }
        .qr { width: 44px; height: 44px; }
        .sig-line {
            width: 96px;
            height: 1.1px;
            background: #1A5C52;
            margin: {{ $is_arabic ? '0 auto 4px 0' : '0 0 4px auto' }};
        }
        .align-end { text-align: {{ $is_arabic ? 'left' : 'right' }}; }
        .align-start { text-align: {{ $is_arabic ? 'right' : 'left' }}; }
    </style>
</head>
<body>
<div class="page">
    <div class="gold-frame">
        <div class="inner">
            <div class="corner tl"></div>
            <div class="corner tr"></div>
            <div class="corner bl"></div>
            <div class="corner br"></div>

            @if (!empty($logo_src))
                <div class="logo"><img src="{{ $logo_src }}" alt="ATAA"></div>
            @endif

            <p class="org-ar">جمعية عطاء الخيرية</p>
            <p class="org-en">ATAA Charity Association</p>

            <table class="divider" cellpadding="0" cellspacing="0">
                <tr>
                    <td><div class="gold-line"></div></td>
                    <td style="width:16px; text-align:center;"><div class="gold-dot" style="margin:0 auto;"></div></td>
                    <td><div class="gold-line"></div></td>
                </tr>
            </table>

            <p class="title">{{ $title }}</p>
            <p class="honor">{{ $honor }}</p>
            <p class="name">{{ $volunteer_name }}</p>
            <div class="name-line"></div>
            <p class="body">{{ $body }}</p>
            <div class="hours">{{ $hours_label }}</div>

            <table class="footer">
                <tr>
                    <td class="align-start">
                        <p class="label">{{ $date_label }}</p>
                        <p class="value">{{ $issued_at_label }}</p>
                    </td>
                    <td class="align-start">
                        <p class="label">{{ $number_label }}</p>
                        <p class="value ltr">{{ $certificate_number }}</p>
                    </td>
                    <td style="text-align:center;">
                        <div class="qr-box">
                            <table>
                                <tr>
                                    <td><img class="qr" src="{{ $qr_src }}" alt="QR"></td>
                                    <td style="padding-left:8px; padding-right:8px; text-align:left;">
                                        <p class="label">{{ $code_label }}</p>
                                        <p class="code">{{ $unique_code }}</p>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </td>
                    <td class="align-end">
                        <p class="label">{{ $authorized_label }}</p>
                        <div class="sig-line"></div>
                        <p class="value">{{ $seal }}</p>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</div>
</body>
</html>
