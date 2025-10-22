import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  final String familyCode;
  final List<String> fcmTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.familyCode,
    this.fcmTokens = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Converte User para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'familyCode': familyCode,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Cria User a partir de Map (do Firestore)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      familyCode: map['familyCode'] ?? '',
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Cria cópia do User com campos alterados
  User copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? familyCode,
    List<String>? fcmTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      familyCode: familyCode ?? this.familyCode,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(uid: $uid, displayName: $displayName, email: $email, familyCode: $familyCode, fcmTokens: $fcmTokens, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.familyCode == familyCode &&
        other.fcmTokens == fcmTokens &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        familyCode.hashCode ^
        fcmTokens.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
