// 📁 lib/core/validation/validators.dart
// 🎯 Sistema de Validação Centralizado
// ✅ Validações consistentes para toda a aplicação
// 📅 2025-05-23
// 👤 MusicSheet Pro Team
// 🔢 v1.0.0

import 'package:music_sheet_pro/core/exceptions/app_exception.dart';

/// Resultado de uma validação
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null,
        fieldErrors = const {};

  const ValidationResult.error(this.errorMessage, {this.fieldErrors = const {}})
      : isValid = false;

  /// Combina múltiplos resultados de validação
  static ValidationResult combine(List<ValidationResult> results) {
    final errors = <String, String>{};
    final messages = <String>[];

    for (final result in results) {
      if (!result.isValid) {
        if (result.errorMessage != null) {
          messages.add(result.errorMessage!);
        }
        errors.addAll(result.fieldErrors);
      }
    }

    if (errors.isEmpty && messages.isEmpty) {
      return const ValidationResult.success();
    }

    return ValidationResult.error(
      messages.join(', '),
      fieldErrors: errors,
    );
  }
}

/// Validadores para campos de música
class MusicValidators {
  /// Valida título da música
  static ValidationResult validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.error(
        'Título é obrigatório',
        fieldErrors: {'title': 'Título é obrigatório'},
      );
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return const ValidationResult.error(
        'Título deve ter pelo menos 2 caracteres',
        fieldErrors: {'title': 'Título deve ter pelo menos 2 caracteres'},
      );
    }

    if (trimmedValue.length > 100) {
      return const ValidationResult.error(
        'Título não pode ter mais de 100 caracteres',
        fieldErrors: {'title': 'Título não pode ter mais de 100 caracteres'},
      );
    }

    // Verificar caracteres especiais perigosos
    if (RegExp(r'''[<>&"']''').hasMatch(trimmedValue)) {
      return const ValidationResult.error(
        'Título contém caracteres não permitidos',
        fieldErrors: {'title': 'Título contém caracteres não permitidos'},
      );
    }

    return const ValidationResult.success();
  }

  /// Valida nome do artista
  static ValidationResult validateArtist(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.error(
        'Artista é obrigatório',
        fieldErrors: {'artist': 'Artista é obrigatório'},
      );
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 1) {
      return const ValidationResult.error(
        'Nome do artista é obrigatório',
        fieldErrors: {'artist': 'Nome do artista é obrigatório'},
      );
    }

    if (trimmedValue.length > 80) {
      return const ValidationResult.error(
        'Nome do artista não pode ter mais de 80 caracteres',
        fieldErrors: {'artist': 'Nome do artista muito longo'},
      );
    }

    return const ValidationResult.success();
  }

  /// Valida tags
  static ValidationResult validateTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return const ValidationResult.success(); // Tags são opcionais
    }

    if (tags.length > 10) {
      return const ValidationResult.error(
        'Máximo de 10 tags permitidas',
        fieldErrors: {'tags': 'Máximo de 10 tags'},
      );
    }

    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        return const ValidationResult.error(
          'Tags não podem estar vazias',
          fieldErrors: {'tags': 'Tags vazias não são permitidas'},
        );
      }

      if (tag.length > 20) {
        return ValidationResult.error(
          'Cada tag deve ter no máximo 20 caracteres',
          fieldErrors: {'tags': 'Tag muito longa: $tag'},
        );
      }
    }

    return const ValidationResult.success();
  }

  /// Valida uma música completa
  static ValidationResult validateMusic({
    required String? title,
    required String? artist,
    List<String>? tags,
  }) {
    final results = [
      validateTitle(title),
      validateArtist(artist),
      validateTags(tags),
    ];

    return ValidationResult.combine(results);
  }
}

