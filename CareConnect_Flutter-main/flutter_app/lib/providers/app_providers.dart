import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:careconnect/services/auth_service.dart';
import 'package:careconnect/services/firestore_service.dart';
import 'package:careconnect/services/api_service.dart';
import 'package:careconnect/services/blockchain_service.dart';

// Auth provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// API provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Blockchain provider
final blockchainServiceProvider = Provider<BlockchainService>((ref) => BlockchainService());

// Auth state provider
final authStateProvider = StreamProvider((ref) {
  return ref.read(authServiceProvider).authStateChanges();
});

// Current user provider
final currentUserProvider = FutureProvider((ref) {
  return ref.read(authServiceProvider).getCurrentUser();
});