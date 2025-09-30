import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../util/theme.dart';
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
      title: Row(
        children: [
          // CPF Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/CPF_Logo.jpg',
                fit: BoxFit.cover,
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
                      ),
                ),
                if (isLandingPage)
                  Text(
                    'Collaborative Philanthropy Foundation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: showBackButton,
      actions: actions ?? _buildDefaultActions(context),
      bottom: isLandingPage ? _buildLandingPageBottom(context) : null,
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
                const PopupMenuItem(
                  value: 'home',
                  child: ListTile(
                    leading: Icon(Icons.home, color: AppTheme.primaryRed),
                    title: Text('Home'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info, color: AppTheme.primaryRed),
                    title: Text('About Us'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'contact',
                  child: ListTile(
                    leading:
                        Icon(Icons.contact_mail, color: AppTheme.primaryRed),
                    title: Text('Contact'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'donate',
                  child: ListTile(
                    leading: Icon(Icons.favorite, color: AppTheme.primaryRed),
                    title: Text('Donate'),
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
                          '${_getDashboardTitle(authProvider.userRole)} Dashboard'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person, color: AppTheme.primaryRed),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: AppTheme.primaryRed),
                      title: Text('Logout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ]);
              } else {
                // Add login items for non-logged-in users
                items.addAll([
                  const PopupMenuItem(
                    value: 'admin_login',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings,
                          color: AppTheme.primaryRed),
                      title: Text('Admin Login'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ngo_login',
                    child: ListTile(
                      leading: Icon(Icons.business, color: AppTheme.primaryRed),
                      title: Text('NGO Login'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'donor_login',
                    child: ListTile(
                      leading: Icon(Icons.people, color: AppTheme.primaryRed),
                      title: Text('Donor Login'),
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
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem('Home', Icons.home, () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }),
            ),
            Expanded(
              child: _buildNavItem('About', Icons.info, () {
                Navigator.pushNamed(context, '/about');
              }),
            ),
            Expanded(
              child: _buildNavItem('Contact', Icons.contact_mail, () {
                Navigator.pushNamed(context, '/contact');
              }),
            ),
            Expanded(
              child: _buildNavItem('Donate', Icons.favorite, () {
                Navigator.pushNamed(context, '/donate');
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
      case 'donate':
        Navigator.pushNamed(context, '/donate');
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
    }
  }

  String _getDashboardTitle(UserRole? userRole) {
    if (userRole == null) return 'User';

    switch (userRole) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.ngo:
        return 'NGO';
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/CPF_Logo.jpg',
                fit: BoxFit.cover,
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
                      ),
                ),
                Text(
                  '${userType.toUpperCase()} Dashboard',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 1,
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
              const PopupMenuItem(
                value: 'home',
                child: ListTile(
                  leading: Icon(Icons.home, color: AppTheme.primaryRed),
                  title: Text('Home'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info, color: AppTheme.primaryRed),
                  title: Text('About Us'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: ListTile(
                  leading: Icon(Icons.contact_mail, color: AppTheme.primaryRed),
                  title: Text('Contact'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'donate',
                child: ListTile(
                  leading: Icon(Icons.favorite, color: AppTheme.primaryRed),
                  title: Text('Donate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              // Dashboard Actions
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: AppTheme.primaryRed),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help, color: AppTheme.primaryRed),
                  title: Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppTheme.primaryRed),
                  title: Text('Logout'),
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
      case 'donate':
        Navigator.pushNamed(context, '/donate');
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
