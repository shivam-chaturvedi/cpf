import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class CertificateGenerator {
  // Template paths
  static const String dueDiligenceTemplate =
      'assets/docs/2 CERT_Diligence_NGO_6Feb25 (1).docx';
  static const String complianceTemplate =
      'assets/docs/1 CERT_Compliance_NGO_6Feb25.docx';
  static const String letterheadTemplate =
      'assets/docs/CPF Letterhead - Copy (2).docx';

  static Future<void> generateDueDiligenceCertificate({
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String logoPath,
    required String certificateId,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateCertificateFromTemplate(
      templateType: 'due_diligence',
      ngoName: ngoName,
      ngoAddress: ngoAddress,
      cfoName: cfoName,
      logoPath: logoPath,
      certificateId: certificateId,
      issueDate: issueDate,
      expiryDate: expiryDate,
      context: context,
    );
  }

  static Future<void> generateComplianceCertificate({
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String logoPath,
    required String certificateId,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateCertificateFromTemplate(
      templateType: 'compliance',
      ngoName: ngoName,
      ngoAddress: ngoAddress,
      cfoName: cfoName,
      logoPath: logoPath,
      certificateId: certificateId,
      issueDate: issueDate,
      expiryDate: expiryDate,
      context: context,
    );
  }

  static Future<void> generateLetterheadCertificate({
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String logoPath,
    required String certificateId,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateCertificateFromTemplate(
      templateType: 'letterhead',
      ngoName: ngoName,
      ngoAddress: ngoAddress,
      cfoName: cfoName,
      logoPath: logoPath,
      certificateId: certificateId,
      issueDate: issueDate,
      expiryDate: expiryDate,
      context: context,
    );
  }

  static Future<void> _generateCertificateFromTemplate({
    required String templateType,
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String logoPath,
    required String certificateId,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    print('========================================');
    print('GENERATING CERTIFICATE');
    print('Type: $templateType');
    print('NGO Name: $ngoName');
    print('NGO Address: $ngoAddress');
    print('CFO Name: $cfoName');
    print('Logo Path: $logoPath');
    print('Certificate ID: $certificateId');
    print('Issue Date: ${_formatDate(issueDate)}');
    print('Expiry Date: ${_formatDate(expiryDate)}');
    print('========================================');

    final pdf = pw.Document();

    // Load logo if available
    pw.ImageProvider? logoProvider;
    if (logoPath.isNotEmpty) {
      try {
        print('Attempting to load logo from: $logoPath');
        final logoData = await rootBundle.load(logoPath);
        logoProvider = pw.MemoryImage(logoData.buffer.asUint8List());
        print('Logo loaded successfully');
      } catch (e) {
        print('Error loading logo: $e');
        print('Using default CPF logo');
        try {
          final defaultLogo =
              await rootBundle.load('assets/images/CPF_Logo.jpg');
          logoProvider = pw.MemoryImage(defaultLogo.buffer.asUint8List());
        } catch (e2) {
          print('Error loading default logo: $e2');
        }
      }
    }

    // Generate certificate based on template type
    switch (templateType) {
      case 'due_diligence':
        _buildDueDiligenceCertificate(pdf, ngoName, ngoAddress, cfoName,
            logoProvider, certificateId, issueDate, expiryDate);
        break;
      case 'compliance':
        _buildComplianceCertificate(pdf, ngoName, ngoAddress, cfoName,
            logoProvider, certificateId, issueDate, expiryDate);
        break;
      case 'letterhead':
        _buildLetterheadCertificate(pdf, ngoName, ngoAddress, cfoName,
            logoProvider, certificateId, issueDate, expiryDate);
        break;
    }

    // Save and share the PDF
    final fileName =
        '${templateType.toUpperCase()}_Certificate_$certificateId.pdf';
    await _saveAndSharePDF(pdf, fileName, context);
  }

  static void _buildDueDiligenceCertificate(
    pw.Document pdf,
    String ngoName,
    String ngoAddress,
    String cfoName,
    pw.ImageProvider? logoProvider,
    String certificateId,
    DateTime issueDate,
    DateTime expiryDate,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with logo
              if (logoProvider != null)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Image(logoProvider, width: 100, height: 100),
                ),

              pw.SizedBox(height: 20),

              // Certificate Title
              pw.Text(
                'CERTIFICATE OF DUE DILIGENCE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 10),

              // Subtitle
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 20),

              // NGO Name
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ngoName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      ngoAddress,
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Chief Functionary: $cfoName',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Body
              pw.Text(
                'has successfully completed the due diligence process and meets all the required standards for transparency, accountability, and compliance as set forth by the Collaborative Philanthropy Foundation (CPF).',
                style: pw.TextStyle(fontSize: 14, height: 1.5),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 30),

              // Certificate Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Certificate ID:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(certificateId),
                      pw.SizedBox(height: 10),
                      pw.Text('Issue Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(issueDate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Valid Until:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(expiryDate)),
                      pw.SizedBox(height: 10),
                      pw.Text('Status:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('ACTIVE',
                          style: pw.TextStyle(color: PdfColors.green)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Collaborative Philanthropy Foundation',
                style: pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Date: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  static void _buildComplianceCertificate(
    pw.Document pdf,
    String ngoName,
    String ngoAddress,
    String cfoName,
    pw.ImageProvider? logoProvider,
    String certificateId,
    DateTime issueDate,
    DateTime expiryDate,
  ) {
    print('Building Compliance Certificate with:');
    print('NGO Name: $ngoName');
    print('Address: $ngoAddress');
    print('CFO: $cfoName');
    print('Certificate ID: $certificateId');
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with logo
              if (logoProvider != null)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Image(logoProvider, width: 100, height: 100),
                ),

              pw.SizedBox(height: 20),

              // Certificate Title
              pw.Text(
                'CERTIFICATE OF COMPLIANCE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 10),

              // Subtitle
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 20),

              // NGO Name
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ngoName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      ngoAddress,
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Chief Functionary: $cfoName',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Body
              pw.Text(
                'has demonstrated full compliance with all regulatory requirements, operational guidelines, and standards established by the Collaborative Philanthropy Foundation (CPF).',
                style: pw.TextStyle(fontSize: 14, height: 1.5),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 30),

              // Compliance Details
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Compliance Areas Verified:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Bullet(
                        text: 'Financial Transparency and Accountability'),
                    pw.Bullet(text: 'Governance and Management Structure'),
                    pw.Bullet(text: 'Program Implementation and Impact'),
                    pw.Bullet(text: 'Legal and Regulatory Compliance'),
                    pw.Bullet(text: 'Documentation and Reporting Standards'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Certificate ID:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(certificateId),
                      pw.SizedBox(height: 10),
                      pw.Text('Issue Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(issueDate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Valid Until:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(expiryDate)),
                      pw.SizedBox(height: 10),
                      pw.Text('Status:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('COMPLIANT',
                          style: pw.TextStyle(color: PdfColors.green)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Collaborative Philanthropy Foundation',
                style: pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Date: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  static void _buildLetterheadCertificate(
    pw.Document pdf,
    String ngoName,
    String ngoAddress,
    String cfoName,
    pw.ImageProvider? logoProvider,
    String certificateId,
    DateTime issueDate,
    DateTime expiryDate,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with logo
              if (logoProvider != null)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Image(logoProvider, width: 100, height: 100),
                ),

              pw.SizedBox(height: 20),

              // Certificate Title
              pw.Text(
                'OFFICIAL LETTERHEAD AUTHORIZATION',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 10),

              // Subtitle
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 20),

              // NGO Name
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ngoName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      ngoAddress,
                      style: pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Chief Functionary: $cfoName',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Body
              pw.Text(
                'is hereby authorized to use the official letterhead of the Collaborative Philanthropy Foundation (CPF) for all official correspondence, documentation, and communication purposes.',
                style: pw.TextStyle(fontSize: 14, height: 1.5),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 30),

              // Authorization Details
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Authorization Details:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Bullet(text: 'Official correspondence and letters'),
                    pw.Bullet(text: 'Project proposals and reports'),
                    pw.Bullet(text: 'Financial documentation'),
                    pw.Bullet(text: 'Partnership agreements'),
                    pw.Bullet(text: 'Public communications and announcements'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Certificate ID:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(certificateId),
                      pw.SizedBox(height: 10),
                      pw.Text('Issue Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(issueDate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Valid Until:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatDate(expiryDate)),
                      pw.SizedBox(height: 10),
                      pw.Text('Status:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('AUTHORIZED',
                          style: pw.TextStyle(color: PdfColors.blue)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Collaborative Philanthropy Foundation',
                style: pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Date: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _saveAndSharePDF(
      pw.Document pdf, String fileName, BuildContext context) async {
    try {
      if (kIsWeb) {
        // For web, trigger direct download
        final Uint8List pdfBytes = await pdf.save();

        // Create blob and trigger download
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile/desktop, save to file and share
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');

        // Save the PDF
        await file.writeAsBytes(await pdf.save());

        // Share the PDF
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Certificate: $fileName',
          subject: 'CPF Certificate',
        );
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate downloaded: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
