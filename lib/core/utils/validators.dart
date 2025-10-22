class Validators {
  // Validação de email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }
  
  // Validação de senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }
  
  // Validação de nome
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    
    if (value.length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    return null;
  }
  
  // Validação de código da família
  static String? familyCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Código da família é obrigatório';
    }
    
    if (value.length < 6) {
      return 'Código deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }
  
  // Validação de nome do pet
  static String? petName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome do pet é obrigatório';
    }
    
    if (value.length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    return null;
  }
  
  // Validação de espécie
  static String? species(String? value) {
    if (value == null || value.isEmpty) {
      return 'Espécie é obrigatória';
    }
    
    return null;
  }
  
  // Validação de peso
  static String? weight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Peso é obrigatório';
    }
    
    final weight = double.tryParse(value.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      return 'Peso deve ser um número válido';
    }
    
    return null;
  }
  
  // Validação de título da tarefa
  static String? taskTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Título é obrigatório';
    }
    
    if (value.length < 3) {
      return 'Título deve ter pelo menos 3 caracteres';
    }
    
    return null;
  }
  
  // Validação de data
  static String? date(DateTime? value) {
    if (value == null) {
      return 'Data é obrigatória';
    }
    
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return 'Data não pode ser futura';
    }
    
    return null;
  }
  
  // Validação de data futura (para vacinas)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'Data é obrigatória';
    }
    
    final now = DateTime.now();
    if (value.isBefore(now.subtract(const Duration(days: 1)))) {
      return 'Data não pode ser muito antiga';
    }
    
    return null;
  }
}
