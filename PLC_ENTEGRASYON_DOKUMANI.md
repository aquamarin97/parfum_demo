# Parfüm Kiosk — PLC Entegrasyon Dokümanı
**Register Haritası v1.1 · 2026-06-13**

---

## 1. Bağlantı Bilgileri

| Parametre | Değer |
|---|---|
| Protokol | Modbus TCP |
| PLC IP Adresi | `192.168.1.105` |
| Port | `502` |
| Slave ID | `1` |
| Bağlantı Timeout | 3000 ms |
| Retry Sayısı | 3 |
| Register Türü | Holding Registers (4x) |

> IP adresi `assets/config/plc_registers.json` üzerinden yapılandırılabilir.

---

## 2. Register Haritası

Tüm registerlar **uint16** (16-bit işaretsiz tam sayı) tipindedir.  
Adres notasyonu: **PDU adresi** (0-tabanlı). Simülatörde 400001 formatına çeviri: `PDU + 1` → `400101`.

### Blok 1 — Komutlar · Flutter → PLC (Yalnızca Flutter yazar)

| PDU Adresi | Simülatör | Register | Açıklama |
|---|---|---|---|
| 100 | 400101 | CMD_ACTION | Komut türü (aşağıya bakın) |
| 101 | 400102 | CMD_SLOT | Hedef slot numarası (1–24) |
| 102 | 400103 | CMD_SEQ_ID | Komut sıra numarası (0–255, döngüsel) |

**CMD_ACTION değerleri:**

| Değer | Anlamı |
|---|---|
| 0 | Boşta |
| 1 | Tester Bas |
| 2 | Ödeme Başlat |
| 3 | Satış Bas |
| 4 | Sistem Sıfırla |
| 5 | Oturumu İptal Et |

---

### Blok 2 — Sistem Durumu · PLC → Flutter (Yalnızca PLC yazar)

| PDU Adresi | Simülatör | Register | Açıklama |
|---|---|---|---|
| 200 | 400201 | STATUS_SYSTEM | Sistem durumu |
| 201 | 400202 | LAST_CMD_SEQ_ID | Son işlenen komutun sıra numarası |
| 202 | 400203 | LAST_CMD_RESULT | Son komutun sonucu |
| 203 | 400204 | ACTIVE_SLOT | O an aktif slot numarası |

**STATUS_SYSTEM değerleri:**

| Değer | Anlamı |
|---|---|
| 0 | Boşta |
| 1 | Meşgul |
| 2 | Hata |

**LAST_CMD_RESULT değerleri:**

| Değer | Anlamı |
|---|---|
| 0 | Başarılı |
| 1 | Başarısız |

---

### Blok 3 — Ödeme Sistemi · Çift Yönlü

| PDU Adresi | Simülatör | Register | Yön | Açıklama |
|---|---|---|---|---|
| 300 | 400301 | PAYMENT_STATUS | PLC → Flutter | Ödeme durumu |
| 301 | 400302 | PAYMENT_AMOUNT | Flutter → PLC | Ödeme tutarı (kuruş) |
| 302 | 400303 | PAYMENT_CONFIRMED_ACK | Flutter → PLC | Ödeme onay bildirimi |
| 303 | 400304 | SALE_COMPLETED | PLC → Flutter | Satış tamamlandı |

**PAYMENT_STATUS değerleri:**

| Değer | Anlamı |
|---|---|
| 0 | Bekliyor |
| 1 | Onaylandı |
| 2 | Reddedildi |
| 3 | Timeout |

> `PAYMENT_AMOUNT`: Değer kuruş cinsindendir. Örnek: 590 TL → `59000`.

---

### Blok 4 — Sensörler · PLC → Flutter (Yalnızca PLC yazar)

| PDU Adresi | Simülatör | Register | Açıklama |
|---|---|---|---|
| 400 | 400401 | SENSOR_PRESENCE | Müşteri varlık sensörü |
| 401–424 | 400402–400425 | STOCK_1–STOCK_24 | Slot 1–24 stok durumu |

**Değerler (tüm sensörler için):**

| Değer | Anlamı |
|---|---|
| 0 | Boş / Kullanıcı Yok |
| 1 | Dolu / Kullanıcı Var |

---

### Blok 5 — Hata Kayıtları · Çift Yönlü

| PDU Adresi | Simülatör | Register | Yön | Açıklama |
|---|---|---|---|---|
| 500 | 400501 | ERROR_CODE | PLC → Flutter | Birincil hata kodu |
| 501 | 400502 | ERROR_SLOT | PLC → Flutter | Hata veren slot |
| 502 | 400503 | ERROR_CODE_2 | PLC → Flutter | İkincil hata kodu |
| 503 | 400504 | ERROR_SLOT_2 | PLC → Flutter | İkincil hata slotu |
| 504 | 400505 | ERROR_ACK | Flutter → PLC | Hata okundu bildirimi |

**ERROR_CODE değerleri:**

| Değer | Anlamı |
|---|---|
| 0 | Hata Yok |
| 1 | Pompa Arıza |
| 2 | Dispenser Arıza |
| 3 | Stok Boş |
| 4 | Terminal Arıza |
| 5 | Ödeme Timeout |
| 6 | Aşırı Isınma |

