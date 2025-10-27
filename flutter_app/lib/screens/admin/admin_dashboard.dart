import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import 'patients_management_screen.dart';
import 'auctions_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isAILoading = false;
  String _aiInsight = 'Tap to generate AI summary.';

  final List<Widget> _screens = [
    const AnalyticsScreen(),
    const PatientsManagementScreen(),
    const AuctionsManagementScreen(),
  ];

  // 🧠 Mock AI Summary Generator (can later connect to Gemini API)
  Future<void> _generateAIInsight() async {
    setState(() => _isAILoading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate AI delay

    setState(() {
      _aiInsight =
          '📊 AI Insight: High donation activity this week — consider highlighting urgent cases on the dashboard.';
      _isAILoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareConnect Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007BFF), Color(0xFF00BFA5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'AI Summary',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _isAILoading ? null : _generateAIInsight,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),

      // 🌈 Drawer Navigation
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF00BFA5)],
                  ),
                ),
                child: FutureBuilder(
                  future: authService.getCurrentUser(),
                  builder: (context, snapshot) {
                    final email = snapshot.data?.email ?? 'Admin';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.admin_panel_settings,
                              color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CareConnect Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 📂 Drawer Menu
              _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
              _drawerItem(Icons.people_alt_rounded, 'Patients Management', 1),
              _drawerItem(Icons.gavel_rounded, 'Auctions Management', 2),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Settings coming soon!'),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: () async {
                  await authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
            ],
          ),
        ),
      ),

      // 🧠 Body with AI Insights
      body: Column(
        children: [
          if (_isAILoading || _aiInsight.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isAILoading
                          ? 'AI is analyzing dashboard data...'
                          : _aiInsight,
                      style: TextStyle(
                        color: _isAILoading
                            ? Colors.grey.shade600
                            : Colors.blue.shade900,
                        fontStyle:
                            _isAILoading ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  if (_isAILoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),

      // 🔽 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_rounded),
            label: 'Auctions',
          ),
        ],
      ),
    );
  }

  // Reusable Drawer item builder
  Widget _drawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
