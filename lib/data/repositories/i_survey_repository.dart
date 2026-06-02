import '../models/survey.dart';

abstract interface class ISurveyRepository {
  Future<Survey> loadSurvey();
}
