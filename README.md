# Personal Chat UI

Modern, duyarlı ve akışlı (streaming) mesaj deneyimi sunan bir Flutter sohbet arayüzü. Çoklu sohbet oturumları, model seçimi, dosya ekleri, sürükle-bırak, görsel kitaplığı, arama ve tema desteği ile birlikte gelir.

- Platformlar: Flutter Web, Masaüstü, Mobil
- Durum yönetimi: GetX (reaktif Rx)
- Tema: Karanlık/Açık
- Duyarlı tasarım: Sizer + LayoutBuilder

## Ekran Görüntüleri

- Ana sayfa ve sohbet

  <img width="1279" height="690" alt="1" src="https://github.com/user-attachments/assets/e64e1312-2fac-4e17-954f-16a21a2dbeac" />

- Model seçimi

<img width="969" height="754" alt="image" src="https://github.com/user-attachments/assets/f7e44276-6123-44bd-b0cb-013d5b015c17" />

- Dosya ekleme ve sürükle-bırak

  <img width="1698" height="625" alt="image" src="https://github.com/user-attachments/assets/3efc921b-2aa6-4a35-bf48-3d8dce254ce9" />

- Sohbet geçmişi ve arama
  
  <img width="1096" height="836" alt="image" src="https://github.com/user-attachments/assets/cb26cf6c-22dd-403f-8267-109c03d84b6a" />

- Görsel kitaplığı

  <img width="1799" height="1022" alt="image" src="https://github.com/user-attachments/assets/bd86cb09-d81c-451c-9298-2d2070bf6e96" />

  <img width="1809" height="1027" alt="image" src="https://github.com/user-attachments/assets/8b99dd14-50ba-479e-bf0f-3b01a8f90bad" />

- Premium planlar (temsili)

<img width="980" height="754" alt="image" src="https://github.com/user-attachments/assets/d03a351c-f245-4b71-b08f-756a14cf31cc" />

- Karanlık/Açık tema

<img width="2556" height="1590" alt="image" src="https://github.com/user-attachments/assets/2cd58572-67aa-4558-95a6-6a403bedb670" />

## Özellikler

- Çoklu sohbet oturumu
  - Oturum başlıkları, en son aktiviteye göre sıralama
  - Boş oturum koruma ve “Yeni sohbet” davranışı
- Akışlı (streaming) yanıt
  - Asistan mesajı canlı tokenlarla akar
  - “Düşünüyor” (mantık yürütme) durumu ve nabız animasyonu
  - Akışı iptal et (Stop)
- Model seçimi ve yetenek farkındalığı
  - Model meta verileri, rozetler: Reasoning, File Inputs, Audio Inputs
  - Oturum bazlı model geçmişi (logo ızgarası olarak geçmişte kullanılanlar)
  - Dosya/Audio yeteneği yoksa ilgili butonlar devre dışı
- Girdi çubuğu
  - Enter: Gönder, Shift+Enter: Yeni satır
  - Düşün (Mantık yürüt) butonu — sadece destekleyen modeller için
  - Dosya ekleri: seçim + simüle yükleme ilerlemesi
  - Global yükleme ilerleme çubuğu
  - Web’de sürükle-bırak (drop overlay + dashed border)
- Görsel kitaplığı
  - Tüm oturumlardaki görsel eklerini toplar (png/jpg/jpeg/webp/gif)
  - Grid görünümü ve büyük önizleme
  - “Sohbette aç” ve (Web) “İndir” eylemleri
- Sohbet arama
  - Oturum başlıklarında arama
  - Tarihsel gruplama: Bugün, Dün, Önceki 7 Gün, Daha Eski
- Duyarlı yerleşim
  - Geniş ekranda yan panel, dar ekranda Drawer
- Tema
  - Karanlık/Açık tema, Google Fonts (Montserrat)
- İnteraktif hoş geldin ekranı
  - Mesaj yokken yazı makinesi efektiyle placeholder

## Model Çeşitliliği

Farklı sağlayıcılardan çok sayıda model desteklenir ve her oturumda seçilen modele göre arayüz dinamik olarak uyarlanır.

- Sağlayıcılar (vendor’lar):
  - xAI: Grok 3, Grok 4
  - Anthropic: Claude Sonnet / Haiku / Opus serileri (4, 4.5, 4.1)
  - DeepSeek: R1
  - Google: Gemini 2.5 Pro, Gemini 2.5 Flash
  - OpenAI: GPT-5, GPT-4o, GPT-4.1, o3, o4-mini

