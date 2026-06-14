# Content Editor

Basit PyQt6 araci; soru metinlerini, secenekleri ve secenek bazli parfum
puanlama/eleme kurallarini duzenler.

## Calistirma

```powershell
python tools\content_editor.py
```

## Import

Import butonu iki dosya ister:

1. `assets/content/survey_questions.json`
2. `assets/rules/scoring_rules.json`

Editor sadece `tr` metinlerini yukler. Diger diller daha sonra AI veya baska
bir ceviri araci ile uretilebilir.

## Export

Export secilen klasore iki dosya yazar:

1. `survey_questions.json`
2. `scoring_rules.json`

Bu dosyalar mevcut Flutter uygulamasinin bekledigi formatla uyumludur.

## Validation

Export oncesinde kontrol edilenler:

- En az bir soru var mi?
- Soru id'leri benzersiz mi?
- Soru metinleri dolu mu?
- Her soruda en az iki secenek var mi?
- Secenek metinleri dolu mu?
- Secilen parfum id'leri `parfume_list.txt` listesindeki id'lerle uyumlu mu?
