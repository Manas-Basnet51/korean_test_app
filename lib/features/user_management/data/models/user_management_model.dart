import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final bool isActive;
  final String createdAt;
  final String lastLoginAt;
  final bool isAdmin;
  
  UserManagementModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isAdmin,
  });
  
  factory UserManagementModel.fromFirestore(DocumentSnapshot doc, {bool? isAdmin}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserManagementModel(
      id: doc.id,
      email: data['email'] ?? 'Unknown',
      name: data['name'] ?? 'Unknown',
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? '',
      lastLoginAt: data['lastLoginAt'] ?? '',
      isAdmin: isAdmin ?? false,
    );
  }
  
  UserManagementModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    bool? isActive,
    String? createdAt,
    String? lastLoginAt,
    bool? isAdmin,
  }) {
    return UserManagementModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}