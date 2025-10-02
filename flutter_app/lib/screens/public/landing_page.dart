import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../services/blockchain_service.dart';
import '../../utils/formatters.dart';
// import '../auth/login_screen.dart'; // Commented out missing file

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 768 && size.width <= 1024;
    final isMobile = size.width <= 768;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                Icon(Icons.favorite, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'CareConnect',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              if (!isMobile) ...[
                TextButton(
                  onPressed: () => _scrollToSection(0),
                  child: const Text('Home'),
                ),
                TextButton(
                  onPressed: () => _scrollToSection(1),
                  child: const Text('Impact'),
                ),
                TextButton(
                  onPressed: () => _scrollToSection(2),
                  child: const Text('Features'),
                ),
                TextButton(
                  onPressed: () => _scrollToSection(3),
                  child: const Text('Blockchain'),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: HeroSection(
              isDesktop: isDesktop,
              isTablet: isTablet,
              isMobile: isMobile,
            ),
          ),

          // Impact Dashboard
          SliverToBoxAdapter(
            child: ImpactDashboard(
              isDesktop: isDesktop,
              isTablet: isTablet,
              isMobile: isMobile,
            ),
          ),

          // Feature Showcase
          SliverToBoxAdapter(
            child: FeatureShowcase(
              isDesktop: isDesktop,
              isTablet: isTablet,
              isMobile: isMobile,
            ),
          ),

          // Blockchain Transparency
          SliverToBoxAdapter(
            child: BlockchainTransparency(
              isDesktop: isDesktop,
              isTablet: isTablet,
              isMobile: isMobile,
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Footer(isMobile: isMobile),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int section) {
    final position = section * 800.0;
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

// Hero Section Widget
class HeroSection extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;

  const HeroSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : (isTablet ? 48 : 80),
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          if (isDesktop || isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHeroContent(context),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: _buildImpactCounters(context, firestoreService),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildHeroContent(context),
                const SizedBox(height: 40),
                _buildImpactCounters(context, firestoreService),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Empowering Hope Through Blockchain',
          style: TextStyle(
            fontSize: isMobile ? 32 : (isTablet ? 40 : 56),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'CareConnect is a blockchain-powered platform connecting donors with pediatric cancer patients. Every donation is transparent, traceable, and makes a real difference.',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: Colors.white.withOpacity(0.9),
            height: 1.6,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login navigation
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const LoginScreen()),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start Donating'),
            ),
            OutlinedButton(
              onPressed: () {
                // TODO: Implement login navigation
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const LoginScreen()),
                // );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Browse Auctions'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactCounters(BuildContext context, FirestoreService firestoreService) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: firestoreService.getPlatformStats(),
      builder: (context, snapshot) {
        // Handle errors specifically for web platform
        if (snapshot.hasError) {
          print('Error in platform stats: ${snapshot.error}');
          // Return default stats on error
        }
        
        final stats = snapshot.data ?? {
          'totalDonations': 0,
          'totalDonors': 0,
          'patientsHelped': 0,
          'activeAuctions': 0,
        };

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildCounter(
                context,
                'Total Donations',
                CurrencyFormatter.formatPHP(stats['totalDonations'] ?? 0),
                Icons.attach_money,
              ),
              const Divider(color: Colors.white24, height: 32),
              _buildCounter(
                context,
                'Active Donors',
                '${stats['totalDonors'] ?? 0}',
                Icons.people,
              ),
              const Divider(color: Colors.white24, height: 32),
              _buildCounter(
                context,
                'Patients Helped',
                '${stats['patientsHelped'] ?? 0}',
                Icons.favorite,
              ),
              const Divider(color: Colors.white24, height: 32),
              _buildCounter(
                context,
                'Active Auctions',
                '${stats['activeAuctions'] ?? 0}',
                Icons.gavel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounter(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Impact Dashboard Widget
class ImpactDashboard extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;

  const ImpactDashboard({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : (isTablet ? 48 : 80),
        vertical: isMobile ? 60 : 80,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Our Impact',
            style: TextStyle(
              fontSize: isMobile ? 32 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Real-time statistics showing the difference we\'re making together',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          StreamBuilder<Map<String, dynamic>>(
            stream: firestoreService.getDetailedStats(),
            builder: (context, snapshot) {
              // Handle errors specifically for web platform
              if (snapshot.hasError) {
                print('Error in detailed stats: ${snapshot.error}');
                // Use default stats on error
                return _buildDetailedStatsContent(context, {
                  'monthlyDonations': 0,
                  'donationsByCategory': {'Medical': 0, 'Education': 0, 'Family': 0},
                  'donorRetention': 0.0,
                  'averageDonation': 0,
                });
              }
              
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = snapshot.data!;
              
              return Column(
                children: [
                  // Statistics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.5 : 1.8,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Raised',
                        CurrencyFormatter.formatPHP(stats['totalRaised'] ?? 0),
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        'This Month',
                        CurrencyFormatter.formatPHP(stats['monthlyDonations'] ?? 0),
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Avg Donation',
                        CurrencyFormatter.formatPHP(stats['avgDonation'] ?? 0),
                        Icons.show_chart,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        context,
                        'Success Rate',
                        '${stats['successRate'] ?? 0}%',
                        Icons.check_circle,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Success Stories
                  Text(
                    'Success Stories',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSuccessStories(context, stats['successStories'] ?? []),
                  
                  const SizedBox(height: 48),
                  
                  // Geographic Reach
                  Text(
                    'Geographic Reach',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildGeographicReach(context, stats['regions'] ?? []),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsContent(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      children: [
        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: isMobile ? 1.2 : 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Raised',
              CurrencyFormatter.formatPHP(stats['totalRaised'] ?? 0),
              Icons.trending_up,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'This Month',
              CurrencyFormatter.formatPHP(stats['monthlyDonations'] ?? 0),
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Avg Donation',
              CurrencyFormatter.formatPHP(stats['avgDonation'] ?? 0),
              Icons.show_chart,
              Colors.purple,
            ),
            _buildStatCard(
              context,
              'Success Rate',
              '${stats['successRate'] ?? 0}%',
              Icons.check_circle,
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 48),
        
        // Success Stories
        Text(
          'Success Stories',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        _buildSuccessStories(context, stats['successStories'] ?? []),
        
        const SizedBox(height: 48),
        
        // Geographic Reach
        Text(
          'Geographic Reach',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        _buildGeographicReach(context, stats['regions'] ?? []),
      ],
    );
  }

  Widget _buildSuccessStories(BuildContext context, List<dynamic> stories) {
    if (stories.isEmpty) {
      return const Text('No success stories yet. Be the first to make a difference!');
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Container(
            width: isMobile ? 280 : 350,
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story['patientName'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            story['location'] ?? '',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(
                    story['story'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Fully Funded',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeographicReach(BuildContext context, List<dynamic> regions) {
    if (regions.isEmpty) {
      return const Text('Expanding our reach across the Philippines...');
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: regions.map<Widget>((region) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${region['name']} (${region['count']})',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Feature Showcase Widget
class FeatureShowcase extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;

  const FeatureShowcase({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : (isTablet ? 48 : 80),
        vertical: isMobile ? 60 : 80,
      ),
      child: Column(
        children: [
          Text(
            'Platform Features',
            style: TextStyle(
              fontSize: isMobile ? 32 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Built with cutting-edge technology for maximum transparency and security',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            crossAxisSpacing: 32,
            mainAxisSpacing: 32,
            childAspectRatio: isMobile ? 2 : 1.2,
            children: [
              _buildFeatureCard(
                context,
                'Blockchain Transparency',
                'Every donation is recorded on the Polygon blockchain, ensuring complete transparency and traceability.',
                Icons.link,
                Colors.blue,
              ),
              _buildFeatureCard(
                context,
                'Secure Payments',
                'Multiple payment options including crypto (MATIC), PayMaya, and GCash with bank-level security.',
                Icons.security,
                Colors.green,
              ),
              _buildFeatureCard(
                context,
                'NFT Auctions',
                'Bid on physical items tokenized as NFTs, with all proceeds going directly to patients.',
                Icons.gavel,
                Colors.purple,
              ),
              _buildFeatureCard(
                context,
                'AI-Powered Matching',
                'Our AI chatbot helps match donors with patients based on their preferences and interests.',
                Icons.psychology,
                Colors.orange,
              ),
              _buildFeatureCard(
                context,
                'Loyalty Rewards',
                'Earn achievement NFTs and unlock exclusive benefits as you continue supporting patients.',
                Icons.emoji_events,
                Colors.amber,
              ),
              _buildFeatureCard(
                context,
                'Real-Time Impact',
                'Track your donations in real-time and see the direct impact you\'re making on patients\' lives.',
                Icons.insights,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Blockchain Transparency Widget
class BlockchainTransparency extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;

  const BlockchainTransparency({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final blockchainService = ref.watch(blockchainServiceProvider); // Commented out missing provider

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : (isTablet ? 48 : 80),
        vertical: isMobile ? 60 : 80,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Blockchain Transparency',
            style: TextStyle(
              fontSize: isMobile ? 32 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Live statistics from the Polygon blockchain',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FutureBuilder<Map<String, dynamic>>(
            future: Future.value({"transactions": 120, "verified": 98}), // Mock data until blockchain service is implemented
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = snapshot.data!;

              return Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: isMobile ? 3 : 1.5,
                    children: [
                      _buildBlockchainStat(
                        context,
                        'Total Transactions',
                        '${stats['totalTransactions'] ?? 0}',
                        Icons.receipt_long,
                      ),
                      _buildBlockchainStat(
                        context,
                        'Smart Contracts',
                        '${stats['contractCount'] ?? 3}',
                        Icons.description,
                      ),
                      _buildBlockchainStat(
                        context,
                        'Gas Saved',
                        '${stats['gasSaved'] ?? 0} MATIC',
                        Icons.savings,
                      ),
                      _buildBlockchainStat(
                        context,
                        'Network',
                        'Polygon',
                        Icons.hub,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Verification Tool
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Theme.of(context).primaryColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verify Any Transaction',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter a transaction hash to verify it on the Polygon blockchain',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Enter transaction hash (0x...)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Implement verification
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Verification feature coming soon!'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                              ),
                              child: const Text('Verify'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse('https://polygonscan.com/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View on PolygonScan'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Smart Contract Addresses
                  Text(
                    'Smart Contract Addresses',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContractAddress(
                    context,
                    'Donation Contract',
                    stats['donationContract'] ?? 'Not deployed',
                  ),
                  const SizedBox(height: 12),
                  _buildContractAddress(
                    context,
                    'Auction Contract',
                    stats['auctionContract'] ?? 'Not deployed',
                  ),
                  const SizedBox(height: 12),
                  _buildContractAddress(
                    context,
                    'Achievement NFT',
                    stats['achievementNFT'] ?? 'Not deployed',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContractAddress(BuildContext context, String name, String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Copy to clipboard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 20),
          ),
        ],
      ),
    );
  }
}

// Footer Widget
class Footer extends StatelessWidget {
  final bool isMobile;

  const Footer({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: 48,
      ),
      color: Colors.grey[900],
      child: Column(
        children: [
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAboutSection(context)),
                const SizedBox(width: 60),
                Expanded(child: _buildLinksSection(context)),
                const SizedBox(width: 60),
                Expanded(child: _buildContactSection(context)),
              ],
            )
          else
            Column(
              children: [
                _buildAboutSection(context),
                const SizedBox(height: 32),
                _buildLinksSection(context),
                const SizedBox(height: 32),
                _buildContactSection(context),
              ],
            ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          Text(
            '© 2025 CareConnect - Cancer Warrior Foundation. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'CareConnect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Empowering hope through blockchain technology. Supporting pediatric cancer patients across the Philippines.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink('About Us'),
        _buildFooterLink('How It Works'),
        _buildFooterLink('Success Stories'),
        _buildFooterLink('FAQ'),
        _buildFooterLink('Contact'),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildContactItem(Icons.email, 'info@careconnect.ph'),
        _buildContactItem(Icons.phone, '+63 123 456 7890'),
        _buildContactItem(Icons.location_on, 'Manila, Philippines'),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
