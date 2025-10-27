import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction.dart';
import '../models/donation.dart';
import '../models/donor.dart';
import '../models/patient.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Platform stats
  Stream<Map<String, dynamic>> getPlatformStats() {
    return _firestore.collection('stats').doc('platform').snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  // Get detailed stats
  Stream<Map<String, dynamic>> getDetailedStats() {
    return _firestore.collection('stats').doc('detailed').snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  // Get active auctions
  Stream<List<Auction>> getActiveAuctions() {
    return _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Auction> auctions = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Get bid history (kept as raw maps inside auction model if needed)
        final bids = await _firestore
            .collection('auctions')
            .doc(doc.id)
            .collection('bids')
            .orderBy('timestamp', descending: true)
            .get();
        data['bids'] = bids.docs.map((bid) => bid.data()).toList();
        auctions.add(Auction.fromFirestore(data, id: doc.id));
      }
      return auctions;
    });
  }

  // Get all auctions
  Future<List<Auction>> getAuctions() async {
    final snapshot = await _firestore.collection('auctions').get();
    return snapshot.docs.map((doc) => Auction.fromFirestore(doc.data(), id: doc.id)).toList();
  }

  // Get a single auction
  Future<Auction> getAuction(String id) async {
    final doc = await _firestore.collection('auctions').doc(id).get();
    return Auction.fromFirestore(doc.data() ?? {}, id: doc.id);
  }

  // Add auction
  Future<void> addAuction(String itemName, double startingBid) async {
    await _firestore.collection('auctions').add({
      'itemName': itemName,
      'description': '',
      'imageUrl': '',
      'targetBid': startingBid * 2,
      'startingBid': startingBid,
      'currentBid': startingBid,
      'bidCount': 0,
      'startTime': DateTime.now(),
      'endTime': DateTime.now().add(const Duration(days: 7)),
      'status': 'active',
      'createdAt': DateTime.now(),
      'sellerId': 'admin',
    });
  }

  // Get donor's donations
  Future<List<Donation>> getDonorDonations(String donorId) async {
    final snapshot = await _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .get();
    return snapshot.docs.map((doc) => Donation.fromFirestore(doc.data(), id: doc.id)).toList();
  }

  // Get donor profile
  Future<Donor> getDonor(String donorId) async {
    final doc = await _firestore.collection('donors').doc(donorId).get();
    return Donor.fromFirestore(doc.data() ?? {}, id: doc.id);
  }

  // Get admin patients
  Stream<List<Patient>> getAdminPatients() {
    return _firestore.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Patient.fromFirestore(doc.data(), id: doc.id, isPublic: false)).toList();
    });
  }

  // Get public patients
  Future<List<Patient>> getPublicPatientsAsFuture() async {
    final snapshot = await _firestore
        .collection('patients')
        .where('isPublic', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Patient.fromFirestore(doc.data(), id: doc.id, isPublic: true)).toList();
  }

  // Get retention metrics
  Future<Map<String, dynamic>> getRetentionMetrics() async {
    final doc = await _firestore.collection('metrics').doc('retention').get();
    return doc.data() ?? {};
  }

  // Get donor profile stream
  Stream<Donor> getDonorProfileStream(String userId) {
    return _firestore
        .collection('donors')
        .doc(userId)
        .snapshots()
        .map((doc) => Donor.fromFirestore(doc.data() ?? {}, id: doc.id));
  }

  // Get public patients with filtering
  Stream<List<Patient>> getPublicPatients({
    int? limit,
    String? lastPatientId,
    String? searchQuery,
  }) {
    var query = _firestore
        .collection('patients')
        .where('isPublic', isEqualTo: true)
        .orderBy('priority', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (lastPatientId != null) {
      query = query.startAfter([lastPatientId]);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Patient.fromFirestore(data, id: doc.id, isPublic: true);
      }).toList();
    });
  }

  // Get user donations with pagination
  Stream<List<Donation>> getUserDonations(String userId, {
    int? limit,
    DateTime? lastDonationDate,
  }) {
    var query = _firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (lastDonationDate != null) {
      query = query.startAfter([Timestamp.fromDate(lastDonationDate)]);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Donation.fromFirestore(data, id: doc.id);
      }).toList();
    });
  }
}