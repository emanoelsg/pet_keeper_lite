// features/pet_tasks/models/pet_task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum PetTaskType {
  food('Alimentação'),
  medicine('Medicamento'),
  walk('Passeio'),
  grooming('Banho e Tosa'),
  vet('Veterinário'),
  other('Outro');

  const PetTaskType(this.displayName);
  final String displayName;

  static PetTaskType fromString(String value) {
    return PetTaskType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PetTaskType.other,
    );
  }
}

class PetTask {
  final String id;
  final String petId;
  final String familyCode;
  final PetTaskType type;
  final String title;
  final DateTime? dueDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool done;

  PetTask({
    required this.id,
    required this.petId,
    required this.familyCode,
    required this.type,
    required this.title,
    this.dueDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.done = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'familyCode': familyCode,
      'type': type.name,
      'title': title,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'done': done,
    };
  }

  factory PetTask.fromMap(Map<String, dynamic> map) {
    return PetTask(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      familyCode: map['familyCode'] ?? '',
      type: PetTaskType.fromString(map['type'] ?? 'other'),
      title: map['title'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      done: map['done'] ?? false,
    );
  }

  PetTask copyWith({
    String? id,
    String? petId,
    String? familyCode,
    PetTaskType? type,
    String? title,
    DateTime? dueDate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? done,
  }) {
    return PetTask(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      familyCode: familyCode ?? this.familyCode,
      type: type ?? this.type,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      done: done ?? this.done,
    );
  }

  @override
  String toString() {
    return 'PetTask(id: $id, petId: $petId, familyCode: $familyCode, type: $type, title: $title, dueDate: $dueDate, notes: $notes, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, done: $done)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetTask &&
        other.id == id &&
        other.petId == petId &&
        other.familyCode == familyCode &&
        other.type == type &&
        other.title == title &&
        other.dueDate == dueDate &&
        other.notes == notes &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.done == done;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        petId.hashCode ^
        familyCode.hashCode ^
        type.hashCode ^
        title.hashCode ^
        dueDate.hashCode ^
        notes.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        done.hashCode;
  }
}
