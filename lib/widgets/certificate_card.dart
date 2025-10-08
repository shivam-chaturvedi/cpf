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
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.getResponsiveLayout(
      context: context,
      mobile: _buildMobileCard(context),
      tablet: _buildTabletCard(context),
      desktop: _buildDesktopCard(context),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isExpired ? Colors.red : color,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Certificate details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow('ID:', certificateId, context),
                  _buildDetailRow('Issue:', _formatDate(issueDate), context),
                  _buildDetailRow('Expiry:', _formatDate(expiryDate), context),
                  _buildDetailRow(
                      'Status:', isExpired ? 'Expired' : 'Active', context,
                      valueColor: isExpired ? Colors.red : Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Download button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _generateCertificate(context),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: color.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isExpired ? Colors.red : color,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 20),

            // Certificate details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Certificate ID:', certificateId, context),
                  _buildDetailRow(
                      'Issue Date:', _formatDate(issueDate), context),
                  _buildDetailRow(
                      'Expiry Date:', _formatDate(expiryDate), context),
                  _buildDetailRow(
                      'Status:', isExpired ? 'Expired' : 'Active', context,
                      valueColor: isExpired ? Colors.red : Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Download button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _generateCertificate(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: color.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isExpired ? Colors.red : color,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 24),

            // Certificate details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Certificate ID:', certificateId, context),
                  _buildDetailRow(
                      'Issue Date:', _formatDate(issueDate), context),
                  _buildDetailRow(
                      'Expiry Date:', _formatDate(expiryDate), context),
                  _buildDetailRow(
                      'Status:', isExpired ? 'Expired' : 'Active', context,
                      valueColor: isExpired ? Colors.red : Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Download button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _generateCertificate(context),
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  shadowColor: color.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
          ),
        ],
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating certificate...'),
            ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title downloaded successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error generating certificate: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating certificate: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

}
