import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/landing_page.dart';
import '../screens/admin_dashboard.dart';
import '../screens/ngo_dashboard.dart';
import '../screens/donor_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading indicator while checking authentication
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, redirect to appropriate dashboard
        if (authProvider.isLoggedIn && authProvider.userRole != null) {
          switch (authProvider.userRole!) {
            case UserRole.admin:
              return const AdminDashboard();
            case UserRole.ngo:
              return const NGODashboard();
            case UserRole.donor:
              return const DonorDashboard();
          }
        }

        // If not logged in, show landing page
        return const LandingPage();
      },
    );
  }
}
