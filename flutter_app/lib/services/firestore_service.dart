import 'package:cloud_firestore/cloud_firestore.dart' hide Timestamp;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore show Timestamp;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/donation.dart';
import '../models/patient.dart';
import '../models/auction.dart';
import '../models/donor.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Helper method to safely handle Firestore operations for web compatibility
  Future<T> _safeFirestoreOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      // Handle Firebase exceptions in a web-compatible way
      debugPrint('Firestore operation error: $e');
      throw e; // Rethrow to be handled by the caller
    }
  }
  
  // Helper method to safely handle Firestore streams for web compatibility
  Stream<T> _safeFirestoreStream<T>(Stream<T> stream) {
    if (kIsWeb) {
      return stream.handleError((error) {
        debugPrint('Firestore stream error: $error');
        // Return empty data instead of throwing
        return;
      });
    }
    return stream;
  }

  // Donations
  Stream<List<Donation>> getUserDonations(String userId) {
    final stream = _firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donation.fromFirestore(doc.data()!, id: doc.id))
            .toList());
    
    return _safeFirestoreStream(stream);
  }

  Future<Donation> getDonation(String donationId) async {
    final result = await _safeFirestoreOperation(() async {
      final doc = await _firestore.collection('donations').doc(donationId).get();
      if (doc.exists && doc.data() != null) {
        return Donation.fromFirestore(doc.data()!, id: doc.id);
      }
      // Return empty donation instead of null
      return Donation.fromFirestore({
        'amount': 0,
        'donorId': '',
        'patientId': '',
        'createdAt': firestore.Timestamp.now(),
        'status': 'unknown'
      }, id: 'not_found');
    });
    
    return result ?? Donation.fromFirestore({
      'amount': 0,
      'donorId': '',
      'patientId': '',
      'createdAt': firestore.Timestamp.now(),
      'status': 'error'
    }, id: 'error');
  }

  // Patients (public view - de-identified)
  Stream<List<Patient>> getPublicPatients({int? limit}) {
    var query = _firestore
        .collection('public_patients')
        .orderBy('priority', descending: true);
        
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final stream = query
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data(), id: doc.id, isPublic: true))
            .toList());
    
    return _safeFirestoreStream(stream);
  }
  
  // Get donor by ID
  Future<Map<String, dynamic>?> getDonor(String userId) async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('donors').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        } else {
          return null;
        }
      });
    } catch (e) {
      print('Error getting donor: $e');
      return null;
    }
  }
  
  // Get donor profile
  Future<Donor?> getDonorProfile(String userId) async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('donors').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          return Donor.fromFirestore(doc.data()!, id: doc.id);
        }
        // Return default donor instead of null
        return Donor.fromFirestore({
          'displayName': 'Unknown Donor',
          'email': '',
          'totalDonated': 0,
          'donationCount': 0,
          'tier': 'Bronze',
          'createdAt': firestore.Timestamp.now(),
        }, id: userId);
      });
    } catch (e) {
      debugPrint('Error getting donor: $e');
      // Return default donor on error
      return Donor.fromFirestore({
        'displayName': 'Error',
        'email': '',
        'totalDonated': 0,
        'donationCount': 0,
        'tier': 'Bronze',
        'createdAt': firestore.Timestamp.now(),
      }, id: userId);
    }
  }
  
  // Get donor donations
  Future<List<Donation>> getDonorDonations(String userId, {int? limit}) async {
    try {
      return await _safeFirestoreOperation(() async {
        var query = _firestore
            .collection('donations')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true);
            
        if (limit != null) {
          query = query.limit(limit);
        }
        
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => Donation.fromFirestore(doc.data()!, id: doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting donor donations: $e');
      return [];
    }
  }
  
  // Get auctions
  Future<List<Auction>> getAuctions() async {
    try {
      return await _safeFirestoreOperation(() async {
        final snapshot = await _firestore
            .collection('auctions')
            .orderBy('endDate')
            .get();
        return snapshot.docs
            .map((doc) => Auction.fromFirestore(doc.data(), id: doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting auctions: $e');
      return [];
    }
  }

  Future<Patient> getPublicPatient(String patientId) async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('public_patients').doc(patientId).get();
        if (doc.exists) {
          return Patient.fromFirestore(doc.data()!, id: doc.id, isPublic: true);
        }
        // Return default patient instead of null
        return Patient.fromFirestore({
          'name': 'Not Found',
          'condition': 'Unknown',
          'fundingGoal': 0,
          'fundingReceived': 0,
          'createdAt': firestore.Timestamp.now(),
        }, id: 'not_found', isPublic: true);
      });
    } catch (e) {
      return Patient.fromFirestore({
        'name': 'Error',
        'condition': 'Error retrieving patient',
        'fundingGoal': 0,
        'fundingReceived': 0,
        'createdAt': firestore.Timestamp.now(),
      }, id: 'error', isPublic: true);
    }
  }

  // Patients (admin view - full data)
  Stream<List<Patient>> getAdminPatients() {
    final stream = _firestore
        .collection('patients')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data()!, id: doc.id, isPublic: false))
            .toList());
    
    return _safeFirestoreStream(stream);
  }

  Future<Patient> getAdminPatient(String patientId) async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('patients').doc(patientId).get();
        if (doc.exists) {
          return Patient.fromFirestore(doc.data()!, id: doc.id, isPublic: false);
        }
        // Return default patient instead of null
        return Patient.fromFirestore({
          'name': 'Not Found',
          'condition': 'Unknown',
          'fundingGoal': 0,
          'fundingReceived': 0,
          'createdAt': firestore.Timestamp.now(),
        }, id: 'not_found', isPublic: false);
      });
    } catch (e) {
      return Patient.fromFirestore({
        'name': 'Error',
        'condition': 'Error retrieving patient',
        'fundingGoal': 0,
        'fundingReceived': 0,
        'createdAt': firestore.Timestamp.now(),
      }, id: 'error', isPublic: false);
    }
  }

  // Auctions
  Stream<List<Auction>> getActiveAuctions() {
    final stream = _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .orderBy('endTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Auction.fromFirestore(doc.data(), id: doc.id))
            .toList());
    
    return _safeFirestoreStream(stream);
  }

  Future<Auction> getAuction(String auctionId) async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('auctions').doc(auctionId).get();
        if (doc.exists) {
          return Auction.fromFirestore(doc.data()!, id: doc.id);
        }
        // Return default auction instead of null
        return Auction.fromFirestore({
          'title': 'Not Found',
          'description': 'Auction not found',
          'startingBid': 0,
          'currentBid': 0,
          'endTime': firestore.Timestamp.now(),
          'status': 'unknown'
        }, id: 'not_found');
      });
    } catch (e) {
      return Auction.fromFirestore({
        'title': 'Error',
        'description': 'Error retrieving auction',
        'startingBid': 0,
        'currentBid': 0,
        'endTime': firestore.Timestamp.now(),
        'status': 'error'
      }, id: 'error');
    }
  }

  Stream<List<Auction>> getUserAuctions(String userId) {
    final stream = _firestore
        .collection('auctions')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Auction.fromFirestore(doc.data(), id: doc.id))
            .toList());
    
    return _safeFirestoreStream(stream);
  }

  // Platform statistics
  Stream<Map<String, dynamic>> getDetailedStats() {
    final stream = _firestore
        .collection('analytics')
        .doc('detailed_stats')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data() as Map<String, dynamic>;
          } else {
            return {
              'monthlyDonations': [],
              'donorGrowth': [],
              'impactMetrics': {
                'livesImpacted': 0,
                'communitiesServed': 0,
                'treatmentsProvided': 0
              }
            };
          }
        });
    
    return _safeFirestoreStream(stream);
  }

  Future<Map<String, dynamic>> getImpactStats() async {
    try {
      return await _safeFirestoreOperation(() async {
        final doc = await _firestore.collection('stats').doc('impact').get();
        if (doc.exists && doc.data() != null) {
          return doc.data()!;
        }
        return <String, dynamic>{};
      });
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  // Donor profile as stream
  Stream<Donor?> getDonorProfileStream(String userId) {
    final stream = _firestore
        .collection('donors')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? Donor.fromFirestore(doc.data()!, id: doc.id) : null);
    
    return _safeFirestoreStream(stream);
  }

  Future<void> updateDonorProfile(String userId, Map<String, dynamic> data) async {
    return _safeFirestoreOperation(() async {
      await _firestore.collection('donors').doc(userId).update(data);
    });
  }

  // Analytics
  Future<Map<String, dynamic>> getDonationAnalytics() async {
    try {
      return await _safeFirestoreOperation(() async {
        final snapshot = await _firestore.collection('analytics').doc('donations').get();
        return snapshot.data() ?? {};
      });
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getRetentionMetrics() async {
    try {
      return await _safeFirestoreOperation(() async {
        final snapshot = await _firestore.collection('analytics').doc('donor_retention').get();
        return snapshot.data() ?? {};
      });
    } catch (e) {
      return {};
    }
  }
  
  // Platform statistics
  Stream<Map<String, dynamic>> getPlatformStats() {
    final stream = _firestore
        .collection('analytics')
        .doc('platform_stats')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data() as Map<String, dynamic>;
          } else {
            return {
              'totalDonations': 0,
              'donorsCount': 0,
              'patientsHelped': 0,
              'successfulAuctions': 0
            };
          }
        });
    
    return _safeFirestoreStream(stream);
  }
  
  // Convert Stream to Future for compatibility with FutureBuilder
  Future<List<Patient>> getPublicPatientsAsFuture({int? limit}) async {
    try {
      return await _safeFirestoreOperation(() async {
        var query = _firestore
            .collection('public_patients')
            .orderBy('priority', descending: true);
            
        if (limit != null) {
          query = query.limit(limit);
        }
        
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data()!, id: doc.id, isPublic: true))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting public patients: $e');
      return [];
    }
  }
}
