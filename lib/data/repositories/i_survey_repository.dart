import '../models/survey.dart';

/// Contract for loading the survey question set.
///
/// Implementations may load from the asset bundle ([SurveyRepository]),
/// a remote API, or a local database.
abstract interface class ISurveyRepository {
  /// Loads and returns the complete [Survey].
  ///
  /// Throws if the underlying data source is unavailable or returns
  /// malformed data.
  Future<Survey> loadSurvey();
}