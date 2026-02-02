// plc_error_codes.dart
/// PLC bağlantı ve iletişim hataları için error code sistemi
class PLCErrorCodes {
  // Bağlantı hataları (400-409)
  static const int connectionFailed = 401;
  static const int connectionTimeout = 402;
  static const int connectionLost = 403;
  static const int invalidHost = 404;
  static const int portNotAvailable = 405;
  
  // İletişim hataları (410-419)
  static const int modbusReadError = 410;
  static const int modbusWriteError = 411;
  static const int invalidRegisterAddress = 412;
  static const int dataCorruption = 413;
  static const int responseTimeout = 414;
  
  // PLC durum hataları (420-429)
  static const int plcNotReady = 420;
  static const int plcEmergencyStop = 421;
  static const int sensorError = 422;
  static const int motorError = 423;
  
  // Uygulama hataları (430-439)
  static const int unknownError = 430;
  static const int configurationError = 431;
  
  /// Hata kodu için kullanıcı dostu mesaj döndürür
  static String getErrorMessage(int errorCode, String locale) {
    final messages = _errorMessages[locale] ?? _errorMessages['tr']!;
    return messages[errorCode] ?? messages[unknownError]!;
  }
  
  /// Hata kodu için teknik açıklama döndürür (teknisyenler için)
  static String getTechnicalDescription(int errorCode) {
    return _technicalDescriptions[errorCode] ?? 
           'Bilinmeyen hata kodu: $errorCode';
  }
  
  static final Map<String, Map<int, String>> _errorMessages = {
    'tr': {
      connectionFailed: 'PLC bağlantısı kurulamadı',
      connectionTimeout: 'Bağlantı zaman aşımına uğradı',
      connectionLost: 'PLC ile bağlantı kesildi',
      invalidHost: 'Geçersiz PLC adresi',
      portNotAvailable: 'Port erişilemez durumda',
      modbusReadError: 'Veri okuma hatası',
      modbusWriteError: 'Veri yazma hatası',
      invalidRegisterAddress: 'Geçersiz register adresi',
      dataCorruption: 'Veri bozulması tespit edildi',
      responseTimeout: 'PLC yanıt vermedi',
      plcNotReady: 'PLC hazır değil',
      plcEmergencyStop: 'Acil durum butonu aktif',
      sensorError: 'Sensör hatası',
      motorError: 'Motor hatası',
      unknownError: 'Beklenmeyen bir hata oluştu',
      configurationError: 'Yapılandırma hatası',
    },
    'en': {
      connectionFailed: 'Failed to connect to PLC',
      connectionTimeout: 'Connection timeout',
      connectionLost: 'Connection to PLC lost',
      invalidHost: 'Invalid PLC address',
      portNotAvailable: 'Port not available',
      modbusReadError: 'Data read error',
      modbusWriteError: 'Data write error',
      invalidRegisterAddress: 'Invalid register address',
      dataCorruption: 'Data corruption detected',
      responseTimeout: 'PLC did not respond',
      plcNotReady: 'PLC not ready',
      plcEmergencyStop: 'Emergency stop active',
      sensorError: 'Sensor error',
      motorError: 'Motor error',
      unknownError: 'An unexpected error occurred',
      configurationError: 'Configuration error',
    },
    'ar': {
      connectionFailed: 'فشل الاتصال بـ PLC',
      connectionTimeout: 'انتهت مهلة الاتصال',
      connectionLost: 'فُقد الاتصال بـ PLC',
      invalidHost: 'عنوان PLC غير صالح',
      portNotAvailable: 'المنفذ غير متاح',
      modbusReadError: 'خطأ في قراءة البيانات',
      modbusWriteError: 'خطأ في كتابة البيانات',
      invalidRegisterAddress: 'عنوان السجل غير صالح',
      dataCorruption: 'تم اكتشاف تلف في البيانات',
      responseTimeout: 'لم يستجب PLC',
      plcNotReady: 'PLC غير جاهز',
      plcEmergencyStop: 'زر الطوارئ نشط',
      sensorError: 'خطأ في المستشعر',
      motorError: 'خطأ في المحرك',
      unknownError: 'حدث خطأ غير متوقع',
      configurationError: 'خطأ في التكوين',
    },
  };
  
  static final Map<int, String> _technicalDescriptions = {
    connectionFailed: 'TCP/IP bağlantısı başlatılamadı. IP ve port ayarlarını kontrol edin.',
    connectionTimeout: 'Bağlantı timeout değeri: 3000ms. PLC network üzerinde erişilebilir mi?',
    connectionLost: 'Aktif bağlantı kesildi. Kablo bağlantısını ve PLC gücünü kontrol edin.',
    invalidHost: 'Hedef IP adresi geçersiz format. Varsayılan: 127.0.0.1',
    portNotAvailable: 'Modbus TCP portu (502) kullanımda veya engellenmiş.',
    modbusReadError: 'Read Holding Registers (FC03) komutu başarısız.',
    modbusWriteError: 'Write Single Register (FC06) veya Multiple (FC16) komutu başarısız.',
    invalidRegisterAddress: 'Register adresi range dışında (0-65535).',
    dataCorruption: 'CRC/Checksum hatası. Elektriksel gürültü veya kablo sorunu olabilir.',
    responseTimeout: 'PLC read timeout: 2000ms. PLC yanıt süresi yavaş olabilir.',
    plcNotReady: 'PLC RUN modunda değil. PLC panel kontrolünü yapın.',
    plcEmergencyStop: 'E-STOP aktif. Güvenlik devresi kontrol edilmeli.',
    sensorError: 'Analog/Digital sensor okuma hatası. Sensor kalibrasyonu gerekli.',
    motorError: 'Motor sürücü hatası. Inverter/Driver kontrolü yapın.',
    unknownError: 'Kategorize edilmemiş hata. Log dosyalarını inceleyin.',
    configurationError: 'Modbus ayarları hatalı. Config dosyasını kontrol edin.',
  };
}

/// PLC Hatası Exception sınıfı
class PLCException implements Exception {
  final int errorCode;
  final String message;
  final String? technicalDetail;
  final DateTime timestamp;
  
  PLCException({
    required this.errorCode,
    required this.message,
    this.technicalDetail,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'PLCException(code: $errorCode, message: $message, time: $timestamp)';
  }
  
  /// Kullanıcıya gösterilecek mesaj
  String getUserMessage(String locale) {
    return PLCErrorCodes.getErrorMessage(errorCode, locale);
  }
  
  /// Teknisyene gösterilecek detaylı bilgi
  String getTechnicalInfo() {
    final baseInfo = PLCErrorCodes.getTechnicalDescription(errorCode);
    if (technicalDetail != null) {
      return '$baseInfo\n\nEk Detay: $technicalDetail';
    }
    return baseInfo;
  }
}