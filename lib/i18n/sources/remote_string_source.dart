import 'dart:convert';
import 'dart:io';

import '../string_source.dart';

/// Fetches localised strings from a remote CDN.
///
/// Expected URL format: `$baseUrl/strings_<languageCode>.json`
///
/// Returns `null` on any error (network, timeout, or parse failure) so
/// that [StringRepository] falls through to the next source silently and
/// logs the failure.
///
/// Not wired into [AppViewModelProvider] by default — add as the first
/// source when remote string updates are required.
class RemoteStringSource implements StringSource {
  const RemoteStringSource(this.baseUrl);

  /// Base URL of the i18n CDN (e.g. `'https://cdn.ventuse.com/i18n'`).
  final String baseUrl;

  static const _timeout = Duration(seconds: 5);

  @override
  Future<Map<String, String>?> load(String languageCode) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/strings_$languageCode.json');
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}