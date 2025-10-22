import 'package:cloud_firestore/cloud_firestore.dart';

enum PetSpecies {
  dog('Cachorro'),
  cat('Gato'),
  bird('Pássaro'),
  fish('Peixe'),
  rabbit('Coelho'),
  hamster('Hamster'),
  turtle('Tartaruga'),
  other('Outro');

  const PetSpecies(this.displayName);
  final String displayName;

  static PetSpecies fromString(String value) {
    return PetSpecies.values.firstWhere(
      (species) => species.name == value,
      orElse: () => PetSpecies.other,
    );
  }
}

class Pet {
  final String id;
  final String familyCode;
  final String name;
  final PetSpecies species;
  final DateTime birthDate;
  final double weightKg;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    required this.id,
    required this.familyCode,
    required this.name,
    required this.species,
    required this.birthDate,
    required this.weightKg,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calcula a idade do pet em anos
  int get ageInYears {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  // Calcula a idade do pet em meses
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) {
      months--;
    }
    return months;
  }

  // Retorna a idade formatada
  String get formattedAge {
    final years = ageInYears;
    final months = ageInMonths;
    
    if (years > 0) {
      return '$years ${years == 1 ? 'ano' : 'anos'}';
    } else if (months > 0) {
      return '$months ${months == 1 ? 'mês' : 'meses'}';
    } else {
      return 'Recém-nascido';
    }
  }

  // Converte Pet para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyCode': familyCode,
      'name': name,
      'species': species.name,
      'birthDate': Timestamp.fromDate(birthDate),
      'weightKg': weightKg,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Cria Pet a partir de Map (do Firestore)
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      familyCode: map['familyCode'] ?? '',
      name: map['name'] ?? '',
      species: PetSpecies.fromString(map['species'] ?? 'other'),
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      weightKg: (map['weightKg'] ?? 0.0).toDouble(),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Cria cópia do Pet com campos alterados
  Pet copyWith({
    String? id,
    String? familyCode,
    String? name,
    PetSpecies? species,
    DateTime? birthDate,
    double? weightKg,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      familyCode: familyCode ?? this.familyCode,
      name: name ?? this.name,
      species: species ?? this.species,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Pet(id: $id, familyCode: $familyCode, name: $name, species: $species, birthDate: $birthDate, weightKg: $weightKg, photoUrl: $photoUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet &&
        other.id == id &&
        other.familyCode == familyCode &&
        other.name == name &&
        other.species == species &&
        other.birthDate == birthDate &&
        other.weightKg == weightKg &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        familyCode.hashCode ^
        name.hashCode ^
        species.hashCode ^
        birthDate.hashCode ^
        weightKg.hashCode ^
        photoUrl.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
