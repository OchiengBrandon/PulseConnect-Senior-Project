import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the application.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String userType; // student, institution, researcher
  final String? profileImageUrl;
  final String? institutionId; // only for students
  final String?
  verificationStatus; // pending, verified, rejected (for students)
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.profileImageUrl,
    this.institutionId,
    this.verificationStatus,
    this.lastLogin,
    this.additionalData,
  });

  /// Create a user model from JSON data.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      institutionId: json['institutionId'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      lastLogin:
          json['lastLogin'] != null
              ? (json['lastLogin'] as Timestamp).toDate()
              : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert user model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType,
      'profileImageUrl': profileImageUrl,
      'institutionId': institutionId,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'additionalData': additionalData,
    };
  }

  /// Create a copy of the user model with updated fields.
  UserModel copyWith({
    String? email,
    String? name,
    String? userType,
    String? profileImageUrl,
    String? institutionId,
    String? verificationStatus,
    DateTime? lastLogin,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      institutionId: institutionId ?? this.institutionId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Check if user is a student.
  bool get isStudent => userType == 'student';

  /// Check if user is an institution.
  bool get isInstitution => userType == 'institution';

  /// Check if user is a researcher.
  bool get isResearcher => userType == 'researcher';

  /// Check if student is verified.
  bool get isVerified => verificationStatus == 'verified';

  /// Check if student verification is pending.
  bool get isVerificationPending => verificationStatus == 'pending';
}
