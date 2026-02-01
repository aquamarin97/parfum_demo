// string_repository.dart file
import '../core/constants/app_constants.dart';
import '../data/local/asset_json_loader.dart';
import '../data/models/language.dart';

class StringRepository {
  StringRepository(this._loader);

  final AssetJsonLoader _loader;

  Future<Map<Language, Map<String, String>>> loadAll() async {
    final Map<Language, Map<String, String>> result = {};

    // Language.values kullanarak tüm dilleri dinamik yükleyebilirsin
    for (var lang in Language.values) {
      // AppConstants içindeki yolları Language enum'u ile eşleştiren bir mantık
      final path = _getPathForLanguage(lang); 
      result[lang] = await _loadLanguage(path);
    }
    
    return result;
  }

  String _getPathForLanguage(Language lang) {
    switch (lang) {
      case Language.tr: return AppConstants.stringsTr;
      case Language.en: return AppConstants.stringsEn;
      case Language.ar: return AppConstants.stringsAr;
    }
  }

  Future<Map<String, String>> _loadLanguage(String path) async {
    try {
      final json = await _loader.loadJson(path);
      // JSON içindeki her bir değeri String'e güvenli şekilde cast ediyoruz
      return json.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // ÖNEMLİ: Hata anında boş map dönerse AppStrings "MISSING" basacaktır.
      // Buraya bir logger eklemek hatayı bulmanı kolaylaştırır.
      print('StringRepository Error ($path): $e'); 
      return {};
    }
  }
}