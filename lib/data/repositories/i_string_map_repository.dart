abstract interface class IStringMapRepository {
  Future<Map<String, Map<String, String>>> loadStrings();
}
