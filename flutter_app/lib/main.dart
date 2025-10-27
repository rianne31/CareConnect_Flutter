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
  // Load environment variables before any services read dotenv.env
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD1EPDM3P61fcnnVoNFO_QJqvXv8_T0ii4",
      authDomain: "careconn-79a46.firebaseapp.com",
      projectId: "careconn-79a46",
      storageBucket: "careconn-79a46.firebasestorage.app",
      messagingSenderId: "708964854924",
      appId: "1:708964854924:web:fc236f641e053c51aa5fa9",
      measurementId: "G-ZWV2ES3FPC",
      databaseURL: "https://careconn-79a46.firebaseio.com"
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
