import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import screens
import 'screens/admin/admin_dashboard.dart';
import 'screens/public/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/donor/donor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase with config from .env
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      authDomain: '${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      databaseURL: 'https://${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseio.com',
    ),
  );
  runApp(const ProviderScope(child: FirebaseInitWrapper()));
}

class FirebaseInitWrapper extends StatelessWidget {
  const FirebaseInitWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Firebase is already initialized in main(), so we can directly return the app
    return const CareConnectApp();
  }
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Blue
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF10B981), // Green
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const LandingPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/donor-home': (context) => const DonorDashboard(),
      },
      initialRoute: '/',
    );
  }
}
