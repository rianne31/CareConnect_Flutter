import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return UserRole.guest;
  return ref.watch(authServiceProvider).getUserRole();
});

enum UserRole { guest, donor, admin }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  // Get current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
  
  // Set user role
  Future<void> setUserRole(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    
    await _firestore.collection('users').doc(user.uid).set({
      'role': role.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure donor profile exists for this user
      await _ensureDonorProfileExists(credential.user!);
      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    [String? displayName]
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      final userName = displayName ?? email.split('@')[0];
      await credential.user?.updateDisplayName(userName);

      // Create donor profile
      await _firestore.collection('donors').doc(credential.user!.uid).set({
        'email': email,
        'displayName': userName,
        'totalDonated': 0,
        'donationCount': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
        'achievements': [],
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  // Register user with complete profile
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required int age,
    required String gender,
    required DateTime dateOfBirth,
    required String address,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName);

      // Create donor profile with extended information
      await _firestore.collection('donors').doc(credential.user!.uid).set({
        'email': email,
        'displayName': fullName,
        'phoneNumber': phoneNumber,
        'age': age,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'totalDonated': 0,
        'donationCount': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
        'achievements': [],
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role from custom claims
  Future<UserRole> getUserRole() async {
    final user = currentUser;
    if (user == null) return UserRole.guest;

    final idTokenResult = await user.getIdTokenResult();
    final claims = idTokenResult.claims;

    if (claims?['admin'] == true) {
      return UserRole.admin;
    } else {
      return UserRole.donor;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == UserRole.admin;
  }

  // Get ID token for API calls
  Future<String?> getIdToken() async {
    return await currentUser?.getIdToken();
  }

  // Ensure donor profile exists after authentication
  Future<void> _ensureDonorProfileExists(User user) async {
    try {
      final docRef = _firestore.collection('donors').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final displayName = user.displayName ?? (user.email != null ? user.email!.split('@')[0] : 'Donor');
        await docRef.set({
          'email': user.email ?? '',
          'displayName': displayName,
          'totalDonated': 0,
          'donationCount': 0,
          'tier': 'Bronze',
          'createdAt': FieldValue.serverTimestamp(),
          'achievements': [],
        });
      }
    } catch (_) {
      // Swallow errors to avoid blocking login; UI can handle missing data gracefully
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return 'Authentication error: ${e.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}
