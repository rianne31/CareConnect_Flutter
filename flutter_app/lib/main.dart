import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screens
import 'screens/admin/admin_dashboard.dart';
import 'screens/public/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/donor/donor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDjVjlcUKYUBb62x5-hMIRJUi5dRdvlxpY",
      authDomain: "careconnect-demo.firebaseapp.com",
      projectId: "careconnect-demo",
      storageBucket: "careconnect-demo.appspot.com",
      messagingSenderId: "468173045065",
      appId: "1:468173045065:web:1d4cd24b9b9d5511ccf9d0",
      measurementId: "G-R1CJ92RRPY"
    ),
  );
  runApp(const ProviderScope(child: CareConnectApp()));
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
