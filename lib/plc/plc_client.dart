// plc_client.dart file
abstract class PlcClient {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendRecommendation(List<int> ids);
}