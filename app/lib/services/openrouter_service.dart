// lib/services/openrouter_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OpenRouterException implements Exception {
  final String message;
  final int? statusCode;
  OpenRouterException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenRouterException: $message (status: $statusCode)';
}

class OpenRouterService {
  static const _baseUrl = 'https://openrouter.ai/api/v1';

  final Dio _dio;
  final String apiKey;

  OpenRouterService({Dio? dio, required this.apiKey})
      : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 120);
    // Use interceptor to guarantee headers on every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $apiKey';
        options.headers['Content-Type'] = 'application/json';
        options.headers['HTTP-Referer'] = 'https://vo2.ai';
        options.headers['X-Title'] = 'VO2.ai';
        handler.next(options);
      },
    ));
  }

  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    required String model,
  }) async {
    debugPrint('[OpenRouter] POST /chat/completions model=$model messages=${messages.length}');

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'max_tokens': 16384,
        },
      );

      debugPrint('[OpenRouter] Response status: ${response.statusCode}');

      final data = response.data;
      if (data == null) {
        throw OpenRouterException('Empty response body');
      }

      // Check for API-level error in response body
      if (data['error'] != null) {
        final errMsg = data['error']['message'] ?? data['error'].toString();
        debugPrint('[OpenRouter] API error: $errMsg');
        throw OpenRouterException(errMsg, statusCode: data['error']['code']);
      }

      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        debugPrint('[OpenRouter] No choices in response: $data');
        throw OpenRouterException('No response from model');
      }

      final content = choices.first['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        debugPrint('[OpenRouter] Empty content in response');
        throw OpenRouterException('Empty content from model');
      }

      debugPrint('[OpenRouter] Got response: ${content.length} chars');
      return content;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      String errorMsg;

      if (responseData is Map && responseData['error'] != null) {
        errorMsg = responseData['error']['message'] ?? responseData['error'].toString();
      } else if (responseData is String) {
        errorMsg = responseData;
      } else {
        errorMsg = e.message ?? 'Network error';
      }

      debugPrint('[OpenRouter] DioException: status=$statusCode msg=$errorMsg');
      debugPrint('[OpenRouter] Type: ${e.type}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw OpenRouterException('Request timed out — try again', statusCode: statusCode);
      }

      throw OpenRouterException(errorMsg, statusCode: statusCode);
    }
  }

  Future<bool> validateKey() async {
    debugPrint('[OpenRouter] Validating API key...');
    try {
      final response = await _dio.get('/auth/key');
      final data = response.data;
      // /auth/key returns { "data": { "label": "...", ... } } for valid keys
      final valid = response.statusCode == 200 &&
          data is Map &&
          data['data'] is Map;
      debugPrint('[OpenRouter] Key validation: ${valid ? 'OK' : 'FAILED'} (status: ${response.statusCode})');
      return valid;
    } on DioException catch (e) {
      debugPrint('[OpenRouter] Key validation failed: ${e.response?.statusCode} — ${e.message}');
      debugPrint('[OpenRouter] Response data: ${e.response?.data}');
      return false;
    }
  }
}
