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
        
        // Navigate after successful signup
        if (!mounted) return;
        
        // Navigate based on user role
        final role = await authService.getUserRole();
        if (!mounted) return;

        if (role == UserRole.admin) {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/donor-home');
        }
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Immediately navigate after successful login
        if (!mounted) return;
        
        // Navigate based on user role
        final role = await authService.getUserRole();
        if (!mounted) return;

        if (role == UserRole.admin) {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/donor-home');
        }
      }
      
      return; // Exit after navigation
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: 32,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.favorite,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CareConnect',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Display Name Field (only shown for sign up)
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Enter your name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'Sign Up' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot Password (only shown for sign in)
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Navigate to forgot password screen
                                Navigator.of(context).pushNamed('/forgot-password');
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 8),

                        // Navigate to Registration Screen
                        TextButton(
                          onPressed: () {
                            if (_isSignUp) {
                              // If already in sign up mode, switch back to sign in
                              setState(() {
                                _isSignUp = false;
                              });
                            } else {
                              // Navigate to the full registration screen
                              Navigator.of(context).pushNamed('/registration');
                            }
                          },
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Register',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),

                        // Back to Landing Page
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
