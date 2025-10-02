import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
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
  String _filterCancerType = 'All';

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
                      selected: _filterCancerType == 'All',
                      onSelected: () {
                        setState(() {
                          _filterCancerType = 'All';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'Leukemia',
                      selected: _filterCancerType == 'Leukemia',
                      onSelected: () {
                        setState(() {
                          _filterCancerType = 'Leukemia';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'Brain Tumor',
                      selected: _filterCancerType == 'Brain Tumor',
                      onSelected: () {
                        setState(() {
                          _filterCancerType = 'Brain Tumor';
                        });
                      },
                    ),
                    _FilterChip(
                      label: 'Lymphoma',
                      selected: _filterCancerType == 'Lymphoma',
                      onSelected: () {
                        setState(() {
                          _filterCancerType = 'Lymphoma';
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
        future: _firestoreService.getPublicPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No patients available'),
            );
          }

          var patients = snapshot.data!;

          // Apply filters
          if (_searchQuery.isNotEmpty) {
            patients = patients.where((patient) {
              return patient.publicAlias.toLowerCase().contains(_searchQuery) ||
                     patient.cancerType.toLowerCase().contains(_searchQuery);
            }).toList();
          }

          if (_filterCancerType != 'All') {
            patients = patients.where((patient) {
              return patient.cancerType == _filterCancerType;
            }).toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return _PatientCard(patient: patient);
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
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final progress = patient.fundingGoal > 0 
        ? patient.currentFunding / patient.fundingGoal 
        : 0.0;

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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      patient.status.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: patient.status == 'active' 
                        ? Colors.green[100] 
                        : Colors.grey[300],
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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
