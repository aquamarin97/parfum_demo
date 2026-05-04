import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../string_source.dart';

/// USB veya manuel dosya kopyalama ile güncelleme için.
/// [basePath] genellikle exe dosyasının yanındaki "i18n" klasörüdür.
class FilesystemStringSource implements StringSource {
  const FilesystemStringSource(this.basePath);

  final String basePath;

  @override
  Future<Map<String, String>?> load(String languageCode) async {
    try {
      final file = File(p.join(basePath, 'strings_$languageCode.json'));
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }
}
