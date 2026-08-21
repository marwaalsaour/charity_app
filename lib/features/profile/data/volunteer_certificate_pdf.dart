import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/file_share_helper.dart';

class VolunteerCertificatePdf {
  VolunteerCertificatePdf._();

  static const requiredHours = 100;
  static const fileName = 'ataa-volunteer-certificate.pdf';

  static const _orgAr = 'جمعية عطاء الخيرية';
  static const _orgEn = 'ATAA Charity Association';
  static const _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Stable per-user code used when the official server PDF is unavailable.
  static String uniqueCode({
    required String volunteerName,
    int? userId,
    String? phone,
    String? email,
  }) {
    final seed = [
      'ataa.volunteer.certificate.v1',
      '${userId ?? 0}',
      volunteerName.trim().toLowerCase(),
      (phone ?? '').replaceAll(RegExp(r'\D'), ''),
      (email ?? '').trim().toLowerCase(),
    ].join('|');
    final bytes = utf8.encode(seed);
    final a = _fnv1a(bytes);
    final b = _fnv1a(bytes, reversed: true);
    String hex(int value, int shift) =>
        ((value >> shift) & 0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase();
    return 'ATAA-${hex(a, 16)}-${hex(a, 0)}-${hex(b, 16)}';
  }

  static String serialNumber({int? userId, required String uniqueCode}) {
    if (userId != null && userId > 0) {
      return 'VOL-${userId.toString().padLeft(6, '0')}';
    }
    final compact = uniqueCode.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final tail = compact.length >= 10 ? compact.substring(4, 10) : compact;
    return 'VOL-$tail';
  }

  static int _fnv1a(List<int> bytes, {bool reversed = false}) {
    var hash = 0x811c9dc5;
    final start = reversed ? bytes.length - 1 : 0;
    final end = reversed ? -1 : bytes.length;
    final step = reversed ? -1 : 1;
    for (var i = start; i != end; i += step) {
      hash ^= bytes[i];
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static String _formatDate(DateTime issuedAt, bool isArabic) {
    if (isArabic) {
      return '${issuedAt.day} ${_arMonths[issuedAt.month - 1]} ${issuedAt.year}';
    }
    return DateFormat.yMMMMd('en').format(issuedAt);
  }

  static pw.Widget _ltr(pw.Widget child) {
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: child,
    );
  }

  static Future<pw.Font> _loadFont() async {
    final data = await rootBundle.load('assets/fonts/Cairo.ttf');
    return pw.Font.ttf(data);
  }

  static Future<Uint8List> build({
    required String volunteerName,
    required int hours,
    required DateTime issuedAt,
    required bool isArabic,
    int? userId,
    String? phone,
    String? email,
  }) async {
    final font = await _loadFont();
    final code = uniqueCode(
      volunteerName: volunteerName,
      userId: userId,
      phone: phone,
      email: email,
    );
    final serial = serialNumber(userId: userId, uniqueCode: code);
    final date = _formatDate(issuedAt, isArabic);

    final title = 'volunteer_certificate_pdf_title'.tr();
    final honor = 'volunteer_certificate_pdf_honor'.tr();
    final body = 'volunteer_certificate_pdf_body'.tr();
    final hoursLabel = 'volunteer_certificate_pdf_hours'.tr(
      namedArgs: {'count': '$hours'},
    );
    final dateLabel = 'volunteer_certificate_pdf_date_label'.tr();
    final numberLabel = 'volunteer_certificate_pdf_number'.tr();
    final codeLabel = 'volunteer_certificate_pdf_unique_code'.tr();
    final authorized = 'volunteer_certificate_pdf_authorized'.tr();
    final seal = 'volunteer_certificate_pdf_seal'.tr();

    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/image/logo-green.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    const primary = PdfColor.fromInt(0xFF1A5C52);
    const primaryDark = PdfColor.fromInt(0xFF0F3D35);
    const gold = PdfColor.fromInt(0xFFC9A227);
    const cream = PdfColor.fromInt(0xFFFBF7EE);
    const ivory = PdfColor.fromInt(0xFFFFFDF8);
    final pageFormat = PdfPageFormat.a4.landscape;
    final width = pageFormat.width - 32;
    final height = pageFormat.height - 32;

    pw.TextStyle style(
      double size, {
      PdfColor color = primaryDark,
      double? spacing,
    }) {
      return pw.TextStyle(
        font: font,
        fontSize: size,
        color: color,
        letterSpacing: spacing,
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(16),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Directionality(
            textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.SizedBox(
              width: width,
              height: height,
              child: pw.Stack(
                fit: pw.StackFit.expand,
                children: [
                  pw.Container(
                    color: cream,
                    padding: const pw.EdgeInsets.all(9),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: gold, width: 3.8),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: ivory,
                          border: pw.Border.all(color: primaryDark, width: 1.2),
                        ),
                        padding: const pw.EdgeInsets.fromLTRB(36, 18, 36, 16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logo != null)
                              pw.SizedBox(
                                width: 46,
                                height: 46,
                                child: pw.Image(logo, fit: pw.BoxFit.contain),
                              ),
                            pw.SizedBox(height: 6),
                            pw.Text(_orgAr, style: style(14, color: primary)),
                            pw.SizedBox(height: 2),
                            _ltr(
                              pw.Text(
                                _orgEn,
                                style: style(
                                  9,
                                  color: PdfColors.grey700,
                                  spacing: 0.8,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(width: 64, height: 1, color: gold),
                                pw.SizedBox(width: 8),
                                pw.Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const pw.BoxDecoration(
                                    color: gold,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Container(width: 64, height: 1, color: gold),
                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(title, style: style(30, color: gold)),
                            pw.SizedBox(height: 10),
                            pw.Text(honor, style: style(12, color: primary)),
                            pw.SizedBox(height: 8),
                            pw.Text(volunteerName, style: style(24)),
                            pw.SizedBox(height: 6),
                            pw.Container(width: 180, height: 1.2, color: gold),
                            pw.SizedBox(height: 10),
                            pw.SizedBox(
                              width: 520,
                              child: pw.Text(
                                body,
                                textAlign: pw.TextAlign.center,
                                style: style(11.5, color: PdfColors.grey800),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0x22C9A227),
                                borderRadius: pw.BorderRadius.circular(16),
                                border: pw.Border.all(color: gold),
                              ),
                              child: pw.Text(
                                hoursLabel,
                                style: style(12, color: primaryDark),
                              ),
                            ),
                            pw.Spacer(),
                            _footer(
                              font: font,
                              isArabic: isArabic,
                              primary: primary,
                              primaryDark: primaryDark,
                              gold: gold,
                              dateLabel: dateLabel,
                              date: date,
                              numberLabel: numberLabel,
                              serial: serial,
                              codeLabel: codeLabel,
                              code: code,
                              authorized: authorized,
                              seal: seal,
                              qrPayload:
                                  'ATAA|$serial|$code|$volunteerName|$hours',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._cornerOrnaments(gold),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _cornerOrnaments(PdfColor gold) {
    pw.Widget corner({
      required double? top,
      required double? bottom,
      required double? left,
      required double? right,
    }) {
      return pw.Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: pw.Container(
          width: 22,
          height: 22,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: top != null
                  ? pw.BorderSide(color: gold, width: 1.6)
                  : pw.BorderSide.none,
              bottom: bottom != null
                  ? pw.BorderSide(color: gold, width: 1.6)
                  : pw.BorderSide.none,
              left: left != null
                  ? pw.BorderSide(color: gold, width: 1.6)
                  : pw.BorderSide.none,
              right: right != null
                  ? pw.BorderSide(color: gold, width: 1.6)
                  : pw.BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: 18, bottom: null, left: 18, right: null),
      corner(top: 18, bottom: null, left: null, right: 18),
      corner(top: null, bottom: 18, left: 18, right: null),
      corner(top: null, bottom: 18, left: null, right: 18),
    ];
  }

  static pw.Widget _footer({
    required pw.Font font,
    required bool isArabic,
    required PdfColor primary,
    required PdfColor primaryDark,
    required PdfColor gold,
    required String dateLabel,
    required String date,
    required String numberLabel,
    required String serial,
    required String codeLabel,
    required String code,
    required String authorized,
    required String seal,
    required String qrPayload,
  }) {
    final dir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    pw.TextStyle labelStyle() => pw.TextStyle(
          font: font,
          fontSize: 8,
          color: PdfColors.grey700,
        );
    pw.TextStyle valueStyle() => pw.TextStyle(
          font: font,
          fontSize: 10,
          color: primaryDark,
        );

    pw.Widget localized(String text, pw.TextStyle style) {
      return pw.Directionality(
        textDirection: dir,
        child: pw.Text(text, style: style),
      );
    }

    pw.Widget block({
      required String label,
      required pw.Widget value,
      pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start,
    }) {
      return pw.Column(
        crossAxisAlignment: align,
        children: [
          localized(label, labelStyle()),
          pw.SizedBox(height: 4),
          value,
        ],
      );
    }

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: block(
              label: dateLabel,
              value: localized(date, valueStyle()),
            ),
          ),
          pw.Expanded(
            child: block(
              label: numberLabel,
              value: _ltr(pw.Text(serial, style: valueStyle())),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(8, 6, 10, 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: gold, width: 0.9),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload,
                  width: 44,
                  height: 44,
                  color: primaryDark,
                  drawText: false,
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    localized(codeLabel, labelStyle()),
                    pw.SizedBox(height: 3),
                    _ltr(
                      pw.Text(
                        code,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 9,
                          color: primaryDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: block(
              label: authorized,
              align: pw.CrossAxisAlignment.end,
              value: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(width: 96, height: 1.1, color: primary),
                  pw.SizedBox(height: 4),
                  localized(seal, valueStyle()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> saveToTempFile({
    required String volunteerName,
    required int hours,
    required bool isArabic,
    int? userId,
    String? phone,
    String? email,
  }) async {
    final bytes = await build(
      volunteerName: volunteerName,
      hours: hours,
      issuedAt: DateTime.now(),
      isArabic: isArabic,
      userId: userId,
      phone: phone,
      email: email,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> share({
    required String volunteerName,
    required int hours,
    required bool isArabic,
    int? userId,
    String? phone,
    String? email,
  }) async {
    final file = await saveToTempFile(
      volunteerName: volunteerName,
      hours: hours,
      isArabic: isArabic,
      userId: userId,
      phone: phone,
      email: email,
    );
    await FileShareHelper.shareFile(
      path: file.path,
      filename: fileName,
    );
  }
}
