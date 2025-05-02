import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';
import 'firebase_service.dart';

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? errorMessage;

  AuthResult({required this.success, this.user, this.errorMessage});

  factory AuthResult.success(UserModel user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.error(String errorMessage) {
    return AuthResult(success: false, errorMessage: errorMessage);
  }
}

/// A service class that handles user authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Check if a user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Get the current user's ID
  String? get userId => currentUser?.uid;

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? institutionId,
  }) async {
    try {
      // Validate email and password
      if (email.isEmpty || !email.contains('@')) {
        return AuthResult.error(ErrorMessages.invalidEmail);
      }

      if (password.length < 6) {
        return AuthResult.error(ErrorMessages.invalidPassword);
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult.error(ErrorMessages.defaultError);
      }

      final user = userCredential.user!;

      // Set display name
      await user.updateDisplayName(name);

      // Determine verification status for students
      String? verificationStatus;
      if (userType == UserType.student) {
        if (institutionId != null) {
          // Check if institution exists
          final institutionDoc =
              await _firestore
                  .collection(Collections.institutions)
                  .doc(institutionId)
                  .get();

          if (institutionDoc.exists) {
            // Get institution domains
            final institutionData = institutionDoc.data();
            final domains = institutionData?['domains'] as List<dynamic>?;

            // Check if student email domain matches institution domains
            if (domains != null && domains.isNotEmpty) {
              final studentDomain = email.split('@').last.toLowerCase();
              if (domains.any(
                (domain) => domain.toLowerCase() == studentDomain,
              )) {
                verificationStatus = VerificationStatus.verified;
              } else {
                verificationStatus = VerificationStatus.pending;
              }
            } else {
              verificationStatus = VerificationStatus.pending;
            }
          } else {
            return AuthResult.error('Institution not found.');
          }
        } else {
          verificationStatus = VerificationStatus.pending;
        }
      }

      // Create user document in Firestore
      final userData = UserModel(
        id: user.uid,
        email: email,
        name: name,
        userType: userType,
        institutionId: userType == UserType.student ? institutionId : null,
        verificationStatus: verificationStatus,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection(Collections.users)
          .doc(user.uid)
          .set(userData.toJson());

      return AuthResult.success(userData);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = ErrorMessages.emailAlreadyInUse;
          break;
        case 'invalid-email':
          errorMessage = ErrorMessages.invalidEmail;
          break;
        case 'weak-password':
          errorMessage = ErrorMessages.invalidPassword;
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }

      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate email and password
      if (email.isEmpty || !email.contains('@')) {
        return AuthResult.error(ErrorMessages.invalidEmail);
      }

      if (password.isEmpty) {
        return AuthResult.error(ErrorMessages.invalidPassword);
      }

      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult.error(ErrorMessages.defaultError);
      }

      final user = userCredential.user!;

      // Update last login time
      await _firestore.collection(Collections.users).doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Get user data
      final userDoc =
          await _firestore.collection(Collections.users).doc(user.uid).get();

      if (!userDoc.exists) {
        return AuthResult.error('User data not found.');
      }

      final userData = UserModel.fromJson({'id': user.uid, ...userDoc.data()!});

      return AuthResult.success(userData);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = ErrorMessages.userNotFound;
          break;
        case 'wrong-password':
          errorMessage = ErrorMessages.wrongPassword;
          break;
        case 'invalid-email':
          errorMessage = ErrorMessages.invalidEmail;
          break;
        case 'user-disabled':
          errorMessage = ErrorMessages.accountDisabled;
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }

      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      // Validate email
      if (email.isEmpty || !email.contains('@')) {
        return AuthResult.error(ErrorMessages.invalidEmail);
      }

      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = ErrorMessages.userNotFound;
          break;
        case 'invalid-email':
          errorMessage = ErrorMessages.invalidEmail;
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }

      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) {
      return null;
    }

    try {
      final userDoc =
          await _firestore
              .collection(Collections.users)
              .doc(currentUser!.uid)
              .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson({'id': currentUser!.uid, ...userDoc.data()!});
    } catch (e) {
      return null;
    }
  }

  /// Request institution verification for student
  Future<AuthResult> requestInstitutionVerification({
    required String studentId,
    required String institutionId,
  }) async {
    try {
      // Check if student exists
      final studentDoc =
          await _firestore.collection(Collections.users).doc(studentId).get();

      if (!studentDoc.exists) {
        return AuthResult.error('Student not found.');
      }

      final studentData = studentDoc.data();
      if (studentData?['userType'] != UserType.student) {
        return AuthResult.error('User is not a student.');
      }

      // Check if institution exists
      final institutionDoc =
          await _firestore
              .collection(Collections.institutions)
              .doc(institutionId)
              .get();

      if (!institutionDoc.exists) {
        return AuthResult.error('Institution not found.');
      }

      // Update student verification status
      await _firestore.collection(Collections.users).doc(studentId).update({
        'institutionId': institutionId,
        'verificationStatus': VerificationStatus.pending,
      });

      // Get updated student data
      final updatedStudentDoc =
          await _firestore.collection(Collections.users).doc(studentId).get();

      return AuthResult.success(
        UserModel.fromJson({'id': studentId, ...updatedStudentDoc.data()!}),
      );
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  //Update user profile
  Future<AuthResult> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Check if the user exists
      final userDoc =
          await _firestore.collection(Collections.users).doc(userId).get();

      if (!userDoc.exists) {
        return AuthResult.error('User not found.');
      }

      // Create a map of updates
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (additionalData != null) updates['additionalData'] = additionalData;

      // If no updates were provided, return early
      if (updates.isEmpty) {
        // Get current user data and return it
        final currentUser = UserModel.fromJson({
          'id': userId,
          ...userDoc.data()!,
        });
        return AuthResult.success(currentUser);
      }

      // Update user document in Firestore
      await _firestore
          .collection(Collections.users)
          .doc(userId)
          .update(updates);

      // Get updated user data
      final updatedUserDoc =
          await _firestore.collection(Collections.users).doc(userId).get();

      // Create updated user model
      final updatedUser = UserModel.fromJson({
        'id': userId,
        ...updatedUserDoc.data()!,
      });

      // If the current user is updating their own profile, update display name in Firebase Auth
      if (userId == currentUser?.uid && name != null) {
        await currentUser?.updateDisplayName(name);
      }

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Update user email
  ///
  /// This method allows a user to update their email address.
  /// It requires the current password for verification.
  Future<AuthResult> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.error('User not authenticated.');
      }

      // Validate email
      if (newEmail.isEmpty || !newEmail.contains('@')) {
        return AuthResult.error(ErrorMessages.invalidEmail);
      }

      // Re-authenticate user before changing email
      try {
        // Get user's current email
        final userEmail = currentUser!.email;
        if (userEmail == null) {
          return AuthResult.error('Current user email not available.');
        }

        // Create credential
        final credential = EmailAuthProvider.credential(
          email: userEmail,
          password: currentPassword,
        );

        // Re-authenticate
        await currentUser!.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = ErrorMessages.wrongPassword;
            break;
          default:
            errorMessage = e.message ?? ErrorMessages.defaultError;
        }
        return AuthResult.error(errorMessage);
      }

      // Update email
      await currentUser!.updateEmail(newEmail);

      // Update email in Firestore
      await _firestore
          .collection(Collections.users)
          .doc(currentUser!.uid)
          .update({'email': newEmail});

      // Get updated user data
      final updatedUser = await getCurrentUserData();

      if (updatedUser == null) {
        return AuthResult.error('Failed to get updated user data.');
      }

      return AuthResult.success(updatedUser);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = ErrorMessages.emailAlreadyInUse;
          break;
        case 'invalid-email':
          errorMessage = ErrorMessages.invalidEmail;
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again before updating your email.';
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }
      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Update user password
  ///
  /// This method allows a user to update their password.
  /// It requires the current password for verification.
  Future<AuthResult> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.error('User not authenticated.');
      }

      // Validate password
      if (newPassword.length < 6) {
        return AuthResult.error(ErrorMessages.invalidPassword);
      }

      // Re-authenticate user before changing password
      try {
        // Get user's current email
        final userEmail = currentUser!.email;
        if (userEmail == null) {
          return AuthResult.error('Current user email not available.');
        }

        // Create credential
        final credential = EmailAuthProvider.credential(
          email: userEmail,
          password: currentPassword,
        );

        // Re-authenticate
        await currentUser!.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = ErrorMessages.wrongPassword;
            break;
          default:
            errorMessage = e.message ?? ErrorMessages.defaultError;
        }
        return AuthResult.error(errorMessage);
      }

      // Update password
      await currentUser!.updatePassword(newPassword);

      // Get updated user data
      final updatedUser = await getCurrentUserData();

      if (updatedUser == null) {
        return AuthResult.error('Failed to get updated user data.');
      }

      return AuthResult.success(updatedUser);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = ErrorMessages.invalidPassword;
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again before updating your password.';
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }
      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Delete user account
  ///
  /// This method allows a user to delete their account.
  /// It requires the current password for verification.
  Future<AuthResult> deleteAccount({required String currentPassword}) async {
    try {
      if (currentUser == null) {
        return AuthResult.error('User not authenticated.');
      }

      // Re-authenticate user before deleting account
      try {
        // Get user's current email
        final userEmail = currentUser!.email;
        if (userEmail == null) {
          return AuthResult.error('Current user email not available.');
        }

        // Create credential
        final credential = EmailAuthProvider.credential(
          email: userEmail,
          password: currentPassword,
        );

        // Re-authenticate
        await currentUser!.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = ErrorMessages.wrongPassword;
            break;
          default:
            errorMessage = e.message ?? ErrorMessages.defaultError;
        }
        return AuthResult.error(errorMessage);
      }

      // Delete user document from Firestore
      await _firestore
          .collection(Collections.users)
          .doc(currentUser!.uid)
          .delete();

      // Delete user from Firebase Auth
      await currentUser!.delete();

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Please log in again before deleting your account.';
          break;
        default:
          errorMessage = e.message ?? ErrorMessages.defaultError;
      }
      return AuthResult.error(errorMessage);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Get institutions list
  ///
  /// This method returns a list of all available institutions.
  Future<List<Map<String, dynamic>>> getInstitutions() async {
    try {
      final institutionsSnapshot =
          await _firestore.collection(Collections.institutions).get();

      return institutionsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get students pending verification for an institution
  ///
  /// This method returns a list of students pending verification for a specific institution.
  Future<List<UserModel>> getPendingVerificationStudents({
    required String institutionId,
  }) async {
    try {
      // Check if current user is an institution
      final currentUserData = await getCurrentUserData();
      if (currentUserData == null ||
          currentUserData.userType != UserType.institution ||
          currentUserData.id != institutionId) {
        return [];
      }

      // Get students with pending verification for this institution
      final studentsSnapshot =
          await _firestore
              .collection(Collections.users)
              .where('userType', isEqualTo: UserType.student)
              .where('institutionId', isEqualTo: institutionId)
              .where(
                'verificationStatus',
                isEqualTo: VerificationStatus.pending,
              )
              .get();

      return studentsSnapshot.docs
          .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Verify student (for institutions)
  Future<AuthResult> verifyStudent({
    required String studentId,
    required String institutionId,
    required bool approve,
  }) async {
    try {
      // Check if current user is an institution
      final currentUserData = await getCurrentUserData();
      if (currentUserData == null ||
          currentUserData.userType != UserType.institution) {
        return AuthResult.error('Only institutions can verify students.');
      }

      // Check if student exists
      final studentDoc =
          await _firestore.collection(Collections.users).doc(studentId).get();

      if (!studentDoc.exists) {
        return AuthResult.error('Student not found.');
      }

      final studentData = studentDoc.data();
      if (studentData?['userType'] != UserType.student) {
        return AuthResult.error('User is not a student.');
      }

      if (studentData?['institutionId'] != institutionId) {
        return AuthResult.error(
          'Student is not associated with this institution.',
        );
      }

      // Update student verification status
      await _firestore.collection(Collections.users).doc(studentId).update({
        'verificationStatus':
            approve ? VerificationStatus.verified : VerificationStatus.rejected,
      });

      // Get updated student data
      final updatedStudentDoc =
          await _firestore.collection(Collections.users).doc(studentId).get();

      return AuthResult.success(
        UserModel.fromJson({'id': studentId, ...updatedStudentDoc.data()!}),
      );
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }
}
