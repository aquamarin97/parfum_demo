import '../../core/constants/app_constants.dart';
import '../local/asset_json_loader.dart';
import '../models/question.dart';
import '../models/survey.dart';
import 'i_survey_repository.dart';

class SurveyRepository implements ISurveyRepository {
  SurveyRepository(this._loader);

  final AssetJsonLoader _loader;

  @override
  Future<Survey> loadSurvey() async {
    final json = await _loader.loadJson(AppConstants.surveyAssetPath);
    final list = json['perfume_survey'] as List<dynamic>;
    final questions = list.map((entry) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as int;
      final translationsJson = map['translations'] as Map<String, dynamic>;
      final translations = <String, QuestionTranslation>{};
      for (final code in translationsJson.keys) {
        final langJson = translationsJson[code] as Map<String, dynamic>;
        final text = langJson['question'] as String;
        final options = (langJson['options'] as List<dynamic>)
            .map((option) => option.toString())
            .toList();
        translations[code] = QuestionTranslation(text: text, options: options);
      }
      return SurveyQuestion(id: id, translations: translations);
    }).toList();
    return Survey(questions: questions);
  }
}
