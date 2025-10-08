import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';

class OrganizationsCarousel extends StatefulWidget {
  const OrganizationsCarousel({super.key});

  @override
  State<OrganizationsCarousel> createState() => _OrganizationsCarouselState();
}

class _OrganizationsCarouselState extends State<OrganizationsCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _organizations = [
    {
      'name': 'Plan International India',
      'description': 'Child rights and equality for girls',
      'icon': Icons.child_care,
      'color': Colors.blue,
    },
    {
      'name': 'Anant National University',
      'description': 'Design education and innovation',
      'icon': Icons.school,
      'color': Colors.green,
    },
    {
      'name': 'National Law School of India University',
      'description': 'Legal education and research',
      'icon': Icons.gavel,
      'color': Colors.purple,
    },
    {
      'name': 'SOUL – School of Ultimate Leadership',
      'description': 'Leadership development programs',
      'icon': Icons.leaderboard,
      'color': Colors.orange,
    },
    {
      'name': 'Shri Sathya Sai Institute',
      'description': 'Spiritual and educational services',
      'icon': Icons.spa,
      'color': Colors.teal,
    },
    {
      'name': 'Rishihood University',
      'description': 'Innovation and entrepreneurship',
      'icon': Icons.lightbulb,
      'color': Colors.indigo,
    },
    {
      'name': 'Pratham',
      'description': 'Education for every child',
      'icon': Icons.menu_book,
      'color': Colors.red,
    },
    {
      'name': 'CYDA',
      'description': 'Youth development and advocacy',
      'icon': Icons.people,
      'color': Colors.pink,
    },
    {
      'name': 'SH Associates',
      'description': 'Professional consulting services',
      'icon': Icons.business,
      'color': Colors.brown,
    },
    {
      'name': 'Light of Life Trust',
      'description': 'Healthcare and social services',
      'icon': Icons.health_and_safety,
      'color': Colors.cyan,
    },
    {
      'name': 'Rural Organisation for Poverty Eradication',
      'description': 'Rural development and poverty alleviation',
      'icon': Icons.home_work,
      'color': Colors.deepOrange,
    },
    {
      'name': 'Foundation for Initiatives in Development',
      'description': 'Development initiatives and capacity building',
      'icon': Icons.trending_up,
      'color': Colors.lime,
    },
    {
      'name': 'Subhiksha Voluntary Organization',
      'description': 'Community development and welfare',
      'icon': Icons.volunteer_activism,
      'color': Colors.amber,
    },
    {
      'name': 'Diya Foundation',
      'description': 'Educational and social initiatives',
      'icon': Icons.lightbulb_outline,
      'color': Colors.deepPurple,
    },
    {
      'name': 'Shishu Mandir',
      'description': 'Child welfare and education',
      'icon': Icons.child_friendly,
      'color': Colors.lightBlue,
    },
    {
      'name': 'Akshara Foundation',
      'description': 'Education and learning solutions',
      'icon': Icons.school,
      'color': Colors.greenAccent,
    },
    {
      'name': 'Christel House India',
      'description': 'Education and life skills development',
      'icon': Icons.church,
      'color': Colors.blueGrey,
    },
    {
      'name': 'YuvaLok Foundation',
      'description': 'Youth empowerment and development',
      'icon': Icons.emoji_people,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Nudge Lifeskills Foundation',
      'description': 'Life skills and employability training',
      'icon': Icons.work,
      'color': Colors.tealAccent,
    },
    {
      'name': 'Junglescapes Charitable Trust',
      'description': 'Environmental conservation and research',
      'icon': Icons.eco,
      'color': Colors.lightGreen,
    },
    {
      'name': 'United Way of Bengaluru',
      'description': 'Community impact and social change',
      'icon': Icons.handshake,
      'color': Colors.redAccent,
    },
    {
      'name': 'ASSCOD',
      'description': 'Social development and community services',
      'icon': Icons.group,
      'color': Colors.purpleAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _startAutoPlay();
    _animationController.forward();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _currentIndex = (_currentIndex + 1) % _organizations.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'Trusted by Leading Organizations',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 18,
                    tablet: 22,
                    desktop: 26,
                  ),
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          Text(
            'We are proud to partner with these esteemed organizations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          Container(
            height: ResponsiveHelper.isMobile(context) ? 200 : 250,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _organizations.length,
              itemBuilder: (context, index) {
                return _buildOrganizationCard(_organizations[index]);
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> organization) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
        vertical: 8,
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                organization['color'].withOpacity(0.1),
                organization['color'].withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: organization['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    organization['icon'],
                    size: ResponsiveHelper.isMobile(context) ? 40 : 50,
                    color: organization['color'],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  organization['name'],
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  organization['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _organizations.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? AppTheme.primaryRed
                : AppTheme.primaryRed.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
