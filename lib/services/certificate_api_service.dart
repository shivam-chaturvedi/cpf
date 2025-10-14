import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class CertificateApiService {
  static const String _baseUrl = 'https://certificate-tool-kappa.vercel.app';

  /// Generate Due Diligence Certificate
  static Future<void> generateDueDiligenceCertificate({
    required String ngoName,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateCertificate(
      endpoint: '/generate/due_diligence',
      ngoName: ngoName,
      issueDate: issueDate,
      expiryDate: expiryDate,
      fileName: 'certificate_due_diligence.docx',
      context: context,
    );
  }

  /// Generate Compliance Certificate
  static Future<void> generateComplianceCertificate({
    required String ngoName,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateCertificate(
      endpoint: '/generate/compliance',
      ngoName: ngoName,
      issueDate: issueDate,
      expiryDate: expiryDate,
      fileName: 'certificate_compliance.docx',
      context: context,
    );
  }

  /// Generate Letterhead Certificate
  static Future<void> generateLetterheadCertificate({
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String checkType,
    required DateTime issueDate,
    required DateTime expiryDate,
    required BuildContext context,
  }) async {
    await _generateLetterheadCertificate(
      ngoName: ngoName,
      ngoAddress: ngoAddress,
      cfoName: cfoName,
      checkType: checkType,
      issueDate: issueDate,
      expiryDate: expiryDate,
      fileName: 'certificate_letterhead.docx',
      context: context,
    );
  }

  /// Internal method to generate compliance and due diligence certificates
  static Future<void> _generateCertificate({
    required String endpoint,
    required String ngoName,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      print('========================================');
      print('CALLING CERTIFICATE API');
      print('Endpoint: $_baseUrl$endpoint');
      print('NGO Name: $ngoName');
      print('Issue Date: ${_formatDate(issueDate)}');
      print('Expiry Date: ${_formatDate(expiryDate)}');
      print('========================================');

      // Prepare request body
      final Map<String, String> requestBody = {
        'ngo_name': ngoName,
        'issue_date': _formatDate(issueDate),
        'exp_date': _formatDate(expiryDate),
      };

      print('Request body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept':
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Download the file
        final bytes = response.bodyBytes;
        print('Received ${bytes.length} bytes');
        await _downloadFile(bytes, fileName, context);
      } else {
        // Try to parse error message
        String errorMessage = 'Failed to generate certificate';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in _generateCertificate: $e');
      rethrow;
    }
  }

  /// Internal method to generate letterhead certificate
  static Future<void> _generateLetterheadCertificate({
    required String ngoName,
    required String ngoAddress,
    required String cfoName,
    required String checkType,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      print('========================================');
      print('CALLING LETTERHEAD CERTIFICATE API');
      print('Endpoint: $_baseUrl/generate/letterhead');
      print('NGO Name: $ngoName');
      print('NGO Address: $ngoAddress');
      print('CFO Name: $cfoName');
      print('Check Type: $checkType');
      print('Issue Date: ${_formatDate(issueDate)}');
      print('Expiry Date: ${_formatDate(expiryDate)}');
      print('========================================');

      // Prepare request body
      final Map<String, String> requestBody = {
        'cfo_name': cfoName,
        'ngo_name': ngoName,
        'ngo_address': ngoAddress,
        'check_type': checkType,
        'issue_date': _formatDate(issueDate),
        'exp_date': _formatDate(expiryDate),
      };

      print('Request body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/generate/letterhead'),
        headers: {
          'Content-Type': 'application/json',
          'Accept':
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Download the file
        final bytes = response.bodyBytes;
        print('Received ${bytes.length} bytes');
        await _downloadFile(bytes, fileName, context);
      } else {
        // Try to parse error message
        String errorMessage = 'Failed to generate certificate';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in _generateLetterheadCertificate: $e');
      rethrow;
    }
  }

  /// Download the file (handles web and mobile/desktop differently)
  static Future<void> _downloadFile(
    Uint8List bytes,
    String fileName,
    BuildContext context,
  ) async {
    try {
      if (kIsWeb) {
        // For web, trigger direct download
        final blob = html.Blob([
          bytes
        ], 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        print('File downloaded successfully: $fileName');
      } else {
        // For mobile/desktop platforms
        // Note: You might need to implement this using path_provider and share_plus
        // or open_file packages for mobile platforms
        throw UnimplementedError(
            'File download for mobile/desktop is not yet implemented. Please use the web version.');
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  /// Format date as "DD Mon YYYY" (e.g., "14 Oct 2025")
  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
