import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _handleRoleSelection() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.setUserRole(_selectedRole!);

      if (!mounted) return;

      if (_selectedRole == UserRole.admin) {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Your Role'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.primaryContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Your Role in CareConnect',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your role determines what you can do in the app.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  _buildAnimatedRoleCard(
                    title: 'Admin',
                    description: 'Manage campaigns, view analytics, and oversee donations.',
                    icon: Icons.admin_panel_settings,
                    isSelected: _selectedRole == UserRole.admin,
                    onTap: () => setState(() => _selectedRole = UserRole.admin),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildAnimatedRoleCard(
                    title: 'Donor',
                    description: 'Make donations and track your contributions.',
                    icon: Icons.volunteer_activism,
                    isSelected: _selectedRole == UserRole.donor,
                    onTap: () => setState(() => _selectedRole = UserRole.donor),
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleRoleSelection,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildAnimatedRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected ? Colors.white : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
