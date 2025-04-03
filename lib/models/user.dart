import 'dart:convert';
import 'package:crypto/crypto.dart';

enum UserRole {
  admin,
  inspector,
}

class User {
  final int? id;
  final String username;
  final String passwordHash;
  final UserRole role;

  User({
    this.id,
    required this.username,
    required String password,
    required this.role,
  }) : passwordHash = _hashPassword(password);

  User.withHash({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  // Convert User to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role.toString().split('.').last,
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User.withHash(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.inspector,
    );
  }

  // Hash password with SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool verifyPassword(String password) {
    final hashedPassword = _hashPassword(password);
    return hashedPassword == passwordHash;
  }
}
