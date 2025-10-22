import 'package:cloud_firestore/cloud_firestore.dart';

enum PetTaskType {
  vaccine('Vacina'),
  medication('Medicamento'),
  grooming('Banho/Tosa'),
  vet('Veterinário'),
  exercise('Exercício'),
  feeding('Alimentação'),
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
  final PetTaskType type;
  final String title;
  final DateTime? dueDate;
  final String? notes;
  final String createdBy;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetTask({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    this.dueDate,
    this.notes,
    required this.createdBy,
    this.done = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Verifica se a tarefa está vencida
  bool get isOverdue {
    if (dueDate == null) return false;
    return !done && dueDate!.isBefore(DateTime.now());
  }

  // Verifica se a tarefa está próxima do vencimento (7 dias)
  bool get isDueSoon {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final daysUntilDue = dueDate!.difference(now).inDays;
    return !done && daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  // Retorna o status da tarefa
  String get status {
    if (done) return 'Concluída';
    if (isOverdue) return 'Vencida';
    if (isDueSoon) return 'Próxima do vencimento';
    return 'Pendente';
  }

  // Converte PetTask para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'type': type.name,
      'title': title,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'createdBy': createdBy,
      'done': done,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Cria PetTask a partir de Map (do Firestore)
  factory PetTask.fromMap(Map<String, dynamic> map) {
    return PetTask(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      type: PetTaskType.fromString(map['type'] ?? 'other'),
      title: map['title'] ?? '',
      dueDate: map['dueDate'] != null 
          ? (map['dueDate'] as Timestamp).toDate() 
          : null,
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      done: map['done'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Cria cópia do PetTask com campos alterados
  PetTask copyWith({
    String? id,
    String? petId,
    PetTaskType? type,
    String? title,
    DateTime? dueDate,
    String? notes,
    String? createdBy,
    bool? done,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetTask(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PetTask(id: $id, petId: $petId, type: $type, title: $title, dueDate: $dueDate, notes: $notes, createdBy: $createdBy, done: $done, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetTask &&
        other.id == id &&
        other.petId == petId &&
        other.type == type &&
        other.title == title &&
        other.dueDate == dueDate &&
        other.notes == notes &&
        other.createdBy == createdBy &&
        other.done == done &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        petId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        dueDate.hashCode ^
        notes.hashCode ^
        createdBy.hashCode ^
        done.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
