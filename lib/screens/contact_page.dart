import 'package:flutter/material.dart';
import '../util/theme.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/custome_card.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: const CustomNavbar(
        title: 'Contact Us',
        isLandingPage: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get in Touch with CPF',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to help you make a meaningful impact through collaborative philanthropy.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Information Cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Office Address',
                    Icons.location_on,
                    '418, 4th Floor, World Trade Centre,\nBarakhamba Road,\nNew Delhi - 110001',
                    null,
                    AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Email Us',
                    Icons.email,
                    'info@cpfindia.org',
                    () => _launchEmail(context, 'info@cpfindia.org'),
                    AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Website',
                    Icons.web,
                    'www.cpfindia.org',
                    () => _launchWebsite(context, 'https://www.cpfindia.org'),
                    AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    context,
                    'LinkedIn',
                    Icons.business,
                    'Follow us on LinkedIn',
                    () => _launchWebsite(context,
                        'https://www.linkedin.com/company/collaborative-philanthropy-foundation/'),
                    AppTheme.accentGold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // About CPF Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.primaryRed, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'About Collaborative Philanthropy Foundation (CPF)',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CPF is an incorporated Section 8 Company that builds on the expertise of OneStage (registered as Charities Aid Foundation India), a trust working since 1998. As an impact-led organization, CPF acts as a facilitator and implementer while providing consulting and management services to a vast client base including companies, CSR board, civil society organizations, philanthropic foundations, and more.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Our Mission:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amplifying sustainable impact for businesses through collaborative philanthropy and enabling informed giving by ensuring that every partnership rests on a foundation of credibility, accountability, and impact.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Services Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work,
                            color: AppTheme.primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Our Services',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildServiceItem(
                      context,
                      'NGO Due Diligence',
                      'Rigorous assessment and verification of NGOs to ensure credibility and compliance.',
                    ),
                    _buildServiceItem(
                      context,
                      'CSR Consulting',
                      'Strategic guidance for corporate social responsibility initiatives.',
                    ),
                    _buildServiceItem(
                      context,
                      'Impact Assessment',
                      'Comprehensive evaluation of social impact and program effectiveness.',
                    ),
                    _buildServiceItem(
                      context,
                      'Philanthropic Advisory',
                      'Expert consultation for effective philanthropic investments.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Form Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message,
                            color: AppTheme.primaryGreen, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Send us a Message',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildContactForm(context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    IconData icon,
    String content,
    VoidCallback? onTap,
    Color color,
  ) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Tap to open',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: color, size: 16),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(
      BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: subjectController,
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: messageController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Your Message',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Handle form submission
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Send Message'),
          ),
        ),
      ],
    );
  }

  void _launchEmail(BuildContext context, String email) {
    // In a real app, you would use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email: $email')),
    );
  }

  void _launchWebsite(BuildContext context, String url) {
    // In a real app, you would use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening website: $url')),
    );
  }
}
