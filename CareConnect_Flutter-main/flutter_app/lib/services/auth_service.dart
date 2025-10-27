import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Get current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email
    Future<UserCredential> signUpWithEmail(String email, String password, String displayName) async {
    try {
        // Create user with email and password
        final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

        // Update display name
        await userCredential.user?.updateDisplayName(displayName);

        // Initialize user document in Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'email': email,
          'displayName': displayName,
          'role': UserRole.donor.toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return userCredential;
    } catch (e) {
      rethrow;
    }
  }

    // Register user with role
    Future<void> registerUser(String uid, UserRole role, {String? email, String? displayName}) async {
      try {
        await _firestore.collection('users').doc(uid).set({
          'role': role.toString(),
          if (email != null) 'email': email,
          if (displayName != null) 'displayName': displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        rethrow;
      }
    }
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Send phone verification
  Future<void> sendPhoneVerification() async {
    try {
      // Implement phone verification logic
    } catch (e) {
      rethrow;
    }
  }

  // Verify email
  Future<void> verifyEmail(String code) async {
    try {
      // Implement email verification code logic
    } catch (e) {
      rethrow;
    }
  }

  // Verify phone
  Future<void> verifyPhone(String code) async {
    try {
      // Implement phone verification code logic
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user role
  Future<UserRole> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return UserRole.undefined;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserRole.fromString(doc.data()?['role']);
    } catch (e) {
      return UserRole.undefined;
    }
  }

  // Set user role
  Future<void> setUserRole(UserRole role) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection('users').doc(user.uid).set({
        'role': role.toString(),
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}