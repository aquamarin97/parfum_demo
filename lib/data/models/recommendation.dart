// recommendation.dart file
// recommendation.dart (yeni dosya oluşturun)
class Recommendation {
  final List<int> topIds;

  Recommendation({required this.topIds});

  // Test için statik factory
  factory Recommendation.mock() {
    return Recommendation(
      topIds: [101, 202, 303], // Mock parfüm ID'leri
    );
  }
}