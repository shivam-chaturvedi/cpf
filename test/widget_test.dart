// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cpf_portal/main.dart';

void main() {
  testWidgets('CPF Portal app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CPFPortalApp());

    // Verify that the landing page loads with the tagline
    expect(find.text('"Empowering NGOs Through Trust & Transparency"'), findsOneWidget);
    
    // Verify that the Register button is present
    expect(find.text('Register Your NGO'), findsOneWidget);
    
    // Verify that the Learn More button is present
    expect(find.text('Learn More'), findsOneWidget);
  });

  testWidgets('Navigation to login page works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CPFPortalApp());

    // Find and tap the Login button (you may need to adjust this based on your actual UI)
    final loginButton = find.text('Login');
    expect(loginButton, findsOneWidget);
    
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify that we're on the login page
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your NGO account'), findsOneWidget);
  });
}