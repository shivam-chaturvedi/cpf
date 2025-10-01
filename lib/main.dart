import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Import the Firebase options
import 'providers/auth_provider.dart';
import 'providers/ngo_provider.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/ngo_login.dart';
import 'screens/ngo_registration.dart';
import 'screens/ngo_dashboard.dart';
import 'screens/admin_login.dart';
import 'screens/admin_dashboard.dart';
import 'screens/donor_login.dart';
import 'screens/donor_registration.dart';
import 'screens/donor_dashboard.dart';
import 'screens/contact_page.dart';
import 'screens/about_page.dart';
import 'screens/ngo_list_page.dart';
import 'screens/donate_page.dart';
import 'package:cpf_portal/util/theme.dart' as cpf_theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CPFPortalApp());
}

class CPFPortalApp extends StatelessWidget {
  const CPFPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NGOProvider()),
      ],
      child: MaterialApp(
        title: 'NPO Registration Portal',
        theme: cpf_theme.AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const AuthWrapper());
            case '/ngo-login':
              return MaterialPageRoute(builder: (_) => const NGOLoginPage());
            case '/ngo-register':
              return MaterialPageRoute(
                  builder: (_) => const NGORegistrationPage());
            case '/ngo-dashboard':
              return MaterialPageRoute(builder: (_) => const NGODashboard());
            case '/admin-login':
              return MaterialPageRoute(builder: (_) => const AdminLoginPage());
            case '/admin-dashboard':
              return MaterialPageRoute(builder: (_) => const AdminDashboard());
            case '/donor-login':
              return MaterialPageRoute(builder: (_) => const DonorLoginPage());
            case '/donor-register':
              return MaterialPageRoute(
                  builder: (_) => const DonorRegistrationPage());
            case '/donor-dashboard':
              return MaterialPageRoute(builder: (_) => const DonorDashboard());
            case '/contact':
              return MaterialPageRoute(builder: (_) => const ContactPage());
            case '/about':
              return MaterialPageRoute(builder: (_) => const AboutPage());
            case '/ngo-list':
              return MaterialPageRoute(builder: (_) => const NGOListPage());
            case '/donate':
              return MaterialPageRoute(builder: (_) => const DonatePage());
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Page not found')),
                ),
              );
          }
        },
      ),
    );
  }
}
