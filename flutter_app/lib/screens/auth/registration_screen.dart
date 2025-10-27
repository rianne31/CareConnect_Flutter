import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _selectedGender;
  UserRole? _selectedRole;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        final age = DateTime.now().difference(picked).inDays ~/ 365;
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms || _selectedRole == null) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the Terms & Conditions'), backgroundColor: Colors.red),
        );
      }
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      await authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender ?? 'Prefer not to say',
        dateOfBirth: _dateOfBirth ?? DateTime.now(),
        address: _addressController.text.trim(),
      );

      await authService.setUserRole(_selectedRole!);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        _selectedRole == UserRole.admin ? '/admin-dashboard' : '/donor-home',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFECF1F4), Color(0xFFE3ECF8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 40),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Column(
                          children: [
                            Icon(Icons.favorite, color: Theme.of(context).primaryColor, size: 60),
                            const SizedBox(height: 12),
                            Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Join CareConnect to make a difference.",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          decoration: _inputDecoration("Full Name", Icons.person_outline),
                          validator: (v) => v!.isEmpty ? "Please enter your name" : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email", Icons.email_outlined),
                          validator: (v) => v!.contains('@') ? null : "Enter valid email",
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration("Phone Number", Icons.phone_outlined),
                          validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                        ),
                        const SizedBox(height: 16),

                        // DOB + Age
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
                                  child: Text(
                                    _dateOfBirth == null
                                        ? "Select Date"
                                        : DateFormat('MM/dd/yyyy').format(_dateOfBirth!),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration("Age", Icons.cake_outlined),
                                validator: (v) => v!.isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Gender
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: _inputDecoration("Gender", Icons.people_outline),
                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                          validator: (v) => v == null ? "Select gender" : null,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: _inputDecoration("Address", Icons.home_outlined),
                          validator: (v) => v!.isEmpty ? "Enter address" : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              v!.length < 6 ? "Password must be at least 6 characters" : null,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _inputDecoration("Confirm Password", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (v) =>
                              v != _passwordController.text ? "Passwords do not match" : null,
                        ),
                        const SizedBox(height: 24),

                        // Role Selection
                        const Text("Select your role:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: const Text('Donor'),
                                value: UserRole.donor,
                                groupValue: _selectedRole,
                                onChanged: (v) => setState(() => _selectedRole = v),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: const Text('Admin'),
                                value: UserRole.admin,
                                groupValue: _selectedRole,
                                onChanged: (v) => setState(() => _selectedRole = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Terms
                        CheckboxListTile(
                          title: const Text('I accept the Terms & Conditions'),
                          value: _acceptTerms,
                          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),

                        // Register button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Create Account',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Back to Login
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            "Already have an account? Sign In",
                            style: TextStyle(color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
