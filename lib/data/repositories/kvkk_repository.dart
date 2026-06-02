import '../../core/constants/app_constants.dart';
import '../local/asset_json_loader.dart';
import '../models/kvkk_text.dart';
import 'i_kvkk_repository.dart';

class KvkkRepository implements IKvkkRepository {
  KvkkRepository(this._loader);

  final AssetJsonLoader _loader;

  @override
  Future<KvkkText> loadKvkk() async {
    final json = await _loader.loadJson(AppConstants.kvkkAssetPath);
    final kvkk = json['kvkk_text'] as Map<String, dynamic>;
    final id = kvkk['id'].toString();
    final translationsJson = kvkk['translations'] as Map<String, dynamic>;
    final translations = <String, KvkkTranslation>{};
    for (final code in translationsJson.keys) {
      final langJson = translationsJson[code] as Map<String, dynamic>;
      translations[code] = KvkkTranslation(
        title: langJson['title'].toString(),
        body: langJson['content'].toString(),
        approvalLabel: langJson['approval_text'].toString(),
        buttonLabel: langJson['button_text'].toString(),
      );
    }
    return KvkkText(id: id, translations: translations);
  }
}
