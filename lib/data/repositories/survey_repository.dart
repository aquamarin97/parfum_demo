import '../../core/constants/app_constants.dart';
import '../local/asset_json_loader.dart';
import '../models/question.dart';
import '../models/survey.dart';
import 'i_survey_repository.dart';

/// Loads the survey question set from the Flutter asset bundle.
///
/// Expects the asset at [AppConstants.surveyAssetPath] to contain a
/// JSON object with a `perfume_survey` array. Each element must have
/// an `id` (int) and a `translations` map keyed by BCP 47 language code.
class SurveyRepository implements ISurveyRepository {
  SurveyRepository(this._loader);

  final AssetJsonLoader _loader;

  @override
  Future<Survey> loadSurvey() async {
    final json = await _loader.loadJson(AppConstants.surveyAssetPath);
    final list = json['perfume_survey'] as List<dynamic>;
    final questions = list.map(_parseQuestion).toList();
    return Survey(questions: questions);
  }

  SurveyQuestion _parseQuestion(dynamic entry) {
    final map = entry as Map<String, dynamic>;
    final id = map['id'] as int;
    final translationsJson = map['translations'] as Map<String, dynamic>;
    final translations = <String, QuestionTranslation>{
      for (final code in translationsJson.keys)
        code: _parseTranslation(translationsJson[code] as Map<String, dynamic>),
    };
    return SurveyQuestion(id: id, translations: translations);
  }

  QuestionTranslation _parseTranslation(Map<String, dynamic> json) {
    return QuestionTranslation(
      text: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((o) => o.toString())
          .toList(),
    );
  }
}