- Model Geçmişi:
  - Bir oturumda kullanılan modeller sırasıyla kaydedilir.
  - Sidebar ve arama dialogunda en fazla 4 benzersiz logo 2x2 grid olarak gösterilir.
  - Aynı model art arda seçilirse tekrar eklenmez.
  
- Model Seçimi:
  - Sağlayıcı (şirket) başlıkları altında gruplanır.
  - Her model satırında: logo, ad, kısa açıklama, yetenek ikonları (psikoloji / ataş / mikrofon).
  - Modeller fonksiyonlarına göre filtrelenebilir (Mantık yürütme, dosya okuma, ses algılama).

- Reasoning Akışı:
  - “Mantık yürüt” aktifse cevap başlamadan kısa bir “Düşünüyor” placeholder’ı pulse animasyonu ile gösterilir.
  - Akış iptal edilirse o ana kadar gelen tokenlar commit edilir veya boş kalır.

- Örnek Yetenek Matrisi (özet):
  - Grok 4: mantık yürütme + dosya okuma + ses algılama + metin girdiler
  - DeepSeek R1: mantık yürütme + metin girdiler 
  - GPT-5: dosya okuma + ses algılama + metin girdiler
  - o3: Reasoning + dosya okuma + ses algılama + metin girdiler
  - o4-mini: metin girdiler

## Hızlı Başlangıç

- Gereksinimler: Flutter 3.x+, Dart 3.x
- Paketler: get, flutter_svg, google_fonts, file_selector, http, universal_html

1) Bağımlılıkları yükleyin
- flutter pub get

2) Çalıştırın
- flutter run
- Web için: flutter run -d chrome

## Proje Yapısı

- lib/
  - main.dart: Uygulama girişi, Theme/Sidebar/Chat controller’larının bind edilmesi
  - core/theme/app_theme.dart: Açık/Karanlık tema
  - controllers/
    - chat_controller.dart: Oturumlar, mesajlar, akış, model geçmişi, düşünme modu, galeri
    - sidebar_controller.dart: Yan panel açık/kapalı
    - theme_controller.dart: Tema modu
  - models/chat_message.dart: ChatMessage, Attachment
  - services/chat_service.dart: Simüle akışlı yanıt (gerçek API ile değiştirilebilir)
  - enums/app.enum.dart: Sabit yazılar, planlar, modeller, yetenekler ve yardımcılar
  - ui/
    - pages/home_page.dart: Üst bar, layout, Drawer/Sidebar, ChatArea
    - widgets/: InputBar, MessageBubble, SidebarPanel, ModelGrid, DropOverlay, ContentDropzone, GalleryGrid…
    - dialogs/: SelectModelDialog, SearchChatsDialog, LibraryDialog, PremiumDialog

## Mimari ve Akış

- GetX Rx ile reaktif mimari
  - ChatController: 
    - Oturum listesi ve aktif oturum
    - Akış durumu (isStreaming), canlı metin (streamText)
    - Oturum başına modelId, modelHistory, thinkingEnabled
    - Global yükleme durumu (isUploading, uploadProgress)
  - Mesaj gönderme:
    - Kullanıcı mesajını ekle, asistan placeholder mesajı oluştur
    - (İsteğe bağlı) düşünme gecikmesi, ardından ChatService’den token akışı
    - Bittiğinde veya iptalde tek seferde commit
- Dosya ekleri
  - file_selector ile seçim; DropOverlay + ContentDropzone ile web’de sürükle-bırak
  - Ekler simüle zamanlayıcıyla yüklenir; global ilerleme barı güncellenir
  - Seçilen model dosya desteklemiyorsa ekleri temizleme sinyali
- Görsel kitaplığı
  - Tüm oturumlardan görsel uzantıları filtrelenir
  - Yeni > Eski sırası, grid ve büyük önizleme
  - Web’de indir, sohbette aç
- Arama
  - Oturum başlıklarını filtreleme, güncelleme tarihine göre gruplama

## Gerçek API ile Entegrasyon

services/chat_service.dart içindeki streamCompletion’ı gerçek bir sağlayıcıyla değiştirin:
- API’den gelen tokenları Stream<String> olarak yayınlayın
- Hata durumunda onError’da akışı iptal edip mevcut metni commit edin
- Dosya ekleri için gerçek yükleme mantığını entegre edin (Upload API)

Örnek uç noktalar:
- POST /chat/completions (stream=true)
- WebSocket/SSE ile token bazlı yayın

## Kullanım İpuçları

- Enter: Gönder, Shift+Enter: Yeni satır
- “Mantık yürüt” sadece reasoning destekli modellerde aktif olur
- Model değiştirince:
  - Düşünme modu sıfırlanır
  - Dosya desteği olmayan modele geçildiğinde mevcut ekler temizlenir