---

### Blok 6 — Heartbeat · Çift Yönlü

| PDU Adresi | Simülatör | Register | Yön | Açıklama |
|---|---|---|---|---|
| 600 | 400601 | PLC_HEARTBEAT | PLC → Flutter | PLC sağlık sinyali |
| 601 | 400602 | FLUTTER_HEARTBEAT | Flutter → PLC | Uygulama sağlık sinyali |

> Her iki taraf da kendi heartbeat değerini her saniye 1 artırır (0–65535 döngüsel).  
> Flutter, `PLC_HEARTBEAT` değişmezse bağlantıyı kesilmiş kabul eder.

---

## 3. Komut-ACK Mekanizması

Flutter her komut gönderiminde şu sırayı izler:

```
1. Flutter yazar:
   CMD_SLOT     (R101) ← hedef slot
   CMD_ACTION   (R100) ← komut türü      ← PLC bu yazmayı trigger noktası olarak alır
   CMD_SEQ_ID   (R102) ← sıra numarası

2. PLC komutları işler ve yazar:
   LAST_CMD_SEQ_ID  (R201) ← Flutter'ın gönderdiği CMD_SEQ_ID değerini yazar
   LAST_CMD_RESULT  (R202) ← 0 (başarılı) veya 1 (başarısız)

3. Flutter her 500 ms'de R201'i okur:
   R201 == CMD_SEQ_ID → ACK alındı
   R201 != CMD_SEQ_ID → bekle (max. 30 saniye, sonra timeout hatası)
```

**Önemli:** PLC, `CMD_SEQ_ID` yazılana kadar komutu işlememeli; `CMD_SEQ_ID` yazıldığında tüm komut verisi (`ACTION` + `SLOT`) hazır demektir.

---

## 4. Tam Operasyon Akışı

### Adım 1 — Tester Hazırlama

Müşteri anketi tamamladığında uygulama 3 parfüm önerir ve her biri için tester komutu gönderir.

```
Flutter → PLC (slot A için):
  R101 = <slotId_A>
  R100 = 1  (Tester Bas)
  R102 = N  (sıra numarası)

PLC → Flutter (ACK):
  R201 = N
  R202 = 0
  R200 = 1  (Meşgul — testerlar fiziksel olarak hazırlanıyor)

[Aynı işlem slot B ve slot C için tekrarlanır]
```

### Adım 2 — Sistem Boşta Bekleme

3 tester komutu ACK'landıktan sonra Flutter, `STATUS_SYSTEM = 0` olana kadar R200'ü izler.

```
PLC → Flutter (testerlar fiziksel olarak hazır):
  R200 = 0  (Boşta)
```

> Ekranda "Testerlar Hazırlandı" mesajı ve 3 seçim butonu gösterilir.

### Adım 3 — Ödeme Başlatma

Müşteri bir tester seçtiğinde:

```
Flutter → PLC:
  R302 = 0             (PAYMENT_CONFIRMED_ACK sıfırlanmış olmalı)
  R301 = <tutar_kurus> (Örn: 59000 → 590 TL)
  R101 = <seçilen_slotId>
  R100 = 3             (Ödeme Başlat)
  R102 = N+1

PLC → Flutter (ACK):
  R201 = N+1
  R202 = 0
```

### Adım 4 — Ödeme İzleme

Flutter, `PAYMENT_STATUS ≠ 0` olana kadar R300'ü her saniye okur.

```
PLC → Flutter (ödeme gerçekleşince):
  R300 = 1  (Onaylandı)
       = 2  (Reddedildi — hata ekranı gösterilir)
       = 3  (Timeout — hata ekranı gösterilir)
```

### Adım 5 — Ödeme Onayı

```
Flutter → PLC:
  R302 = 1  (PAYMENT_CONFIRMED_ACK)
```

> PLC bu değeri okuyunca `R302`'yi sıfırlamalıdır.

### Adım 6 — Satış Komutu

```
Flutter → PLC:
  R101 = <seçilen_slotId>
  R100 = 2  (Satış Bas)
  R102 = N+2

PLC → Flutter (ACK):
  R201 = N+2
  R202 = 0
```

### Adım 7 — Satış Tamamlanma

Flutter, `SALE_COMPLETED = 1` olana kadar R303'ü her 500 ms'de okur.

```
PLC → Flutter (parfüm dağıtımı tamamlandı):
  R303 = 1

Flutter → PLC (bir sonraki oturum için sıfırla):
  (PLC, R303'ü bir sonraki satışa kadar 0'a çekmeli)
```

---

## 5. Hata Yönetimi

### PLC Kaynaklı Hatalar

PLC hata durumunu şu şekilde bildirir:

```
R500 = <hata_kodu>
R501 = <hata_slotu>
R200 = 2  (STATUS_SYSTEM = Hata)
```

Flutter R200 = 2 gördüğünde kullanıcıya "Cihaz Hizmet Dışı" ekranı gösterir.

