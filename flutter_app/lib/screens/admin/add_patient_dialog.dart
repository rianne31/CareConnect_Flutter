import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _medicalUrgencyController = TextEditingController();
  final _familySituationController = TextEditingController();
  int _priority = 5;
  bool _isLoading = false;
  bool _isAISuggesting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diagnosisController.dispose();
    _fundingGoalController.dispose();
    _medicalUrgencyController.dispose();
    _familySituationController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('patients').add({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'diagnosis': _diagnosisController.text.trim(),
        'fundingGoal': double.parse(_fundingGoalController.text),
        'currentFunding': 0,
        'priority': _priority,
        'medicalUrgency': _medicalUrgencyController.text.trim(),
        'familySituation': _familySituationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🧠 Mock AI Suggestion for Priority
  Future<void> _suggestPriorityAI() async {
    setState(() => _isAISuggesting = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate AI delay

    // Basic example: more urgency = higher priority
    final urgency = _medicalUrgencyController.text.toLowerCase();
    final family = _familySituationController.text.toLowerCase();

    int aiPriority = 5;
    if (urgency.contains('critical') ||
        urgency.contains('emergency') ||
        family.contains('low income')) {
      aiPriority = 9;
    } else if (urgency.contains('moderate') || family.contains('needs help')) {
      aiPriority = 7;
    } else {
      aiPriority = 4;
    }

    setState(() {
      _priority = aiPriority;
      _isAISuggesting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI suggested priority level: $aiPriority'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  /// 💬 Mock AI Auto-Fill
  Future<void> _autoFillAI() async {
    setState(() => _isAISuggesting = true);
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _diagnosisController.text =
          'Acute Lymphoblastic Leukemia (AI Suggested)';
      _medicalUrgencyController.text = 'Requires immediate chemotherapy';
      _familySituationController.text =
          'Single parent family with limited financial support';
      _isAISuggesting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI auto-filled sample data'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💙 Gradient Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF007BFF), Color(0xFF00BFA5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Add New Patient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🩺 Form Body
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Please enter patient name' : null,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                    prefixIcon:
                                        Icon(Icons.calendar_today_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (int.tryParse(v) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingMedium),
                              Expanded(
                                child: TextFormField(
                                  controller: _fundingGoalController,
                                  decoration: const InputDecoration(
                                    labelText: 'Funding Goal (₱)',
                                    prefixIcon:
                                        Icon(Icons.monetization_on_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (double.tryParse(v) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          TextFormField(
                            controller: _diagnosisController,
                            decoration: const InputDecoration(
                              labelText: 'Diagnosis',
                              prefixIcon: Icon(Icons.local_hospital_outlined),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          TextFormField(
                            controller: _medicalUrgencyController,
                            decoration: const InputDecoration(
                              labelText: 'Medical Urgency',
                              prefixIcon: Icon(Icons.warning_amber_rounded),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          TextFormField(
                            controller: _familySituationController,
                            decoration: const InputDecoration(
                              labelText: 'Family Situation',
                              prefixIcon: Icon(Icons.family_restroom_outlined),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          // AI Add-on Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isAISuggesting ? null : _autoFillAI,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('AI Auto-Fill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isAISuggesting ? null : _suggestPriorityAI,
                                  icon: const Icon(Icons.analytics_outlined),
                                  label: const Text('AI Suggest Priority'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSizes.paddingLarge),

                          // Priority Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Priority Level: $_priority',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Icon(Icons.priority_high,
                                  color: Colors.orangeAccent.shade700),
                            ],
                          ),
                          Slider(
                            value: _priority.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _priority.toString(),
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _priority = v.toInt()),
                          ),
                          const SizedBox(height: AppSizes.paddingLarge),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _savePatient,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Add Patient'),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
