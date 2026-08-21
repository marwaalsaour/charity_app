import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/file_share_helper.dart';

class VolunteerCertificatePdf {
  VolunteerCertificatePdf._();

  static const requiredHours = 100;

  static Future<pw.Font> _loadFont() async {
    final data = await rootBundle.load('assets/fonts/Cairo.ttf');
    return pw.Font.ttf(data);
  }

  static Future<Uint8List> build({
    required String volunteerName,
    required int hours,
    required DateTime issuedAt,
    required bool isArabic,
  }) async {
    final font = await _loadFont();

    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/image/logo-green.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final date = DateFormat.yMMMMd(isArabic ? 'ar' : 'en').format(issuedAt);
    final primary = PdfColor.fromInt(0xFF1A5C52);
    final gold = PdfColor.fromInt(0xFFC8960C);
    final cream = PdfColor.fromInt(0xFFF7F6F2);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Directionality(
            textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.Container(
              color: cream,
              padding: const pw.EdgeInsets.all(18),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: gold, width: 5),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primary, width: 1.6),
                  ),
                  padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logo != null)
                        pw.Container(
                          width: 58,
                          height: 58,
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'volunteer_certificate_pdf_kicker'.tr(),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 13,
                          color: primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'volunteer_certificate_pdf_title'.tr(),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 34,
                          color: gold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(width: 120, height: 2, color: gold),
                      pw.SizedBox(height: 22),
                      pw.Text(
                        'volunteer_certificate_pdf_honor'.tr(),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 14,
                          color: primary,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        volunteerName,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 26,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                      pw.SizedBox(
                        width: 520,
                        child: pw.Text(
                          'volunteer_certificate_pdf_body'.tr(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 13,
                            lineSpacing: 4,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 18),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x33F2C055),
                          borderRadius: pw.BorderRadius.circular(20),
                          border: pw.Border.all(color: gold),
                        ),
                        child: pw.Text(
                          'volunteer_certificate_pdf_hours'.tr(
                            namedArgs: {'count': '$hours'},
                          ),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 13,
                            color: primary,
                          ),
                        ),
                      ),
                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'volunteer_certificate_pdf_date'.tr(
                              namedArgs: {'date': date},
                            ),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 11,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 110,
                                height: 1.2,
                                color: primary,
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'volunteer_certificate_pdf_seal'.tr(),
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 11,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> share({
    required String volunteerName,
    required int hours,
    required bool isArabic,
  }) async {
    final bytes = await build(
      volunteerName: volunteerName,
      hours: hours,
      issuedAt: DateTime.now(),
      isArabic: isArabic,
    );
    final filename = isArabic
        ? 'شهادة_تطوع_عطاء.pdf'
        : 'ataa_volunteer_certificate.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await FileShareHelper.shareFile(
      path: file.path,
      filename: filename,
    );
  }
}
