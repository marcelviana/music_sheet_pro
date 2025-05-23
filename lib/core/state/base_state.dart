// 📁 lib/core/state/base_state.dart
// 🎯 Sistema de Estados Centralizado para toda a aplicação
// 🔄 Padroniza o gerenciamento de estados de loading, sucesso e erro
// 📅 2025-05-23
// 👤 MusicSheet Pro Team
// 🔢 v1.0.0
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum LoadingState {
  idle, // Estado inicial
  loading, // Carregando dados
  success, // Operação bem-sucedida
  error // Erro ocorreu
}

/// Estado base genérico que pode ser usado em qualquer tela
/// Padroniza o gerenciamento de loading, dados e erros
class BaseState<T> {
  final LoadingState status;
  final T? data;
  final String? errorMessage;
  final Exception? exception;
  final DateTime timestamp;

  BaseState({
    this.status = LoadingState.idle,
    this.data,
    this.errorMessage,
    this.exception,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.fromMicrosecondsSinceEpoch(0);

  /// Cria um estado de loading
  BaseState<T> copyWithLoading() {
    return BaseState<T>(
      status: LoadingState.loading,
      data: data, // Mantém dados anteriores durante loading
      timestamp: DateTime.now(),
    );
  }

  /// Cria um estado de sucesso com dados
  BaseState<T> copyWithSuccess(T newData) {
    return BaseState<T>(
      status: LoadingState.success,
      data: newData,
      timestamp: DateTime.now(),
    );
  }

  /// Cria um estado de erro
  BaseState<T> copyWithError(String message, [Exception? exception]) {
    return BaseState<T>(
      status: LoadingState.error,
      data: data, // Mantém dados anteriores em caso de erro
      errorMessage: message,
      exception: exception,
      timestamp: DateTime.now(),
    );
  }

  /// Verifica se está carregando
  bool get isLoading => status == LoadingState.loading;

  /// Verifica se tem dados válidos
  bool get hasData => data != null;

  /// Verifica se é um estado de sucesso
  bool get isSuccess => status == LoadingState.success;

  /// Verifica se é um estado de erro
  bool get isError => status == LoadingState.error;

  /// Verifica se está no estado inicial
  bool get isIdle => status == LoadingState.idle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseState<T> &&
        other.status == status &&
        other.data == data &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return status.hashCode ^ data.hashCode ^ errorMessage.hashCode;
  }

  @override
  String toString() {
    return 'BaseState(status: $status, hasData: $hasData, error: $errorMessage)';
  }
}

/// Notifier para gerenciar estados de forma reativa
class BaseStateNotifier<T> extends ValueNotifier<BaseState<T>> {
  BaseStateNotifier([BaseState<T>? initialState])
      : super(initialState ?? BaseState());

  /// Método para executar operações assíncronas com gerenciamento automático de estado
  Future<void> execute(Future<T> Function() operation) async {
    value = value.copyWithLoading();

    try {
      final result = await operation();
      value = value.copyWithSuccess(result);
    } catch (e) {
      final errorMessage = e.toString();
      final exception = e is Exception ? e : Exception(e.toString());
      value = value.copyWithError(errorMessage, exception);
    }
  }

  /// Limpa o estado atual
  void clear() {
    value = BaseState();
  }

  /// Define um estado de sucesso manualmente
  void setSuccess(T data) {
    value = value.copyWithSuccess(data);
  }

  /// Define um estado de erro manualmente
  void setError(String message, [Exception? exception]) {
    value = value.copyWithError(message, exception);
  }

  /// Define estado de loading manualmente
  void setLoading() {
    value = value.copyWithLoading();
  }
}

/// Widget helper para construir UI baseada no estado
class StateBuilder<T> extends StatelessWidget {
  final BaseState<T> state;
  final Widget Function(T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(String error)? onError;
  final Widget Function()? onIdle;

  const StateBuilder({
    super.key,
    required this.state,
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onIdle,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LoadingState.loading:
        return onLoading?.call() ??
            const Center(
              child: CircularProgressIndicator(),
            );

      case LoadingState.success:
        if (state.hasData) {
          return onSuccess(state.data!);
        }
        return onError?.call('Dados não encontrados') ??
            const Center(
              child: Text('Nenhum dado disponível'),
            );

      case LoadingState.error:
        return onError?.call(state.errorMessage ?? 'Erro desconhecido') ??
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Erro desconhecido',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );

      case LoadingState.idle:
        return onIdle?.call() ?? const SizedBox.shrink();
    }
  }
}

/// Mixin para facilitar o uso do BaseState em StatefulWidgets
mixin BaseStateMixin<T extends StatefulWidget> on State<T> {
  final Map<String, BaseStateNotifier<dynamic>> _notifiers = {};

  /// Obtém ou cria um notifier para um tipo específico
  BaseStateNotifier<K> getNotifier<K>(String key) {
    return _notifiers.putIfAbsent(
      key,
      () => BaseStateNotifier<K>(),
    ) as BaseStateNotifier<K>;
  }

  @override
  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
    super.dispose();
  }
}
