import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? externalTxId;
  final String? patientId;
  final bool isAnonymous;
  final String status;
  final String? blockchainTxHash;
  final String? transactionHash; // Added missing property
  final bool blockchainVerified; // Added missing property
  final DateTime createdAt;
  final DateTime? confirmedAt;

  Donation({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.externalTxId,
    this.patientId,
    required this.isAnonymous,
    required this.status,
    this.blockchainTxHash,
    this.transactionHash,
    required this.blockchainVerified,
    required this.createdAt,
    this.confirmedAt,
  });

  factory Donation.fromFirestore(Map<String, dynamic> data, {required String id}) {
    return Donation(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'PHP',
      paymentMethod: data['paymentMethod'] ?? '',
      externalTxId: data['externalTxId'],
      patientId: data['patientId'],
      isAnonymous: data['isAnonymous'] ?? false,
      status: data['status'] ?? 'pending',
      blockchainTxHash: data['blockchainTxHash'],
      transactionHash: data['transactionHash'],
      blockchainVerified: data['blockchainVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null 
          ? (data['confirmedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'externalTxId': externalTxId,
      'patientId': patientId,
      'isAnonymous': isAnonymous,
      'status': status,
      'blockchainTxHash': blockchainTxHash,
      'transactionHash': transactionHash,
      'blockchainVerified': blockchainVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt as DateTime) : null,
    };
  }
}
