import '../data/models/language.dart';
import 'string_source.dart';

class StringRepository {
  StringRepository(this._sources);

  final List<StringSource> _sources;

  /// Verilen dil listesi için her dile ait stringleri yükler.
  /// Kaynak önceliği: kaynaklar listesindeki sıra (ilk bulunan kazanır).
  Future<Map<String, Map<String, String>>> loadAll(
    List<Language> languages,
  ) async {
    final result = <String, Map<String, String>>{};
    for (final lang in languages) {
      result[lang.code] = await _loadFor(lang.code);
    }
    return result;
  }

  Future<Map<String, String>> _loadFor(String code) async {
    for (final source in _sources) {
      try {
        final data = await source.load(code);
        if (data != null && data.isNotEmpty) return data;
      } catch (_) {}
    }
    return {};
  }
}