Flutter hatayı işledikten sonra:
```
R504 = 1  (ERROR_ACK)
```

### Flutter Kaynaklı Oturum İptali

Kullanıcı işlemi iptal ederse:

```
Flutter → PLC:
  R101 = 0
  R100 = 5  (Oturumu İptal Et)
  R102 = N+1
```

### Sistem Sıfırlama

```
Flutter → PLC:
  R101 = 0
  R100 = 4  (Sistem Sıfırla)
  R102 = N+1
```

---

## 6. Timing Gereksinimleri

| Parametre | Varsayılan | Ayarlanabilir |
|---|---|---|
| CMD_SEQ_ID ACK timeout | **30 saniye** | Evet (admin paneli) |
| STATUS_SYSTEM polling aralığı | 500 ms | Evet (admin paneli) |
| PAYMENT_STATUS polling aralığı | 1000 ms | Evet (admin paneli) |
| SALE_COMPLETED polling aralığı | 500 ms | Evet (admin paneli) |
| Heartbeat yazma aralığı | 1 saniye | Hayır |
| Bağlantı health check aralığı | 10 saniye | Hayır |

---

## 7. Slot — Parfüm Eşlemesi

Sistem 24 slot destekler. Slot 1–12 erkek, 13–24 kadın ürünlerine ayrılmıştır.

| Slot | Ürün |
|---|---|
| 1 | Amouage – Reasons (Essence de Parfum) |
| 2 | Anomalia Paris – Umbra Oud EDP |
| 3 | Chanel – Bleu de Chanel L'Exclusif (Extrait) |
| 4 | Dolce & Gabbana – Devotion for Men Parfum |
| 5 | Maison Francis Kurkdjian – Amyris Homme (Extrait) |
| 6 | Marc-Antoine Barrois – Aldebaran EDP |
| 7 | Parfums de Marly – Haltane EDP |
| 8 | Prada – Paradigme EDP |
| 9 | Roja Parfums – Elysium Noir Pour Homme EDP |
| 10 | The Merchant of Venice – Venetian Blue Intense EDP |
| 11 | Tom Ford – Oud Minerale EDP |
| 12 | Versace – Eros Flame EDP |
| 13 | Carolina Herrera – Good Girl Blush EDP |
| 14 | Khloé Kardashian – XO Khloé EDP |
| 15 | Lancôme – La Vie Est Belle EDP |
| 16 | Marc Jacobs – Daisy Wild EDP |
| 17 | Merit – Retrospect (L'Extrait) |
| 18 | Mugler – Alien Hypersense EDP |
| 19 | Parfums de Marly – Delina Exclusif |
| 20 | Parfums de Marly – Valaya EDP |
| 21 | Prada – Paradoxe EDP |
| 22 | Valentino – Donna Born In Roma EDP |
| 23 | YSL – Black Opium EDP |
| 24 | YSL – Libre Intense EDP |

---

## 8. Özet Register Tablosu

| PDU | Simülatör | Register | Yön | Açıklama |
|---|---|---|---|---|
| 100 | 400101 | CMD_ACTION | F→P | Komut türü |
| 101 | 400102 | CMD_SLOT | F→P | Hedef slot (1–24) |
| 102 | 400103 | CMD_SEQ_ID | F→P | Sıra numarası (0–255) |
| 200 | 400201 | STATUS_SYSTEM | P→F | 0=Boşta 1=Meşgul 2=Hata |
| 201 | 400202 | LAST_CMD_SEQ_ID | P→F | Son işlenen komut sıra no |
| 202 | 400203 | LAST_CMD_RESULT | P→F | 0=OK 1=Hata |
| 203 | 400204 | ACTIVE_SLOT | P→F | Aktif slot |
| 300 | 400301 | PAYMENT_STATUS | P→F | 0=Bekl 1=OK 2=Red 3=Timeout |
| 301 | 400302 | PAYMENT_AMOUNT | F→P | Tutar (kuruş) |
| 302 | 400303 | PAYMENT_CONFIRMED_ACK | F→P | 1=Onay alındı |
| 303 | 400304 | SALE_COMPLETED | P→F | 1=Dağıtım tamam |
| 400 | 400401 | SENSOR_PRESENCE | P→F | Müşteri varlığı |
| 401–424 | 400402–425 | STOCK_1–24 | P→F | Slot stok durumu |
| 500 | 400501 | ERROR_CODE | P→F | Hata kodu |
| 501 | 400502 | ERROR_SLOT | P→F | Hata slotu |
| 502 | 400503 | ERROR_CODE_2 | P→F | İkincil hata kodu |
| 503 | 400504 | ERROR_SLOT_2 | P→F | İkincil hata slotu |
| 504 | 400505 | ERROR_ACK | F→P | Hata okundu |
| 600 | 400601 | PLC_HEARTBEAT | P→F | PLC sağlık sayacı |
| 601 | 400602 | FLUTTER_HEARTBEAT | F→P | Uygulama sağlık sayacı |

**F→P:** Flutter yazar, PLC okur  
**P→F:** PLC yazar, Flutter okur

---

*Sorularınız için yazılım ekibiyle iletişime geçin.*
