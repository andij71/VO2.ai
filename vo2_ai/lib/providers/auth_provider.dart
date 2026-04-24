// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/openrouter_service.dart';

const _keyStorageKey = 'openrouter_api_key';

enum AuthState { unknown, unauthenticated, validating, authenticated, invalid }

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  OpenRouterService? _service;

  AuthNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(AuthState.unknown);

  OpenRouterService? get service => _service;

  Future<void> init() async {
    final key = await _storage.read(key: _keyStorageKey);
    if (key == null || key.isEmpty) {
      state = AuthState.unauthenticated;
      return;
    }
    await setKey(key);
  }

  Future<void> setKey(String apiKey) async {
    state = AuthState.validating;
    _service = OpenRouterService(apiKey: apiKey);
    final valid = await _service!.validateKey();
    if (valid) {
      await _storage.write(key: _keyStorageKey, value: apiKey);
      state = AuthState.authenticated;
    } else {
      _service = null;
      state = AuthState.invalid;
    }
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _keyStorageKey);
    _service = null;
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
