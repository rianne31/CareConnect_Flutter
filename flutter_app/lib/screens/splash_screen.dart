import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (user) async {
        if (user != null) {
          // Check user role
          final role = await ref.read(authServiceProvider).getUserRole();
          if (!mounted) return;
          
          if (role == UserRole.admin) {
            Navigator.of(context).pushReplacementNamed('/admin-dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/donor-home');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/landing');
        }
      },
      loading: () {},
      error: (_, __) {
        Navigator.of(context).pushReplacementNamed('/landing');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF10B981),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'CareConnect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Blockchain-Powered Aid Platform',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
