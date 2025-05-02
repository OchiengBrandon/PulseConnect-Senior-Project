import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionModel {
  final String id;
  final String name;
  final String email;
  final String? logoUrl;
  final String? website;
  final String? description;
  final String? address;
  final String? phone;
  final List<String>? domains; // Email domains for auto-verification
  final DateTime createdAt;
  final Map<String, dynamic>? additionalData;

  InstitutionModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.logoUrl,
    this.website,
    this.description,
    this.address,
    this.phone,
    this.domains,
    this.additionalData,
  });

  /// Create an institution model from JSON data.
  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      logoUrl: json['logoUrl'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      domains:
          json['domains'] != null
              ? List<String>.from(json['domains'] as List)
              : null,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert institution model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'logoUrl': logoUrl,
      'website': website,
      'description': description,
      'address': address,
      'phone': phone,
      'domains': domains,
      'createdAt': createdAt,
      'additionalData': additionalData,
    };
  }

  /// Create a copy of the institution model with updated fields.
  InstitutionModel copyWith({
    String? name,
    String? email,
    String? logoUrl,
    String? website,
    String? description,
    String? address,
    String? phone,
    List<String>? domains,
    Map<String, dynamic>? additionalData,
  }) {
    return InstitutionModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      domains: domains ?? this.domains,
      createdAt: this.createdAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Check if an email domain belongs to this institution.
  bool hasEmailDomain(String email) {
    if (domains == null || domains!.isEmpty) {
      return false;
    }

    final emailDomain = email.split('@').last.toLowerCase();
    return domains!.any((domain) => domain.toLowerCase() == emailDomain);
  }
}
