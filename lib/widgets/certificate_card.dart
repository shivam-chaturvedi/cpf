import 'package:flutter/material.dart';
import 'package:cpf_portal/services/certificate_generator.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';

class CertificateCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String ngoName;
  final String ngoAddress;
  final String cfoName;
  final String logoPath;
  final String certificateType;
  final String certificateId;
  final DateTime issueDate;
  final DateTime expiryDate;
  final bool isExpired;
  final bool isEnabled;

  const CertificateCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.ngoName,
    required this.ngoAddress,
    required this.cfoName,
    required this.logoPath,
    required this.certificateType,
    required this.certificateId,
    required this.issueDate,
    required this.expiryDate,
    this.isExpired = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Container(
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isExpired ? Colors.red : color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 10 : 14),
                topRight: Radius.circular(isMobile ? 10 : 14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: isMobile ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Certificate details
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('ID:', certificateId, isMobile),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                            'Issue:', _formatDate(issueDate), isMobile),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                            'Expiry:', _formatDate(expiryDate), isMobile),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                          'Status:',
                          isExpired ? 'Expired' : 'Active',
                          isMobile,
                          valueColor: isExpired ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Download button
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isEnabled && !isExpired
                    ? () => _generateCertificate(context)
                    : null,
                icon: Icon(
                  isEnabled ? Icons.download : Icons.lock,
                  size: isMobile ? 16 : 18,
                ),
                label: Text(
                  isEnabled
                      ? (isExpired ? 'Expired' : 'Download')
                      : 'Not Enabled',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isEnabled && !isExpired ? color : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 14,
                    horizontal: isMobile ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: (isEnabled && !isExpired ? color : Colors.grey)
                      .withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _generateCertificate(BuildContext context) async {
    try {
      print('Starting certificate generation for: $title');
      print('NGO: $ngoName, Type: $certificateType');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating certificate...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate certificate based on type
      switch (certificateType) {
        case 'due_diligence':
          await CertificateGenerator.generateDueDiligenceCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        case 'compliance':
          await CertificateGenerator.generateComplianceCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        case 'letterhead':
          await CertificateGenerator.generateLetterheadCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        default:
          throw Exception('Unknown certificate type: $certificateType');
      }

      print('Certificate generated successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error generating certificate: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
