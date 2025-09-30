import 'package:flutter/material.dart';
import '../util/theme.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/custome_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: const CustomNavbar(
        title: 'About Us',
        isLandingPage: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'CPF',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Collaborative Philanthropy Foundation',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amplifying sustainable impact for businesses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Who We Are',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Collaborative Philanthropy Foundation (CPF) is an incorporated Section 8 Company that builds on the expertise of OneStage (registered as Charities Aid Foundation India), a trust working since 1998. As an impact-led organization, CPF acts as a facilitator and implementer while providing consulting and management services to a vast client base including companies, CSR board, civil society organizations, philanthropic foundations, and more.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Our Vision',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To create a world where collaborative philanthropy drives sustainable social impact, enabling businesses and organizations to make meaningful contributions to society through transparent, accountable, and effective giving.',
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

            // Mission & Values
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.flag,
                                  color: AppTheme.primaryRed, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Our Mission',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enable informed giving by ensuring that every partnership rests on a foundation of credibility, accountability, and impact. We foster transparency and collaborative philanthropy across India.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite,
                                  color: AppTheme.primaryOrange, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Our Values',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Transparency, Accountability, Impact, Collaboration, Credibility, and Trust form the core of everything we do.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Services Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What We Do',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 20),
                    _buildServiceCard(
                      context,
                      'NGO Due Diligence',
                      'Rigorous assessment and verification of NGOs to ensure credibility and compliance with statutory and governance norms.',
                      Icons.verified_user,
                      AppTheme.primaryGreen,
                    ),
                    _buildServiceCard(
                      context,
                      'CSR Consulting',
                      'Strategic guidance for corporate social responsibility initiatives and sustainable impact programs.',
                      Icons.business_center,
                      AppTheme.primaryRed,
                    ),
                    _buildServiceCard(
                      context,
                      'Impact Assessment',
                      'Comprehensive evaluation of social impact and program effectiveness to measure real-world outcomes.',
                      Icons.analytics,
                      AppTheme.primaryOrange,
                    ),
                    _buildServiceCard(
                      context,
                      'Philanthropic Advisory',
                      'Expert consultation for effective philanthropic investments and strategic giving approaches.',
                      Icons.lightbulb,
                      AppTheme.accentGold,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Leadership Section
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leadership',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryRed,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. Pratyush Kumar Panda, PhD',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Managing Director',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Featured by The Enterprise World as one of the Most Impactful & Visionary Personalities to Look for in 2025. With his forward-thinking approach and dedication, Pratyush continues to steer CPF toward enabling transparency and collaborative philanthropy across India.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Impact Statistics
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Impact',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(context, '25+',
                              'Years of Experience', Icons.schedule),
                        ),
                        Expanded(
                          child: _buildStatItem(
                              context, '500+', 'NGOs Verified', Icons.verified),
                        ),
                        Expanded(
                          child: _buildStatItem(context, '100+',
                              'Corporate Partners', Icons.business),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                              context, '50+', 'States Covered', Icons.map),
                        ),
                        Expanded(
                          child: _buildStatItem(context, '1000+',
                              'Lives Impacted', Icons.favorite),
                        ),
                        Expanded(
                          child: _buildStatItem(context, '₹10Cr+',
                              'Funds Managed', Icons.attach_money),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to Make an Impact?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us in creating sustainable social change through collaborative philanthropy.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Get in Touch'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => _launchWebsite(context,
                            'https://www.linkedin.com/company/collaborative-philanthropy-foundation/'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Follow on LinkedIn'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _launchWebsite(BuildContext context, String url) {
    // In a real app, you would use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening website: $url')),
    );
  }
}
