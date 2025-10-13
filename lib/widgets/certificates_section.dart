import 'package:flutter/material.dart';
import 'package:cpf_portal/widgets/certificate_card.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';

class CertificatesSection extends StatelessWidget {
  final String ngoName;
  final String ngoAddress;
  final String cfoName;
  final String logoPath;

  const CertificatesSection({
    super.key,
    required this.ngoName,
    required this.ngoAddress,
    required this.cfoName,
    required this.logoPath,
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
    final issueDate = now.subtract(const Duration(days: 30));
    final expiryDate = now.add(const Duration(days: 335));

    return [
      // Due Diligence Certificate
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
        certificateId:
            'DD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        issueDate: issueDate,
        expiryDate: expiryDate,
      ),

      // Compliance Certificate
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
        certificateId:
            'COMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        issueDate: issueDate,
        expiryDate: expiryDate,
      ),

      // Letterhead Certificate
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
        certificateId:
            'LH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        issueDate: issueDate,
        expiryDate: expiryDate,
      ),

      // // Expired Certificate Example
      // CertificateCard(
      //   title: 'Previous Compliance Certificate',
      //   description:
      //       'Previous compliance certificate that has expired and needs renewal.',
      //   icon: Icons.schedule,
      //   color: Colors.orange,
      //   ngoName: ngoName,
      //   ngoAddress: ngoAddress,
      //   cfoName: cfoName,
      //   logoPath: logoPath,
      //   certificateType: 'compliance',
      //   certificateId:
      //       'COMP-OLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      //   issueDate: now.subtract(const Duration(days: 400)),
      //   expiryDate: now.subtract(const Duration(days: 10)),
      //   isExpired: true,
      // ),
    ];
  }
}
