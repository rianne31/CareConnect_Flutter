import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/donation.dart';
import '../../models/patient.dart';
import '../../utils/formatters.dart';
import 'patients_list_screen.dart';
import 'donation_history_screen.dart';
import 'donor_profile_screen.dart';
import 'auctions_screen.dart';
import 'ai_chatbot_screen.dart';
import 'patient_detail_screen.dart'; // Added missing import

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({Key? key}) : super(key: key);

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DonorHomeScreen(),
    const PatientsListScreen(),
    const AuctionsScreen(),
    const DonationHistoryScreen(),
    const DonorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIChatbotScreen(),
            ),
          );
        },
        child: const Icon(Icons.smart_toy),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Auctions',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService.getDonor(user!.uid),
                builder: (context, snapshot) {
                  final donor = snapshot.data;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${donor?['name'] ?? 'Donor'}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thank you for supporting children battling cancer',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Donor Stats
              FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService.getDonor(user.uid),
                builder: (context, snapshot) {
                  final donor = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Donated',
                          value: Formatters.formatCurrency(donor?['totalDonated'] ?? 0),
                          icon: Icons.volunteer_activism,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Loyalty Tier',
                          value: donor?['loyaltyTier'] ?? 'Bronze',
                          icon: Icons.stars,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Featured Patients
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Patients',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to patients list
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Patient>>(
                future: _firestoreService.getPublicPatients(limit: 3),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No patients available'),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((patient) {
                      return _PatientCard(patient: patient);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Donations
              Text(
                'Recent Donations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Donation>>(
                future: _firestoreService.getDonorDonations(user.uid, limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No donations yet'),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((donation) {
                      return _DonationCard(donation: donation);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(patient: patient),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: Text(
                  patient.publicAlias[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.publicAlias,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.cancerType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: patient.fundingGoal > 0 
                          ? patient.currentFunding / patient.fundingGoal 
                          : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.formatCurrency(patient.currentFunding)} of ${Formatters.formatCurrency(patient.fundingGoal)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;

  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: donation.status == 'completed' 
              ? Colors.green[100] 
              : Colors.orange[100],
          child: Icon(
            donation.status == 'completed' 
                ? Icons.check 
                : Icons.pending,
            color: donation.status == 'completed' 
                ? Colors.green 
                : Colors.orange,
          ),
        ),
        title: Text(
          Formatters.formatCurrency(donation.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${donation.paymentMethod.toUpperCase()} • ${Formatters.formatDate(donation.createdAt)}',
        ),
        trailing: Chip(
          label: Text(
            donation.status.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: donation.status == 'completed' 
              ? Colors.green[100] 
              : Colors.orange[100],
        ),
      ),
    );
  }
}