/// Validadores para setlists
class SetlistValidators {
  /// Valida nome da setlist
  static ValidationResult validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.error(
        'Nome da setlist é obrigatório',
        fieldErrors: {'name': 'Nome é obrigatório'},
      );
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return const ValidationResult.error(
        'Nome deve ter pelo menos 2 caracteres',
        fieldErrors: {'name': 'Nome muito curto'},
      );
    }

    if (trimmedValue.length > 50) {
      return const ValidationResult.error(
        'Nome não pode ter mais de 50 caracteres',
        fieldErrors: {'name': 'Nome muito longo'},
      );
    }

    return const ValidationResult.success();
  }

  /// Valida descrição da setlist
  static ValidationResult validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.success(); // Descrição é opcional
    }

    if (value.length > 200) {
      return const ValidationResult.error(
        'Descrição não pode ter mais de 200 caracteres',
        fieldErrors: {'description': 'Descrição muito longa'},
      );
    }

    return const ValidationResult.success();
  }

  /// Valida setlist completa
  static ValidationResult validateSetlist({
    required String? name,
    String? description,
  }) {
    final results = [
      validateName(name),
      validateDescription(description),
    ];

    return ValidationResult.combine(results);
  }
}

/// Validadores para conteúdo musical
class ContentValidators {
  /// Valida texto de conteúdo (letras, cifras)
  static ValidationResult validateContentText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.error(
        'Conteúdo não pode estar vazio',
        fieldErrors: {'content': 'Conteúdo é obrigatório'},
      );
    }

    if (value.length > 10000) {
      return const ValidationResult.error(
        'Conteúdo muito longo (máximo 10.000 caracteres)',
        fieldErrors: {'content': 'Conteúdo muito extenso'},
      );
    }

    return const ValidationResult.success();
  }

  /// Valida caminho de arquivo
  static ValidationResult validateFilePath(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.error(
        'Caminho do arquivo é obrigatório',
        fieldErrors: {'filePath': 'Arquivo não selecionado'},
      );
    }

    // Verificar extensões permitidas
    final allowedExtensions = ['.pdf', '.png', '.jpg', '.jpeg'];
    final hasValidExtension = allowedExtensions.any(
      (ext) => value.toLowerCase().endsWith(ext),
    );

    if (!hasValidExtension) {
      return ValidationResult.error(
        'Formato de arquivo não suportado. Use: ${allowedExtensions.join(", ")}',
        fieldErrors: {'filePath': 'Formato não suportado'},
      );
    }

    return const ValidationResult.success();
  }
}

/// Mixin para adicionar validação automática a FormFields
mixin ValidationMixin {
  /// Converte ValidationResult para string (para FormField validator)
  String? validationResultToString(ValidationResult result) {
    return result.isValid ? null : result.errorMessage;
  }

  /// Cria um validator para TextFormField baseado em ValidationResult
  String? Function(String?) createValidator(
    ValidationResult Function(String?) validationFunction,
  ) {
    return (value) => validationResultToString(validationFunction(value));
  }
}

/// Utilitários para validação
class ValidationUtils {
  /// Sanitiza uma string removendo caracteres perigosos
  static String sanitizeString(String input) {
    return input.replaceAll(RegExp(r'[<>&"\' ']'), '').trim();
  }

  /// Valida se um email tem formato válido
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Converte lista de strings em tags válidas
  static List<String> parseTagsFromString(String tagsString) {
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Lança ValidationException se o resultado for inválido
  static void throwIfInvalid(ValidationResult result) {
    if (!result.isValid) {
      throw ValidationException(
        result.errorMessage ?? 'Erro de validação',
        fieldErrors: result.fieldErrors,
      );
    }
  }
}

/// Classe para validação em batch de múltiplos objetos
class BatchValidator {
  final List<ValidationResult> _results = [];

  /// Adiciona um resultado de validação
  void add(ValidationResult result) {
    _results.add(result);
  }

  /// Adiciona múltiplos resultados
  void addAll(List<ValidationResult> results) {
    _results.addAll(results);
  }

  /// Retorna o resultado combinado de todas as validações
  ValidationResult validate() {
    return ValidationResult.combine(_results);
  }

  /// Limpa todos os resultados
  void clear() {
    _results.clear();
  }

  /// Verifica se todas as validações passaram
  bool get isValid => _results.every((r) => r.isValid);

  /// Obtém todas as mensagens de erro
  List<String> get errorMessages {
    return _results
        .where((r) => !r.isValid && r.errorMessage != null)
        .map((r) => r.errorMessage!)
        .toList();
  }
}
