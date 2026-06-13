/// Bir kullanıcı oturumunun kurtarılabilir anlık görüntüsü.
///
/// PLC hatası veya bağlantı kopması sonrası kullanıcıya tüm soruları
/// yeniden sormaktan kaçınmak için öneri listesi ve zaman damgası saklanır.
///
/// [isValid]: 10 dakika içindeki oturumlar kurtarılabilir kabul edilir.
class SessionSnapshot {
  const SessionSnapshot({
    required this.topIds,
    required this.savedAt,
  });

  final List<int> topIds;
  final DateTime savedAt;

  static const _ttl = Duration(minutes: 10);

  bool get isValid =>
      topIds.isNotEmpty && DateTime.now().difference(savedAt) < _ttl;

  Map<String, dynamic> toJson() => {
        'topIds': topIds,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) =>
      SessionSnapshot(
        topIds: List<int>.from(json['topIds'] as List),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
