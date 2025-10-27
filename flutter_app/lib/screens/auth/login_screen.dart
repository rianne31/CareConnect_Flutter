import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      final role = await authService.getUserRole();

      if (role == UserRole.admin) {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/donor-home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: 32,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo and Title
                    Icon(Icons.favorite_rounded, size: 72, color: color.primary),
                    const SizedBox(height: 16),
                    Text(
                      'CareConnect',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: TextStyle(
                        fontSize: 16,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Name (Sign Up only)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: color.surfaceContainerLow,
                        ),
                        validator: (value) {
                          if (_isSignUp && (value == null || value.isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: color.surfaceContainerLow,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: color.surfaceContainerLow,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (_isSignUp && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _handleAuth,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isSignUp
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded),
                      label: Text(
                        _isSignUp ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password (Sign In only)
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: color.primary),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Switch Sign In / Sign Up
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : 'Don’t have an account? Sign Up',
                        style: TextStyle(color: color.primary),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Back to Landing Page
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Home'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
