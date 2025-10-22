import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String familyCode;
  final String ownerUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Family({
    required this.familyCode,
    required this.ownerUid,
    required this.createdAt,
    required this.updatedAt,
  });

  // Converte Family para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'familyCode': familyCode,
      'ownerUid': ownerUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Cria Family a partir de Map (do Firestore)
  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      familyCode: map['familyCode'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Cria cópia do Family com campos alterados
  Family copyWith({
    String? familyCode,
    String? ownerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      familyCode: familyCode ?? this.familyCode,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Family(familyCode: $familyCode, ownerUid: $ownerUid, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Family &&
        other.familyCode == familyCode &&
        other.ownerUid == ownerUid &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return familyCode.hashCode ^
        ownerUid.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
