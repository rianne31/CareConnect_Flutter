// donor_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/donation.dart';
import '../../models/patient.dart';
import '../../models/donor.dart';
import '../../utils/formatters.dart';
import 'patients_list_screen.dart';
import 'donation_history_screen.dart';
import 'donor_profile_screen.dart';
import 'auctions_screen.dart';
import 'patient_detail_screen.dart';
import 'ai_chatbot_screen.dart'; // kept in case other navigation relies on it

// --- Theme colors (CareConnect hybrid) ---
const Color _rose = Color(0xFFFF6F91);
const Color _gold = Color(0xFFFFD166);
const Color _bg = Color(0xFFFFF8F9);

// --- Riverpod Providers for services (simple wrappers) ---
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class DonorDashboard extends ConsumerStatefulWidget {
  const DonorDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends ConsumerState<DonorDashboard> with TickerProviderStateMixin {
  late final PageController _pageController;
  int _selectedIndex = 0;

  // Place holder screens; keep existing screens but we still want FAB visible across all of them
  late final List<Widget> _pages;

  // subtle animation for top cards
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = const [
      DonorHomeScreen(), // we'll use the improved DonorHomeScreen below
      PatientsListScreen(),
      AuctionsScreen(),
      DonationHistoryScreen(),
      DonorProfileScreen(),
    ];

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openCareConnectBotModal({String? conversationId, Map<String, dynamic>? donorContext, String? auctionId, String? contextType}) {
    final convoId = conversationId ??
        (FirebaseAuth.instance.currentUser != null
            ? '${FirebaseAuth.instance.currentUser!.uid}_${auctionId ?? 'dashboard'}'
            : 'guest_${auctionId ?? 'dashboard'}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.85;
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.12), blurRadius: 12)],
            ),
            child: AiChatbotScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We'll use FirestoreService only for navigation-level actions; actual streams live inside the pages.
    final firestore = ref.read(firestoreServiceProvider);
    final auth = ref.read(authServiceProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      // keep the FAB visible across pages; opens with donor context when available
      floatingActionButton: FloatingActionButton(
        heroTag: 'careconnect_dashboard_fab',
        backgroundColor: _rose,
        onPressed: () async {
          // try to get donor data if available
          Donor? donorData;
          if (currentUser != null) {
            try {
              donorData = await firestore.getDonor(currentUser.uid);
            } catch (_) {
              donorData = null;
            }
          }
          _openCareConnectBotModal(
            conversationId: currentUser != null ? '${currentUser.uid}_dashboard' : null, 
            donorContext: donorData != null ? {
              'id': donorData.id,
              'email': donorData.email,
              'displayName': donorData.displayName,
              'totalDonated': donorData.totalDonated,
              'donationCount': donorData.donationCount,
              'tier': donorData.tierName,
            } : null, 
            contextType: 'donor_dashboard'
          );
        },
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Use a gradient app bar consistent across dashboard
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_rose, _gold], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 28, left: 18, right: 18),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Text('CareConnect', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      // implement notification route
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await auth.signOut();
                      if (mounted) Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _selectedIndex = idx),
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel), label: 'Auctions'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Improved DonorHomeScreen
/// Uses real-time streams for donor data, patients, and recent donations.
/// ---------------------------
class DonorHomeScreen extends ConsumerWidget {
  const DonorHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreServiceProvider);
    final user = FirebaseAuth.instance.currentUser;

    // Streams
    final donorStream = user != null ? firestore.getDonorProfileStream(user.uid) : Stream.value(null);
    final featuredPatientsStream = firestore.getPublicPatients();
    final recentDonationsStream = user != null ? firestore.getUserDonations(user.uid) : Stream.value(<Donation>[]);

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger widget rebuilds — streams are real-time anyway
          return Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + donor card (streamed)
              StreamBuilder<Donor?>(
                stream: donorStream,
                builder: (context, snap) {
                  final donor = snap.data;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _rose.withOpacity(0.12),
                            child: const Icon(Icons.volunteer_activism, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back, ${donor?.displayName ?? 'Donor'}!',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Thank you for supporting children battling cancer',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rose,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationHistoryScreen()));
                            },
                            icon: const Icon(Icons.history),
                            label: const Text('My Donations'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

             // Stats row (streamed)
             StreamBuilder<Donor?>(
               stream: donorStream,
               builder: (context, snap) {
                 final donor = snap.data;
                 return Row(
                   children: [
                     Expanded(child: _StatCard(title: 'Total Donated', value: Formatters.formatCurrency(donor?.totalDonated ?? 0), icon: Icons.volunteer_activism, color: Colors.green)),
                     const SizedBox(width: 12),
                     Expanded(child: _StatCard(title: 'Loyalty Tier', value: donor?.tierName ?? 'Bronze', icon: Icons.stars, color: Colors.amber)),
                   ],
                 );
               },
              ),

              const SizedBox(height: 20),

              // Featured Patients (stream)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured Patients', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen())), child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Patient>>(
                stream: featuredPatientsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final patients = snap.data ?? <Patient>[];
                  if (patients.isEmpty) {
                    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('No patients available', style: TextStyle(color: Colors.grey[700])))));
                  }
                  return Column(children: patients.map((p) => _PatientCard(patient: p)).toList());
                },
              ),

              const SizedBox(height: 20),

              // Recent Donations (stream)
              Text('Recent Donations', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              StreamBuilder<List<Donation>>(
                stream: recentDonationsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                  }
                  final donations = snap.data ?? <Donation>[];
                  if (donations.isEmpty) {
                    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('No donations yet', style: TextStyle(color: Colors.grey[700])))));
                  }
                  return Column(children: donations.map((d) => _DonationListTile(donation: d)).toList());
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- UI helper widgets (StatCard, PatientCard, DonationTile) ---
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: patient)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: _rose.withOpacity(0.12), child: Text(patient.publicAlias[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(patient.publicAlias, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(patient.cancerType, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: patient.fundingGoal > 0 ? (patient.currentFunding / patient.fundingGoal) : 0, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.green)),
                  const SizedBox(height: 6),
                  Text('${Formatters.formatCurrency(patient.currentFunding)} of ${Formatters.formatCurrency(patient.fundingGoal)}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationListTile extends StatelessWidget {
  final Donation donation;
  const _DonationListTile({required this.donation});

  Color _colorForStatus() {
    switch (donation.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForStatus() {
    switch (donation.status) {
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          // open donation detail
        },
        leading: CircleAvatar(
          backgroundColor: donation.status == 'completed' ? Colors.green[100] : Colors.orange[100],
          child: Icon(_iconForStatus(), color: _colorForStatus()),
        ),
        title: Text(Formatters.formatCurrency(donation.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${donation.paymentMethod.toUpperCase()} • ${Formatters.formatDate(donation.createdAt)}'),
        trailing: Chip(label: Text(donation.status.toUpperCase(), style: const TextStyle(fontSize: 10)), backgroundColor: donation.status == 'completed' ? Colors.green[100] : Colors.orange[100]),
      ),
    );
  }
}
