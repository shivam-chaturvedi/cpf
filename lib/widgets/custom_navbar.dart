import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../util/theme.dart';
import '../util/responsive.dart';
import '../providers/auth_provider.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isLandingPage;

  const CustomNavbar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.isLandingPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: ResponsiveHelper.isMobile(context)
          ? 100
          : 120, // Increased height for larger logo
      title: Row(
        children: [
          // CPF Logo
          Container(
            width: ResponsiveHelper.isMobile(context)
                ? 180
                : 220, // Further increased width
            height: ResponsiveHelper.isMobile(context)
                ? 70
                : 90, // Further increased height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/CPF_Logo.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to text logo if image fails to load
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'CPF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize:
                              ResponsiveHelper.isMobile(context) ? 14 : 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NPO Registration Portal', // Changed from NGO to NPO
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                ),
                // Removed the "Collaborative Philanthropy Foundation" text as requested
              ],
            ),
          ),
          // Add flexible space before navigation links to push them right
          if (!ResponsiveHelper.isMobile(context)) const Spacer(flex: 3),
          // Navigation Links (Desktop/Tablet only)
          if (!ResponsiveHelper.isMobile(context)) ...[
            _NavLink(
              label: 'Home',
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false),
              isActive: ModalRoute.of(context)?.settings.name == '/',
            ),
            const SizedBox(width: 8),
            _NavLink(
              label: 'About Us',
              onTap: () => Navigator.pushNamed(context, '/about'),
              isActive: ModalRoute.of(context)?.settings.name == '/about',
            ),
            const SizedBox(width: 8),
            _NavLink(
              label: 'NPO Registration',
              onTap: () => Navigator.pushNamed(context, '/ngo-login'),
              isActive: ModalRoute.of(context)?.settings.name == '/ngo-login',
            ),
            const SizedBox(width: 8),
            _NavLink(
              label: 'CPF Website',
              onTap: () => _launchURL(context, 'https://cpfindia.org/'),
            ),
            const SizedBox(width: 8),
            _NavLink(
              label: 'Contact',
              onTap: () => Navigator.pushNamed(context, '/contact'),
              isActive: ModalRoute.of(context)?.settings.name == '/contact',
            ),
          ],
          // Empty space for right alignment
          const Spacer(flex: 1),
        ],
      ),
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showBackButton,
      actions: actions ?? _buildDefaultActions(context),
      // bottom: isLandingPage ?r _buildLandingPageBottom(context) : null,
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    return [
      // Combined Menu with Navigation + Authentication
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
            onSelected: (value) => _handleCombinedMenuSelection(context, value),
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [
                // Navigation Items
                PopupMenuItem(
                  value: 'home',
                  child: ListTile(
                    leading: Icon(Icons.home, color: AppTheme.primaryRed),
                    title: Text(
                      'Home',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info, color: AppTheme.primaryRed),
                    title: Text(
                      'About Us',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'cpf_website',
                  child: ListTile(
                    leading: Icon(Icons.web, color: AppTheme.primaryRed),
                    title: Text(
                      'CPF Website',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'onestage_website',
                  child: ListTile(
                    leading: Icon(Icons.web, color: AppTheme.primaryRed),
                    title: Text(
                      'OneStage Website',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'contact',
                  child: ListTile(
                    leading:
                        Icon(Icons.contact_mail, color: AppTheme.primaryRed),
                    title: Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
              ];

              if (authProvider.isLoggedIn) {
                // Add authentication items for logged-in users
                items.addAll([
                  PopupMenuItem(
                    value: 'dashboard',
                    child: ListTile(
                      leading: Icon(
                        _getDashboardIcon(authProvider.userRole),
                        color: AppTheme.primaryRed,
                      ),
                      title: Text(
                        '${_getDashboardTitle(authProvider.userRole)} Dashboard',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person, color: AppTheme.primaryRed),
                      title: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: AppTheme.primaryRed),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ]);
              } else {
                // Add login items for non-logged-in users
                items.addAll([
                  PopupMenuItem(
                    value: 'admin_login',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings,
                          color: AppTheme.primaryRed),
                      title: Text(
                        'Admin Login',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ngo_login',
                    child: ListTile(
                      leading: Icon(Icons.business, color: AppTheme.primaryRed),
                      title: Text(
                        'NGO Login',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'donor_login',
                    child: ListTile(
                      leading: Icon(Icons.people, color: AppTheme.primaryRed),
                      title: Text(
                        'Donor Login',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ]);
              }

              return items;
            },
          );
        },
      ),
      const SizedBox(width: 8),
    ];
  }

  PreferredSizeWidget? _buildLandingPageBottom(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: AppTheme.surfaceWhite,
        margin: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(context, 'Home', Icons.home, () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }),
            ),
            Expanded(
              child: _buildNavItem(context, 'About Us', Icons.info, () {
                Navigator.pushNamed(context, '/about');
              }),
            ),
            Expanded(
              child: _buildNavItem(context, 'CPF Website', Icons.web, () {
                _launchWebsite(context, 'https://cpfindia.org/');
              }),
            ),
            Expanded(
              child: _buildNavItem(context, 'OneStage Website', Icons.web, () {
                _launchWebsite(context, 'https://theonestage.org/');
              }),
            ),
            Expanded(
              child: _buildNavItem(context, 'Contact', Icons.contact_mail, () {
                Navigator.pushNamed(context, '/contact');
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
          horizontal: ResponsiveHelper.isMobile(context) ? 4 : 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryRed,
              size: ResponsiveHelper.isMobile(context) ? 16 : 20,
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 2 : 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 9,
                    tablet: 10,
                    desktop: 12,
                  ),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCombinedMenuSelection(BuildContext context, String value) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (value) {
      // Navigation items
      case 'home':
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 'about':
        Navigator.pushNamed(context, '/about');
        break;
      case 'contact':
        Navigator.pushNamed(context, '/contact');
        break;
      case 'cpf_website':
        _launchWebsite(context, 'https://cpfindia.org/');
        break;
      case 'onestage_website':
        _launchWebsite(context, 'https://theonestage.org/');
        break;

      // Login items
      case 'admin_login':
        Navigator.pushNamed(context, '/admin-login');
        break;
      case 'ngo_login':
        Navigator.pushNamed(context, '/ngo-login');
        break;
      case 'donor_login':
        Navigator.pushNamed(context, '/donor-login');
        break;

      // Authentication items
      case 'dashboard':
        _navigateToDashboard(context, authProvider.userRole);
        break;
      case 'profile':
        _navigateToProfile(context, authProvider.userRole);
        break;
      case 'logout':
        _handleLogout(context, authProvider);
        break;
    }
  }

  void _navigateToDashboard(BuildContext context, UserRole? userRole) {
    if (userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role not found')),
      );
      return;
    }

    switch (userRole) {
      case UserRole.admin:
        Navigator.pushNamed(context, '/admin-dashboard');
        break;
      case UserRole.ngo:
        Navigator.pushNamed(context, '/ngo-dashboard');
        break;
      case UserRole.donor:
        Navigator.pushNamed(context, '/donor-dashboard');
        break;
    }
  }

  void _navigateToProfile(BuildContext context, UserRole? userRole) {
    // For now, navigate to dashboard. In future, create separate profile pages
    _navigateToDashboard(context, userRole);
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  IconData _getDashboardIcon(UserRole? userRole) {
    if (userRole == null) return Icons.dashboard;

    switch (userRole) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.ngo:
        return Icons.business;
      case UserRole.donor:
        return Icons.people;
    }
  }

  String _getDashboardTitle(UserRole? userRole) {
    if (userRole == null) return 'User';

    switch (userRole) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.donor:
        return 'Donor';
    }
  }

  void _launchWebsite(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening website: $e')),
      );
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(
        isLandingPage ? 120 : kToolbarHeight,
      );
}

class DashboardNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userType;
  final VoidCallback? onLogout;
  final VoidCallback? onRefresh;

  const DashboardNavbar({
    super.key,
    required this.title,
    required this.userType,
    this.onLogout,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: ResponsiveHelper.isMobile(context) ? 160 : 200,
            height: ResponsiveHelper.isMobile(context) ? 60 : 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/CPF_Logo.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to text logo if image fails to load
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'CPF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${userType.toUpperCase()} Dashboard',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 9,
                          tablet: 10,
                          desktop: 12,
                        ),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
        // Combined Menu with Navigation + Dashboard Actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
          onSelected: (value) => _handleDashboardMenuSelection(context, value),
          itemBuilder: (context) {
            List<PopupMenuEntry<String>> items = [
              // Navigation Items
              PopupMenuItem(
                value: 'home',
                child: ListTile(
                  leading: Icon(Icons.home, color: AppTheme.primaryRed),
                  title: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info, color: AppTheme.primaryRed),
                  title: Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'contact',
                child: ListTile(
                  leading: Icon(Icons.contact_mail, color: AppTheme.primaryRed),
                  title: Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'website',
                child: ListTile(
                  leading: Icon(Icons.web, color: AppTheme.primaryRed),
                  title: Text(
                    'CPF Website',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              // Dashboard Actions
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: AppTheme.primaryRed),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help, color: AppTheme.primaryRed),
                  title: Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppTheme.primaryRed),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
            return items;
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleDashboardMenuSelection(BuildContext context, String value) {
    switch (value) {
      // Navigation items
      case 'home':
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 'about':
        Navigator.pushNamed(context, '/about');
        break;
      case 'contact':
        Navigator.pushNamed(context, '/contact');
        break;
      case 'website':
        _launchURL(context, 'https://cpfindia.org/');
        break;

      // Dashboard actions
      case 'profile':
        _navigateToProfile(context, userType);
        break;
      case 'help':
        Navigator.pushNamed(context, '/contact');
        break;
      case 'logout':
        if (onLogout != null) onLogout!();
        break;
    }
  }

  void _navigateToProfile(BuildContext context, String userType) {
    // For now, navigate to dashboard. In future, create separate profile pages
    switch (userType.toLowerCase()) {
      case 'admin':
        Navigator.pushNamed(context, '/admin-dashboard');
        break;
      case 'ngo':
        Navigator.pushNamed(context, '/ngo-dashboard');
        break;
      case 'donor':
        Navigator.pushNamed(context, '/donor-dashboard');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown user type')),
        );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Helper widget for navigation links
class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _NavLink({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
        ),
      ),
    );
  }
}

// Helper function for launching URLs
Future<void> _launchURL(BuildContext context, String url) async {
  try {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening website: $e')),
      );
    }
  }
}
