import '../models/kvkk_text.dart';

/// Contract for loading the KVKK consent text.
///
/// Implementations may load from the asset bundle ([KvkkRepository]),
/// a remote API, or a local database.
abstract interface class IKvkkRepository {
  /// Loads and returns the [KvkkText] for all supported languages.
  ///
  /// Throws if the underlying data source is unavailable or returns
  /// malformed data.
  Future<KvkkText> loadKvkk();
}