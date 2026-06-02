import '../models/kvkk_text.dart';

abstract interface class IKvkkRepository {
  Future<KvkkText> loadKvkk();
}
