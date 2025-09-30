import 'dart:async';
import 'package:cpf_portal/widgets/faq_section.dart';
import 'package:flutter/material.dart';

import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_navbar.dart';

// Added missing BannerImageRotator class
class BannerImageRotator extends StatefulWidget {
  const BannerImageRotator({super.key});

  @override
  State<BannerImageRotator> createState() => _BannerImageRotatorState();
}

class _BannerImageRotatorState extends State<BannerImageRotator> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _images = [
    'images/Banner1.png',
    'images/Banner2.png',
    'images/Banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: Image.asset(
            _images[_currentIndex],
            key: ValueKey<String>(_images[_currentIndex]),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 500,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.primaryRed,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    color: AppTheme.surfaceWhite,
                    size: 100,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Section keys for smooth scrolling
  final GlobalKey _heroSectionKey = GlobalKey();
  final GlobalKey _benefitsSectionKey = GlobalKey();
  final GlobalKey _servicesSectionKey = GlobalKey();
  final GlobalKey _faqSectionKey = GlobalKey();
  final GlobalKey _supportSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Smooth scrolling function
  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: const CustomNavbar(
        title: 'CPF Portal',
        isLandingPage: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(key: _heroSectionKey, child: _buildHeroSection()),
            Container(key: _benefitsSectionKey, child: _buildBenefitsSection()),
            _buildStatsSection(),
            _buildVideoSection(),
            _buildTestimonialsSection(),
            Container(key: _servicesSectionKey, child: _buildServicesSection()),
            _buildImpactSection(),
            _buildPartnersSection(),
            Container(key: _faqSectionKey, child: _buildFAQSection()),
            Container(key: _supportSectionKey, child: _buildSupportSection()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: AppHelpers.getResponsivePadding(context),
            child: Column(
              children: [
                // Banner Image Rotator
                const BannerImageRotator(),

                const SizedBox(height: 40),

                Text(
                  'Empowering NGOs Through Trust & Transparency',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.surfaceWhite,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Overview text from blueprint
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Text(
                    'The Collaborative Philanthropy Foundation (CPF) is a forward-looking Section 8 company that builds upon the legacy and experience of Charities Aid Foundation India, a trusted entity that has been serving the development sector since 1998. CPF operates as an impact-led, research and data-driven organization, offering customized support to a wide array of stakeholders including companies, CSR boards, civil society organizations, and philanthropic foundations.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.surfaceWhite.withOpacity(0.9),
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Benefits checkmarks from wireframe
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildBenefitItem('✅ Register your NGO'),
                    _buildBenefitItem('✅ Get Validated'),
                    _buildBenefitItem('✅ Submit Proposals'),
                    _buildBenefitItem('✅ Build Donor Trust'),
                  ],
                ),

                const SizedBox(height: 40),

                // CTA Buttons from wireframe
                AppHelpers.isMobile(context)
                    ? Column(
                        children: [
                          CustomButton(
                            text: 'Register Your NGO',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/ngo-register'),
                            icon: Icons.app_registration,
                            backgroundColor: AppTheme.primaryOrange,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Learn More',
                            onPressed: () =>
                                _scrollToSection(_benefitsSectionKey),
                            icon: Icons.info_outline,
                            isOutlined: true,
                            backgroundColor: AppTheme.surfaceWhite,
                            width: double.infinity,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            text: 'Register Your NGO',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/ngo-register'),
                            icon: Icons.app_registration,
                            backgroundColor: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 16),
                          CustomButton(
                            text: 'Learn More',
                            onPressed: () =>
                                _scrollToSection(_benefitsSectionKey),
                            icon: Icons.info_outline,
                            isOutlined: true,
                            backgroundColor: AppTheme.surfaceWhite,
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.surfaceWhite.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.surfaceWhite,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        children: [
          Text(
            'Why Choose CPF Portal?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The portal is designed to empower NGOs by streamlining access to funding opportunities, enhancing visibility, and ensuring greater transparency through a structured due diligence process.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: AppHelpers.isDesktop(context) ? 3 : 1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: AppHelpers.isDesktop(context) ? 1.2 : 2.5,
            children: [
              _buildFeatureCard(
                Icons.verified_user,
                'Streamlined Access',
                'Easy access to funding opportunities and enhanced visibility for your NGO\'s impactful work.',
                AppTheme.primaryRed,
              ),
              _buildFeatureCard(
                Icons.visibility,
                'Greater Transparency',
                'Structured due diligence process ensuring transparency and building trust with donors.',
                AppTheme.primaryOrange,
              ),
              _buildFeatureCard(
                Icons.schedule,
                'Save Time & Resources',
                'Simplified compliance and documentation helps you focus on your core mission of creating change.',
                AppTheme.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, String description, Color color) {
    return CustomCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_center,
                color: AppTheme.primaryOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Our Services',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We provide specialized services to support donors and stakeholders in evaluating and partnering with credible NGOs.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: AppHelpers.isDesktop(context) ? 2 : 1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: AppHelpers.isDesktop(context) ? 2 : 1.5,
            children: [
              _buildServiceCard(
                Icons.fact_check,
                'Due Diligence Review',
                'Comprehensive assessment of an NGO\'s legal status, governance, financials, and operations, including field visits and AML/CFT checks.',
                AppTheme.primaryRed,
              ),
              _buildServiceCard(
                Icons.verified,
                'Compliance Checks',
                'Verification of statutory documents like 12A, 80G, FCRA, CSR-1, audit reports, and other key filings.',
                AppTheme.primaryOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      IconData icon, String title, String description, Color color) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
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
                const SizedBox(height: 8),
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

  Widget _buildFAQSection() {
    return Container(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: AppTheme.primaryRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQ Section with questions from wireframe
          const FAQSection(
            faqs: [
              {
                'question': 'How do I register my NGO on the portal?',
                'answer':
                    'To register your NGO, click on the "Register" button on the homepage, fill in the required organization and contact details, upload the necessary documents, and submit the application. You will receive a confirmation once the registration is successful.',
              },
              {
                'question': 'Is there a fee for registration or validation?',
                'answer':
                    'Yes, the registration and validation processes on the portal are chargeable. This has been confirmed by the CPF support team. You may contact their support team for further details. Once confirmed, you can proceed with filling out the registration form.'
              },
              {
                'question': 'What documents are required for NGO registration?',
                'answer':
                    'You typically need to submit your registration certificate, PAN card, address proof, details of governing body members, and recent financial statements. The specific requirements will be listed during the registration process.',
              },
              {
                'question': 'How long does it take for registration approval?',
                'answer':
                    'The approval process usually takes 5-10 working days, depending on the completeness of your submission and the volume of applications.',
              },
              {
                'question':
                    'What should I do if my registration is rejected or returned for correction?',
                'answer':
                    'If your application is rejected or returned, review the remarks provided, make the necessary corrections, and resubmit the application. You can also contact support for clarification.',
              },
              {
                'question':
                    'How can I update my NGO\'s information on the portal?',
                'answer':
                    'After logging in, navigate to the "Profile" section where you can edit or update your organization\'s details. Any changes will be subject to review and approval.',
              },
              {
                'question':
                    'What is the validation process after registration?',
                'answer':
                    'Validation involves verifying the authenticity of submitted documents and information. This may include cross-checking with government databases and requesting additional clarification if needed.',
              },
              {
                'question':
                    'How do I ensure my NGO remains compliant with portal requirements?',
                'answer':
                    'Ensure timely submission of annual reports, financial statements, and any required declarations. Keep your information up to date and follow all listed compliance guidelines.',
              },
              {
                'question':
                    'What happens if my NGO fails to maintain compliance?',
                'answer':
                    'Non-compliance may lead to temporary suspension or deactivation of your account. You will be notified of the issue and given a chance to rectify it before any further action is taken.',
              },
              {
                'question': 'Can multiple users manage the same NGO profile?',
                'answer':
                    'Yes, you can assign additional authorized users to your NGO profile. Each user must have a unique login and appropriate permissions.',
              },
              {
                'question':
                    'Where can I track the status of my registration or validation?',
                'answer':
                    'You can check the status of your application by logging into your account and viewing the "Application Status" dashboard.',
              },
              {
                'question':
                    'Whom should I contact for technical support or assistance?',
                'answer':
                    'For any issues or queries, you can reach out to our support team via the "Help & Support" section on the portal or email us at support@cpfindia.org.',
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: AppHelpers.getResponsivePadding(context),
      child: CustomCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent,
                  color: AppTheme.primaryRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Need Help?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Updated support details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactItem(
                  Icons.phone,
                  'Phone Support',
                  '91 9871216099',
                  () => AppHelpers.showInfoSnackBar(
                      context, 'Phone: 91 9871216099'),
                ),
                if (AppHelpers.isDesktop(context))
                  Container(
                    width: 1,
                    height: 60,
                    color: AppTheme.borderGray,
                  ),
                _buildContactItem(
                  Icons.email,
                  'Email Support',
                  'support@cpfindia.org',
                  () => AppHelpers.showInfoSnackBar(
                      context, 'Email: support@cpfindia.org'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon, String title, String contact, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              contact,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Our Impact in Numbers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '500+',
                  'NGOs Registered',
                  Icons.business,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '₹50M+',
                  'Funds Disbursed',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '25+',
                  'Years Experience',
                  Icons.timeline,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '1000+',
                  'Lives Impacted',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String number, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 16),
          Text(
            number,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(
            'See CPF in Action',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Watch how we\'re making a difference in communities across India',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Placeholder for video - in real app, use video_player package
                  Container(
                    color: AppTheme.primaryRed,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Watch Our Impact Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Play button overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed.withOpacity(0.1),
            AppTheme.primaryOrange.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'What Our Partners Say',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTestimonialCard(
                  'Sarah Johnson',
                  'CEO, Green Earth Foundation',
                  'CPF has been instrumental in helping us scale our environmental initiatives. Their transparent processes and dedicated support have made all the difference.',
                  Icons.eco,
                ),
                const SizedBox(width: 20),
                _buildTestimonialCard(
                  'Rajesh Kumar',
                  'Founder, Education for All',
                  'The impact measurement tools provided by CPF have helped us demonstrate our effectiveness to donors. Highly recommended!',
                  Icons.school,
                ),
                const SizedBox(width: 20),
                _buildTestimonialCard(
                  'Priya Sharma',
                  'Director, Women Empowerment NGO',
                  'CPF\'s capacity building programs have transformed our organization. We\'ve seen a 300% increase in our impact metrics.',
                  Icons.person,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(
      String name, String title, String quote, IconData icon) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryRed, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$quote"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
                5,
                (index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Our Impact Stories',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildImpactCard(
                  'Education Initiative',
                  'Built 50 schools in rural areas, impacting 10,000+ children',
                  'images/Banner1.png',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildImpactCard(
                  'Healthcare Access',
                  'Provided medical care to 25,000+ underserved families',
                  'images/Banner2.png',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildImpactCard(
                  'Environmental Conservation',
                  'Planted 100,000+ trees and restored 500 acres of forest',
                  'images/Banner3.png',
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(
      String title, String description, String imagePath, Color color) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: color.withOpacity(0.8),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Text(
            'Trusted by Leading Organizations',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 40,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildPartnerLogo('Tata Group'),
              _buildPartnerLogo('Reliance Foundation'),
              _buildPartnerLogo('Infosys Foundation'),
              _buildPartnerLogo('Wipro Foundation'),
              _buildPartnerLogo('HDFC Bank'),
              _buildPartnerLogo('ICICI Foundation'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerLogo(String name) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: AppTheme.textPrimary,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // Social Media Icons + Footer Links from wireframe
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.link,
                color: AppTheme.surfaceWhite,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CPF Social Media & Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.surfaceWhite,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildFooterLink(
                'Website',
                'https://cpfindia.org/',
                Icons.language,
              ),
              _buildFooterLink(
                'LinkedIn',
                'LinkedIn Profile',
                Icons.business,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            height: 1,
            color: AppTheme.surfaceWhite.withOpacity(0.2),
          ),

          const SizedBox(height: 24),

          Text(
            '© 2024 Collaborative Philanthropy Foundation. All rights reserved.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.surfaceWhite.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () => AppHelpers.showInfoSnackBar(context, '$title: $subtitle'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.surfaceWhite.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.surfaceWhite,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.surfaceWhite.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
