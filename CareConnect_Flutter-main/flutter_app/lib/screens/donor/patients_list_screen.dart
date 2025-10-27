import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/patient.dart';
import '../../models/patient.dart';
import '../../utils/formatters.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({Key? key}) : super(key: key);

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _filterPriority = 'All';

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red[400]!;
      case 'high':
        return Colors.orange[400]!;
      case 'general':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterPriority == 'All',
                      color: Colors.grey[400]!,
                      onSelected: () {
                        setState(() {
                          _filterPriority = 'All';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'Critical',
                      selected: _filterPriority == 'Critical',
                      color: _priorityColor('critical'),
                      onSelected: () {
                        setState(() {
                          _filterPriority = 'Critical';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'High',
                      selected: _filterPriority == 'High',
                      color: _priorityColor('high'),
                      onSelected: () {
                        setState(() {
                          _filterPriority = 'High';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'General',
                      selected: _filterPriority == 'General',
                      color: _priorityColor('general'),
                      onSelected: () {
                        setState(() {
                          _filterPriority = 'General';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Patient>>(
        future: _firestoreService.getPublicPatientsAsFuture(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No patients available'));
          }

          var patients = snapshot.data!;

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            patients = patients.where((patient) {
              return patient.publicAlias.toLowerCase().contains(_searchQuery) ||
                     patient.cancerType.toLowerCase().contains(_searchQuery);
            }).toList();
          }

          // Apply priority filter
          if (_filterPriority != 'All') {
            patients = patients.where((patient) {
              return patient.priorityLevel.toLowerCase() == _filterPriority.toLowerCase();
            }).toList();
          }

          // Sort: Critical → High → General → others
          patients.sort((a, b) {
            const priorityOrder = {'critical': 0, 'high': 1, 'general': 2};
            int aPriority = priorityOrder[a.priorityLevel] ?? 3;
            int bPriority = priorityOrder[b.priorityLevel] ?? 3;
            return aPriority.compareTo(bPriority);
          });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return _PatientCard(patient: patient, priorityColor: _priorityColor(patient.priorityLevel));
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.grey[200],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final Color priorityColor;

  const _PatientCard({required this.patient, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    final progress = patient.fundingGoal > 0 ? patient.currentFunding / patient.fundingGoal : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      patient.publicAlias[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.publicAlias,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              patient.cancerType,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${patient.priorityLevel[0].toUpperCase()}${patient.priorityLevel.substring(1)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: priorityColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                patient.story,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatCurrency(patient.currentFunding),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Goal: ${Formatters.formatCurrency(patient.fundingGoal)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% funded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
