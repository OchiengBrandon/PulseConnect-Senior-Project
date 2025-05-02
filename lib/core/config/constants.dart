/// App-wide constants

// Collection names
class Collections {
  static const String users = 'users';
  static const String institutions = 'institutions';
  static const String polls = 'polls';
  static const String responses = 'responses';
  static const String discussions = 'discussions';
}

// User types
class UserType {
  static const String student = 'student';
  static const String institution = 'institution';
  static const String researcher = 'researcher';
}

// Verification status
class VerificationStatus {
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String rejected = 'rejected';
}

// Poll types
class PollType {
  static const String public = 'public';
  static const String anonymous = 'anonymous';
  static const String institutional = 'institutional';
}

// Storage paths
class StoragePaths {
  static const String profileImages = 'profile_images';
  static const String institutionLogos = 'institution_logos';
  static const String pollAttachments = 'poll_attachments';
}

// Error messages
class ErrorMessages {
  static const String defaultError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPassword =
      'Password must be at least 6 characters.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String emailAlreadyInUse = 'This email is already in use.';
  static const String wrongPassword = 'Incorrect password.';
  static const String userNotFound = 'No user found with this email.';
  static const String accountDisabled = 'Your account has been disabled.';
  static const String verificationRequired = 'Please verify your email first.';
  static const String institutionVerificationRequired =
      'Your institution verification is pending.';
}

// Success messages
class SuccessMessages {
  static const String accountCreated = 'Account created successfully.';
  static const String loginSuccess = 'Logged in successfully.';
  static const String passwordReset = 'Password reset email sent.';
  static const String profileUpdated = 'Profile updated successfully.';
  static const String pollCreated = 'Poll created successfully.';
  static const String pollResponded = 'Your response has been recorded.';
  static const String verificationSent = 'Verification has been requested.';
}

// App defaults
class AppDefaults {
  static const int pollsPerPage = 10;
  static const int commentsPerPage = 20;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
}
