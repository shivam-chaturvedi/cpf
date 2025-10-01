import 'package:flutter/material.dart';
import '../util/theme.dart';
import '../util/responsive.dart';
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
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: ResponsiveHelper.isMobile(context) ? 80 : 100,
                    height: ResponsiveHelper.isMobile(context) ? 80 : 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'CPF',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  Text(
                    'Collaborative Philanthropy Foundation',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Text(
                    'Amplifying sustainable impact for businesses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // About Section
            CustomCard(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Who We Are',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Text(
                      'Collaborative Philanthropy Foundation (CPF) is an incorporated Section 8 Company that builds on the expertise of OneStage (registered as Charities Aid Foundation India), a trust working since 1998. As an impact-led organization, CPF acts as a facilitator and implementer while providing consulting and management services to a vast client base including companies, CSR board, civil society organizations, philanthropic foundations, and more.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context)),
                    Text(
                      'Our Vision',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveSpacing(context) / 4),
                    Text(
                      'To create a world where collaborative philanthropy drives sustainable social impact, enabling businesses and organizations to make meaningful contributions to society through transparent, accountable, and effective giving.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Mission & Values
            ResponsiveHelper.getResponsiveLayout(
              context: context,
              mobile: Column(
                children: [
                  _buildMissionCard(context),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  _buildValuesCard(context),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(child: _buildMissionCard(context)),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(child: _buildValuesCard(context)),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(child: _buildMissionCard(context)),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(child: _buildValuesCard(context)),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Services Section
            CustomCard(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What We Do',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context)),
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

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Leadership Section
            CustomCard(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leadership',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context)),
                    ResponsiveHelper.getResponsiveLayout(
                      context: context,
                      mobile: Column(
                        children: [
                          Container(
                            width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                            height:
                                ResponsiveHelper.isMobile(context) ? 60 : 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.isMobile(context) ? 30 : 40),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryRed,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 30 : 40,
                            ),
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                      context) /
                                  2),
                          Column(
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
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 18,
                                        desktop: 20,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: ResponsiveHelper.getResponsiveSpacing(
                                          context) /
                                      4),
                              Text(
                                'Managing Director',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.w600,
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 18,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: ResponsiveHelper.getResponsiveSpacing(
                                          context) /
                                      2),
                              Text(
                                'Featured by The Enterprise World as one of the Most Impactful & Visionary Personalities to Look for in 2025. With his forward-thinking approach and dedication, Pratyush continues to steer CPF toward enabling transparency and collaborative philanthropy across India.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 13,
                                        tablet: 14,
                                        desktop: 16,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                      tablet: Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                            height:
                                ResponsiveHelper.isMobile(context) ? 60 : 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.isMobile(context) ? 30 : 40),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryRed,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 30 : 40,
                            ),
                          ),
                          SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(
                                  context)),
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
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 16,
                                          tablet: 18,
                                          desktop: 20,
                                        ),
                                      ),
                                ),
                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                                context) /
                                            4),
                                Text(
                                  'Managing Director',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryRed,
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 14,
                                          tablet: 16,
                                          desktop: 18,
                                        ),
                                      ),
                                ),
                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                                context) /
                                            2),
                                Text(
                                  'Featured by The Enterprise World as one of the Most Impactful & Visionary Personalities to Look for in 2025. With his forward-thinking approach and dedication, Pratyush continues to steer CPF toward enabling transparency and collaborative philanthropy across India.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.5,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 13,
                                          tablet: 14,
                                          desktop: 16,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      desktop: Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                            height:
                                ResponsiveHelper.isMobile(context) ? 60 : 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.isMobile(context) ? 30 : 40),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryRed,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 30 : 40,
                            ),
                          ),
                          SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(
                                  context)),
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
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 16,
                                          tablet: 18,
                                          desktop: 20,
                                        ),
                                      ),
                                ),
                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                                context) /
                                            4),
                                Text(
                                  'Managing Director',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryRed,
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 14,
                                          tablet: 16,
                                          desktop: 18,
                                        ),
                                      ),
                                ),
                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                                context) /
                                            2),
                                Text(
                                  'Featured by The Enterprise World as one of the Most Impactful & Visionary Personalities to Look for in 2025. With his forward-thinking approach and dedication, Pratyush continues to steer CPF toward enabling transparency and collaborative philanthropy across India.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.5,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 13,
                                          tablet: 14,
                                          desktop: 16,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Impact Statistics
            CustomCard(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Impact',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context)),
                    ResponsiveHelper.getResponsiveLayout(
                      context: context,
                      mobile: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '25+',
                                    'Years of Experience', Icons.schedule),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '500+',
                                    'NGOs Verified', Icons.verified),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                      context) /
                                  2),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '100+',
                                    'Corporate Partners', Icons.business),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '50+',
                                    'States Covered', Icons.map),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                      context) /
                                  2),
                          Row(
                            children: [
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
                      tablet: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '25+',
                                    'Years of Experience', Icons.schedule),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '500+',
                                    'NGOs Verified', Icons.verified),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '100+',
                                    'Corporate Partners', Icons.business),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                      context) /
                                  2),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '50+',
                                    'States Covered', Icons.map),
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
                      desktop: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '25+',
                                    'Years of Experience', Icons.schedule),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '500+',
                                    'NGOs Verified', Icons.verified),
                              ),
                              Expanded(
                                child: _buildStatItem(context, '100+',
                                    'Corporate Partners', Icons.business),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                      context) /
                                  2),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(context, '50+',
                                    'States Covered', Icons.map),
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
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Contact CTA
            Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context),
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
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 4),
                  Text(
                    'Join us in creating sustainable social change through collaborative philanthropy.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  ResponsiveHelper.getResponsiveLayout(
                    context: context,
                    mobile: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/contact'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryRed,
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveHelper.getResponsiveSpacing(
                                          context),
                                  vertical:
                                      ResponsiveHelper.getResponsiveSpacing(
                                              context) /
                                          2),
                            ),
                            child: Text(
                              'Get in Touch',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height:
                                ResponsiveHelper.getResponsiveSpacing(context) /
                                    2),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _launchWebsite(context,
                                'https://www.linkedin.com/company/collaborative-philanthropy-foundation/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveHelper.getResponsiveSpacing(
                                          context),
                                  vertical:
                                      ResponsiveHelper.getResponsiveSpacing(
                                              context) /
                                          2),
                            ),
                            child: Text(
                              'Follow on LinkedIn',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    tablet: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryRed,
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveHelper.getResponsiveSpacing(
                                        context),
                                vertical: ResponsiveHelper.getResponsiveSpacing(
                                        context) /
                                    2),
                          ),
                          child: Text(
                            'Get in Touch',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width:
                                ResponsiveHelper.getResponsiveSpacing(context) /
                                    2),
                        OutlinedButton(
                          onPressed: () => _launchWebsite(context,
                              'https://www.linkedin.com/company/collaborative-philanthropy-foundation/'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveHelper.getResponsiveSpacing(
                                        context),
                                vertical: ResponsiveHelper.getResponsiveSpacing(
                                        context) /
                                    2),
                          ),
                          child: Text(
                            'Follow on LinkedIn',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    desktop: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryRed,
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveHelper.getResponsiveSpacing(
                                        context),
                                vertical: ResponsiveHelper.getResponsiveSpacing(
                                        context) /
                                    2),
                          ),
                          child: Text(
                            'Get in Touch',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width:
                                ResponsiveHelper.getResponsiveSpacing(context) /
                                    2),
                        OutlinedButton(
                          onPressed: () => _launchWebsite(context,
                              'https://www.linkedin.com/company/collaborative-philanthropy-foundation/'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveHelper.getResponsiveSpacing(
                                        context),
                                vertical: ResponsiveHelper.getResponsiveSpacing(
                                        context) /
                                    2),
                          ),
                          child: Text(
                            'Follow on LinkedIn',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context)),
      child: ResponsiveHelper.getResponsiveLayout(
        context: context,
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.isMobile(context) ? 10 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
          ],
        ),
        tablet: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveHelper.isMobile(context) ? 20 : 24,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveHelper.isMobile(context) ? 20 : 24,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryRed,
          size: ResponsiveHelper.isMobile(context) ? 24 : 32,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 11,
                  tablet: 12,
                  desktop: 14,
                ),
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

  Widget _buildMissionCard(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: AppTheme.primaryRed,
                  size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 4),
                Text(
                  'Our Mission',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Text(
              'Enable informed giving by ensuring that every partnership rests on a foundation of credibility, accountability, and impact. We foster transparency and collaborative philanthropy across India.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuesCard(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppTheme.primaryOrange,
                  size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 4),
                Text(
                  'Our Values',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Text(
              'Transparency, Accountability, Impact, Collaboration, Credibility, and Trust form the core of everything we do.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
