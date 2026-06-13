/// Slot ID → parfüm adı eşlemesi (1–24).
///
/// Slot 1–12: Erkek ürünleri · Slot 13–24: Kadın ürünleri
abstract final class PerfumeCatalogue {
  static const Map<int, String> _names = {
    1:  'Amouage – Reasons (Essence de Parfum)',
    2:  'Anomalia Paris – Umbra Oud EDP',
    3:  'Chanel – Bleu de Chanel L\'Exclusif (Extrait)',
    4:  'Dolce & Gabbana – Devotion for Men Parfum',
    5:  'Maison Francis Kurkdjian – Amyris Homme (Extrait)',
    6:  'Marc-Antoine Barrois – Aldebaran EDP',
    7:  'Parfums de Marly – Haltane EDP',
    8:  'Prada – Paradigme EDP',
    9:  'Roja Parfums – Elysium Noir Pour Homme EDP',
    10: 'The Merchant of Venice – Venetian Blue Intense EDP',
    11: 'Tom Ford – Oud Minerale EDP',
    12: 'Versace – Eros Flame EDP',
    13: 'Carolina Herrera – Good Girl Blush EDP',
    14: 'Khloé Kardashian – XO Khloé EDP',
    15: 'Lancôme – La Vie Est Belle EDP',
    16: 'Marc Jacobs – Daisy Wild EDP',
    17: 'Merit – Retrospect (L\'Extrait)',
    18: 'Mugler – Alien Hypersense EDP',
    19: 'Parfums de Marly – Delina Exclusif',
    20: 'Parfums de Marly – Valaya EDP',
    21: 'Prada – Paradoxe EDP',
    22: 'Valentino – Donna Born In Roma EDP',
    23: 'YSL – Black Opium EDP',
    24: 'YSL – Libre Intense EDP',
  };

  /// Slot ID'ye göre parfüm adını döner. Bilinmeyen ID için `"Slot #N"` döner.
  static String nameOf(int slotId) => _names[slotId] ?? 'Slot #$slotId';
}
