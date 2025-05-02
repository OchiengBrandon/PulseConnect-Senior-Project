import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if current user is a student
  bool get isStudent => _currentUser?.isStudent ?? false;

  // Check if current user is an institution
  bool get isInstitution => _currentUser?.isInstitution ?? false;

  // Check if current user is a researcher
  bool get isResearcher => _currentUser?.isResearcher ?? false;

  // Check if student is verified
  bool get isVerified => _currentUser?.isVerified ?? false;

  // Check if student verification is pending
  bool get isVerificationPending =>
      _currentUser?.isVerificationPending ?? false;

  // Initialize
  AuthProvider() {
    _init();
  }

  // Initialize and check if user is already logged in
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? institutionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        userType: userType,
        institutionId: institutionId,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to register';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      if (result.success && result.user != null) {
        _currentUser = result.user;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to login';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(email: email);

      if (result.success) {
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to reset password';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request institution verification for student
  Future<bool> requestInstitutionVerification({
    required String institutionId,
  }) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.requestInstitutionVerification(
        studentId: _currentUser!.id,
        institutionId: institutionId,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to request verification';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify student (for institutions)
  Future<bool> verifyStudent({
    required String studentId,
    required bool approve,
  }) async {
    if (_currentUser == null || !isInstitution) {
      _error = 'Only institutions can verify students';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyStudent(
        studentId: studentId,
        institutionId: _currentUser!.id,
        approve: approve,
      );

      if (result.success) {
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to verify student';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        profileImageUrl: profileImageUrl,
        additionalData: additionalData,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh user data
  Future<bool> refreshUserData() async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.getCurrentUserData();

      if (updatedUser != null) {
        _currentUser = updatedUser;
        return true;
      } else {
        _error = 'Failed to refresh user data';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user email
  Future<bool> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.updateEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to update email';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to update password';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user account
  Future<bool> deleteAccount({required String currentPassword}) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.deleteAccount(
        currentPassword: currentPassword,
      );

      if (result.success) {
        _currentUser = null;
        return true;
      } else {
        _error = result.errorMessage ?? 'Failed to delete account';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get institutions list
  Future<List<Map<String, dynamic>>> getInstitutions() async {
    // Remove the initial notifyListeners() call that was causing the problem
    try {
      final result = await _authService.getInstitutions();
      return result;
    } catch (e) {
      _error = e.toString();
      // Don't call notifyListeners() here either
      return [];
    }
  }

  // Get students pending verification for an institution
  Future<List<UserModel>> getPendingVerificationStudents() async {
    if (_currentUser == null || !isInstitution) {
      _error = 'Only authenticated institutions can access this information';
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.getPendingVerificationStudents(
        institutionId: _currentUser!.id,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
