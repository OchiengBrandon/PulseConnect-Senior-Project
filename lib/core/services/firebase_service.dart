import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A service class that manages Firebase services.
class FirebaseService {
  // Static instances for easy access throughout the app
  static late FirebaseAuth auth;
  static late FirebaseFirestore firestore;
  static late FirebaseStorage storage;

  /// Initialize Firebase services.
  static Future<void> initialize() async {
    // Initialize Firebase services
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    storage = FirebaseStorage.instance;

    // Configure Firestore settings
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Get the current authenticated user.
  static User? get currentUser => auth.currentUser;

  /// Check if a user is currently authenticated.
  static bool get isAuthenticated => currentUser != null;

  /// Get the user ID of the current authenticated user.
  static String? get userId => currentUser?.uid;
}
