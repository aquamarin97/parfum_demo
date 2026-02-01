// kvkk_repository.dart file
import '../../core/constants/app_constants.dart';
import '../local/asset_json_loader.dart';
import '../models/kvkk_text.dart';
import '../models/language.dart';

class KvkkRepository {
  KvkkRepository(this._loader);

  final AssetJsonLoader _loader;

  Future<KvkkText> loadKvkk() async {
    final json = await _loader.loadJson(AppConstants.kvkkAssetPath);
    final kvkk = json['kvkk_metni'] as Map<String, dynamic>;
    final id = kvkk['id'].toString();
    final translationsJson = kvkk['translations'] as Map<String, dynamic>;
    final translations = <Language, KvkkTranslation>{};
    for (final language in Language.values) {
      final langJson = translationsJson[language.code] as Map<String, dynamic>;
      translations[language] = KvkkTranslation(
        title: langJson['baslik'].toString(),
        body: langJson['icerik'].toString(),
        approvalLabel: langJson['onay_metni'].toString(),
        buttonLabel: langJson['buton_metni'].toString(),
      );
    }
    return KvkkText(id: id, translations: translations);
  }
}