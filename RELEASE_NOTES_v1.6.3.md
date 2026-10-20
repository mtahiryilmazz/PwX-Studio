# 🚀 PwX Studio v1.6.3 — Sürüm Notları

**PwX Studio v1.6.3**, kullanıcı deneyimini mükemmelleştiren **🇹🇷 TR / 🇬🇧 EN bayrak emojili dil seçimi**, **tam kapsamlı dinamik arayüz çevirisi**, **karakter kodlama (mojibake) düzeltmeleri** ve **logo erişilebilirliği** geliştirmeleriyle yayınlandı!

---

## 🌟 Yeni Özellikler & İyileştirmeler

### 1. 🇹🇷 TR / 🇬🇧 EN Bayrak Emojili Dil Seçici
- Arayüzün sağ üst köşesindeki dil butonu `🇹🇷 TR` ve `🇬🇧 EN` bayrak emojileriyle zenginleştirildi.
- Buton boyutlandırması ve padding değerleri düzenlenerek metin kırpılması tamamen engellendi.

### 2. 🌐 Dinamik ve Tam Kapsamlı Dil Değişimi
- Dil butonuna tıklandığında uygulamanın yeniden başlatılmasına gerek kalmadan tüm arayüz anında seçilen dile dinamik olarak geçer:
  - 📁 **Dosya Yapılandırması** (File Configuration)
  - 🎨 **Uygulama Logosu & Simgesi** (Application Logo & Icon)
  - ℹ️ **Uygulama Bilgileri & Meta Veriler** (Application Info & Metadata)
  - ⚙️ **Hedef Çalışma Zamanı & Uygulama Türü** (Target Runtime & Application Type)
  - 🚀 **Derleme Motoru Seçimi** (Build Engine Selection)
  - 🛠️ **Derleme & Çalışma Seçenekleri** (Build & Runtime Options)
  - ⚡ **Canlı Konsol Günlüğü & Durum Mesajları** (Live Console Log & Status Messages)
  - Araç İpuçları (ToolTips) ve Buton Metinleri

### 3. 🛡️ Karakter Kodlama ve Mojibake Düzeltmesi
- Dil butonunda ve Türkçe arayüz metinlerinde oluşabilen UTF-8 bozulmaları (mojibake) giderildi.
- Kod dosyası UTF-8 BOM standardıyla korunarak PowerShell ve WPF çalışma ortamlarında kusursuz karakter desteği garanti altına alındı.

### 4. 🖼️ Logo Dosyası (pwx_logo.png) Düzeltmesi
- Depo ana dizini ve belgeler için `ico/pwx_logo.png` görseli yüksek çözünürlüklü olarak depoya eklendi. GitHub ve harici bağlantılarda görselin 404 hatası vermesi engellendi.

---

## 📦 İndirme & Sürüm Bilgileri

| Bileşen | Sürüm | Bağlantı / Yükleme Komutu |
|---|---|---|
| **PwX Studio (GUI)** | `v1.6.3` | [GitHub Releases](https://github.com/mtahiryilmazz/PwX-Studio/releases/tag/v1.6.3) |
| **pwxe (PowerShell Gallery)** | `pwxe 1.6.2` | `Install-PSResource pwxe` veya [PSGallery](https://www.powershellgallery.com/packages/pwxe/1.6.2) |
| **pwxe (NuGet.org)** | `pwxe 1.6.2` | `dotnet add package pwxe` veya [NuGet](https://www.nuget.org/packages/pwxe/1.6.2) |
| **pwxe (GitHub)** | `v1.6.2` | [GitHub Reposu](https://github.com/mtahiryilmazz/pwxe) |

---

## 💾 Dağıtım Dosyaları

| Dosya | Açıklama |
|---|---|
| **`PwX-Studio-v1.6.3.exe`** | Sürüm etiketli bağımsız Windows yürütülebilir dosyası (~600 KB) |
| **`PwX-Studio.exe`** | Doğrudan çalıştırılabilir güncel PwX Studio binary'si |
| **`PwX-Studio-v1.6.3.ps1`** | Açık kaynak PowerShell grafik arayüz betiği (WPF tabanlı) |
