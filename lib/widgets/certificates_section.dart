import 'package:flutter/material.dart';
import 'package:cpf_portal/widgets/certificate_card.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';

class CertificatesSection extends StatelessWidget {
  final String ngoName;
  final String ngoAddress;
  final String cfoName;
  final String logoPath;
  final Map<String, dynamic> certificateStatuses;

  const CertificatesSection({
    super.key,
    required this.ngoName,
    required this.ngoAddress,
    required this.cfoName,
    required this.logoPath,
    required this.certificateStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppTheme.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificates & Compliance',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    Text(
                      'Download your official certificates and compliance documents',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Certificates Grid
          ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: Column(
              children: _buildCertificates(context)
                  .map((cert) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: cert,
                      ))
                  .toList(),
            ),
            tablet: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _buildCertificates(context),
            ),
            desktop: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.75,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: _buildCertificates(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCertificates(BuildContext context) {
    final now = DateTime.now();
    final List<Widget> certificates = [];

    print('========================================');
    print('CERTIFICATE STATUSES FROM FIREBASE:');
    print(
        'Due Diligence Enabled: ${certificateStatuses['dueDiligenceCertificateEnabled']}');
    print(
        'Compliance Enabled: ${certificateStatuses['complianceCertificateEnabled']}');
    print(
        'Letterhead Enabled: ${certificateStatuses['letterheadCertificateEnabled']}');
    print('========================================');

    // Check if Due Diligence Certificate is enabled
    final dueDiligenceEnabled =
        certificateStatuses['dueDiligenceCertificateEnabled'] ?? false;
    final dueDiligenceData =
        certificateStatuses['dueDiligenceCertificateEnabledData'];

    if (dueDiligenceEnabled && dueDiligenceData != null) {
      certificates.add(
        CertificateCard(
          title: 'Due Diligence Certificate',
          description:
              'Official certificate confirming completion of due diligence process and compliance with transparency standards.',
          icon: Icons.assignment_turned_in,
          color: AppTheme.primaryRed,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'due_diligence',
          certificateId: dueDiligenceData['certificateId'] ??
              'DD-${now.millisecondsSinceEpoch}',
          issueDate: dueDiligenceData['issueDate'] != null
              ? DateTime.parse(dueDiligenceData['issueDate'])
              : now.subtract(const Duration(days: 30)),
          expiryDate: dueDiligenceData['expiryDate'] != null
              ? DateTime.parse(dueDiligenceData['expiryDate'])
              : now.add(const Duration(days: 335)),
          isEnabled: true,
        ),
      );
    } else {
      // Show disabled card
      certificates.add(
        CertificateCard(
          title: 'Due Diligence Certificate',
          description:
              'This certificate has not been enabled by the admin yet.',
          icon: Icons.lock,
          color: Colors.grey,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'due_diligence',
          certificateId: 'N/A',
          issueDate: now,
          expiryDate: now,
          isEnabled: false,
        ),
      );
    }

    // Check if Compliance Certificate is enabled
    final complianceEnabled =
        certificateStatuses['complianceCertificateEnabled'] ?? false;
    final complianceData =
        certificateStatuses['complianceCertificateEnabledData'];

    if (complianceEnabled && complianceData != null) {
      certificates.add(
        CertificateCard(
          title: 'Compliance Certificate',
          description:
              'Certificate verifying compliance with all regulatory requirements and operational guidelines.',
          icon: Icons.verified,
          color: AppTheme.primaryGreen,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'compliance',
          certificateId: complianceData['certificateId'] ??
              'COMP-${now.millisecondsSinceEpoch}',
          issueDate: complianceData['issueDate'] != null
              ? DateTime.parse(complianceData['issueDate'])
              : now.subtract(const Duration(days: 30)),
          expiryDate: complianceData['expiryDate'] != null
              ? DateTime.parse(complianceData['expiryDate'])
              : now.add(const Duration(days: 335)),
          isEnabled: true,
        ),
      );
    } else {
      certificates.add(
        CertificateCard(
          title: 'Compliance Certificate',
          description:
              'This certificate has not been enabled by the admin yet.',
          icon: Icons.lock,
          color: Colors.grey,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'compliance',
          certificateId: 'N/A',
          issueDate: now,
          expiryDate: now,
          isEnabled: false,
        ),
      );
    }

    // Check if Letterhead Certificate is enabled
    final letterheadEnabled =
        certificateStatuses['letterheadCertificateEnabled'] ?? false;
    final letterheadData =
        certificateStatuses['letterheadCertificateEnabledData'];

    if (letterheadEnabled && letterheadData != null) {
      certificates.add(
        CertificateCard(
          title: 'Letterhead Certificate',
          description:
              'Official letterhead certificate for authorized correspondence and documentation purposes.',
          icon: Icons.description,
          color: Colors.blue,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'letterhead',
          certificateId: letterheadData['certificateId'] ??
              'LH-${now.millisecondsSinceEpoch}',
          issueDate: letterheadData['issueDate'] != null
              ? DateTime.parse(letterheadData['issueDate'])
              : now.subtract(const Duration(days: 30)),
          expiryDate: letterheadData['expiryDate'] != null
              ? DateTime.parse(letterheadData['expiryDate'])
              : now.add(const Duration(days: 335)),
          isEnabled: true,
        ),
      );
    } else {
      certificates.add(
        CertificateCard(
          title: 'Letterhead Certificate',
          description:
              'This certificate has not been enabled by the admin yet.',
          icon: Icons.lock,
          color: Colors.grey,
          ngoName: ngoName,
          ngoAddress: ngoAddress,
          cfoName: cfoName,
          logoPath: logoPath,
          certificateType: 'letterhead',
          certificateId: 'N/A',
          issueDate: now,
          expiryDate: now,
          isEnabled: false,
        ),
      );
    }

    return certificates;
  }
}
