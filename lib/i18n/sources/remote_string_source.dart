import 'dart:convert';
import 'dart:io';

import '../string_source.dart';

/// İnternet bağlantısı varsa merkezi sunucudan çeker.
/// [baseUrl] örnek: 'https://cdn.ventuse.com/i18n'
/// İstenen dosya: $baseUrl/strings_$languageCode.json
class RemoteStringSource implements StringSource {
  const RemoteStringSource(this.baseUrl);

  final String baseUrl;

  @override
  Future<Map<String, String>?> load(String languageCode) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/strings_$languageCode.json');
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      final response = await request.close()
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
