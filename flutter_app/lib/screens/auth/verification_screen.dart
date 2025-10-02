import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _verificationMethod = 'email'; // Default to email verification
  
  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      
      if (_verificationMethod == 'email') {
        await authService.sendEmailVerification();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await authService.sendPhoneVerification();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your phone.'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Future<void> _verifyCode() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      
      if (_verificationMethod == 'email') {
        await authService.verifyEmail(_otpController.text.trim());
      } else {
        await authService.verifyPhone(_otpController.text.trim());
      }
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to appropriate screen based on user role
      final role = await authService.getUserRole();
      if (!mounted) return;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  _verificationMethod == 'email' 
                      ? Icons.email_outlined 
                      : Icons.phone_android_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _verificationMethod == 'email'
                      ? 'Email Verification'
                      : 'Phone Verification',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  _verificationMethod == 'email'
                      ? 'We\'ve sent a verification code to your email address. Please check your inbox and enter the code below.'
                      : 'We\'ve sent a verification code to your phone number. Please enter the code below.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Verification Method Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email Option
                    Expanded(
                      child: _buildVerificationOption(
                        title: 'Email',
                        icon: Icons.email_outlined,
                        isSelected: _verificationMethod == 'email',
                        onTap: () {
                          setState(() {
                            _verificationMethod = 'email';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Phone Option
                    Expanded(
                      child: _buildVerificationOption(
                        title: 'Phone',
                        icon: Icons.phone_android_outlined,
                        isSelected: _verificationMethod == 'phone',
                        onTap: () {
                          setState(() {
                            _verificationMethod = 'phone';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // OTP Input Field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
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
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Resend Code Button
                TextButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}