import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String? name; // Only for admin view
  final String anonymousId; // For public view
  final String publicAlias; // Public display name
  final int age;
  final String diagnosis;
  final String? generalDiagnosis; // De-identified for public
  final String cancerType; // Type of cancer
  final double fundingGoal;
  final double currentFunding;
  final double fundingProgress;
  final int priority;
  final String? impactStory;
  final String status; // Patient status (active, completed, etc.)
  final String story; // Patient story
  final DateTime diagnosisDate; // Date of diagnosis
  final String treatmentStage; // Current treatment stage
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    this.name,
    required this.anonymousId,
    required this.publicAlias,
    required this.age,
    required this.diagnosis,
    this.generalDiagnosis,
    required this.cancerType,
    required this.fundingGoal,
    required this.currentFunding,
    required this.fundingProgress,
    required this.priority,
    this.impactStory,
    required this.status,
    required this.story,
    required this.diagnosisDate,
    required this.treatmentStage,
    required this.createdAt,
    required this.updatedAt,
  });

  // Human-readable priority level used across UI/chatbot
  String get priorityLevel {
    if (priority >= 8) return 'critical';
    if (priority >= 5) return 'high';
    return 'general';
  }

  factory Patient.fromFirestore(Map<String, dynamic> data, {required String id, bool isPublic = true}) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      try {
        final d = v.toDate();
        if (d is DateTime) return d;
      } catch (_) {}
      return DateTime.now();
    }
    if (isPublic) {
      // De-identified public view
      return Patient(
        id: id,
        anonymousId: data['anonymousId'] ?? 'Patient #${id.substring(0, 8)}',
        publicAlias: data['publicAlias'] ?? 'Patient ${id.substring(0, 4)}',
        age: data['age'] ?? 0,
        diagnosis: '',
        generalDiagnosis: data['generalDiagnosis'] ?? '',
        cancerType: data['cancerType'] ?? 'Unspecified',
        fundingGoal: (data['fundingGoal'] ?? 0).toDouble(),
        currentFunding: (data['currentFunding'] ?? 0).toDouble(),
        fundingProgress: (data['fundingProgress'] ?? 0).toDouble(),
        priority: data['priority'] ?? 5,
        impactStory: data['impactStory'],
        status: data['status'] ?? 'active',
        story: data['story'] ?? '',
        diagnosisDate: _toDate(data['diagnosisDate']),
        treatmentStage: data['treatmentStage'] ?? 'Unknown',
        createdAt: _toDate(data['createdAt']),
        updatedAt: _toDate(data['updatedAt']),
      );
    } else {
      // Full admin view
      return Patient(
        id: id,
        name: data['name'],
        anonymousId: data['anonymousId'] ?? 'Patient #${id.substring(0, 8)}',
        publicAlias: data['publicAlias'] ?? 'Patient ${id.substring(0, 4)}',
        age: data['age'] ?? 0,
        diagnosis: data['diagnosis'] ?? '',
        generalDiagnosis: data['generalDiagnosis'],
        cancerType: data['cancerType'] ?? 'Unspecified',
        fundingGoal: (data['fundingGoal'] ?? 0).toDouble(),
        currentFunding: (data['currentFunding'] ?? 0).toDouble(),
        fundingProgress: (data['fundingProgress'] ?? 0).toDouble(),
        priority: data['priority'] ?? 5,
        impactStory: data['impactStory'],
        status: data['status'] ?? 'active',
        story: data['story'] ?? '',
        diagnosisDate: _toDate(data['diagnosisDate']),
        treatmentStage: data['treatmentStage'] ?? 'Unknown',
        createdAt: _toDate(data['createdAt']),
        updatedAt: _toDate(data['updatedAt']),
      );
    }
  }
}
