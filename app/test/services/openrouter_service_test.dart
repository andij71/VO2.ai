// test/services/openrouter_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/openrouter_service.dart';

class MockInterceptor extends Interceptor {
  final List<RequestOptions> requests = [];
  Response? mockResponse;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    if (mockResponse != null) {
      handler.resolve(mockResponse!);
    } else {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'choices': [
          {
            'message': {'content': 'Test response'}
          }
        ]
      }));
    }
  }
}

void main() {
  late OpenRouterService service;
  late MockInterceptor mock;

  setUp(() {
    mock = MockInterceptor();
    final dio = Dio();
    dio.interceptors.add(mock);
    service = OpenRouterService(dio: dio, apiKey: 'test-key');
  });

  test('sendMessage sends correct request format', () async {
    final response = await service.sendMessage(
      messages: [
        {'role': 'user', 'content': 'Hello'}
      ],
      model: 'anthropic/claude-sonnet-4',
    );

    expect(mock.requests.length, 1);
    expect(mock.requests.first.path, contains('/chat/completions'));
    expect(mock.requests.first.headers['Authorization'], 'Bearer test-key');
    final body = mock.requests.first.data as Map<String, dynamic>;
    expect(body['model'], 'anthropic/claude-sonnet-4');
    expect(body['messages'], isA<List>());
    expect(response, 'Test response');
  });

  test('sendMessage throws on error', () async {
    mock.mockResponse = Response(
      requestOptions: RequestOptions(),
      statusCode: 401,
      data: {
        'error': {'message': 'Invalid API key'}
      },
    );

    expect(
      () => service.sendMessage(
        messages: [
          {'role': 'user', 'content': 'Hi'}
        ],
        model: 'anthropic/claude-sonnet-4',
      ),
      throwsA(isA<OpenRouterException>()),
    );
  });

  test('validateKey returns true for valid key', () async {
    final isValid = await service.validateKey();
    expect(isValid, true);
  });
}
