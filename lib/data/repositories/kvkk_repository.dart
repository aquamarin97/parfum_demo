import '../../core/constants/app_constants.dart';
import '../local/asset_json_loader.dart';
import '../models/kvkk_text.dart';
import 'i_kvkk_repository.dart';

/// Loads the KVKK consent text from the Flutter asset bundle.
///
/// Expects the asset at [AppConstants.kvkkAssetPath] to contain a JSON
/// object with a `kvkk_text` entry that has an `id` (string) and a
/// `translations` map keyed by BCP 47 language code.
class KvkkRepository implements IKvkkRepository {
  KvkkRepository(this._loader);

  final AssetJsonLoader _loader;

  @override
  Future<KvkkText> loadKvkk() async {
    final json = await _loader.loadJson(AppConstants.kvkkAssetPath);
    final kvkk = json['kvkk_text'] as Map<String, dynamic>;
    final id = kvkk['id'].toString();
    final translationsJson = kvkk['translations'] as Map<String, dynamic>;
    final translations = <String, KvkkTranslation>{
      for (final code in translationsJson.keys)
        code: _parseTranslation(
          translationsJson[code] as Map<String, dynamic>,
        ),
    };
    return KvkkText(id: id, translations: translations);
  }

  KvkkTranslation _parseTranslation(Map<String, dynamic> json) {
    return KvkkTranslation(
      title: json['title'].toString(),
      body: json['content'].toString(),
      approvalLabel: json['approval_text'].toString(),
      buttonLabel: json['button_text'].toString(),
    );
  }
}