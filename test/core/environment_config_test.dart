import 'package:fitai/core/api/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ApiConfig.reset);

  test(
    'nao usa endpoint de rede implicito quando API_BASE_URL esta ausente',
    () {
      ApiConfig.configure(baseUrl: '');

      expect(ApiConfig.isConfigured, isFalse);
      expect(
        () => ApiConfig.endpoint('/health'),
        throwsA(isA<ApiConfigurationException>()),
      );
    },
  );

  test('normaliza endpoint configurado externamente', () {
    ApiConfig.configure(baseUrl: 'https://api.fitia.test///');

    expect(
      ApiConfig.endpoint('health'),
      Uri.parse('https://api.fitia.test/health'),
    );
  });
}
