abstract interface class IPlcClient {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendRecommendation(List<int> ids);

  Future<void> sendSelectedTester(int testerNumber);
  Future<bool> checkTestersReady();
  Future<int> checkPaymentStatus();
  Future<bool> checkPerfumeReady();
  Stream<bool> watchTestersReady();
  Stream<int> watchPaymentStatus();
  Stream<bool> watchPerfumeReady();
  bool get isConnected;
  Future<bool> healthCheck();
}
