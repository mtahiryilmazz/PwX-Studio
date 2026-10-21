# 🛡️ PwX Studio v1.6.4 & pwxe v1.6.4 — Güvenlik & Kararlılık Sürümü (Release Notes)

**PwX Studio v1.6.4** ve **pwxe v1.6.4**, kapsamlı güvenlik denetimi bulgularını gideren, temiz makinelerdeki başlangıç çökmesini çözen, güvenli motor arama ve Zip Slip korumaları getiren kritik bir güvenlik ve kararlılık sürümüdür.

---

## 🔒 Güvenlik İyileştirmeleri (Security Hardening)

### 1. Güvenilir Motor Arama Yolu (Search Path / Planting Koruması)
- `Get-PwXEnginePath` içerisindeki `(Get-Location)` (çalışma dizini), `Downloads\pwxe` ve `Desktop\pwxe` gibi güvenilmez konumlardan arama mantığı tamamen kaldırıldı.
- Motor artık yalnızca doğrudan geliştirici dizininden (`$PSScriptRoot`), resmi kurulu modülden (`Get-Module pwxe`) veya doğrulanmış dahili gömülü motordan çalıştırılır.
- Kötü amaçlı bir betiğin İndirilenler klasörüne veya çalışma dizinine yerleştirilerek kod yürütmesi riski ortadan kaldırıldı.

### 2. PWX_ERROR_LOG İstismarının Önlenmesi
- C# PS7 host çalışma zamanında `PWX_ERROR_LOG` ortam değişkeniyle hata mesajının keyfi bir dosyaya eklenmesi (`AppendAllText`) kanalı, üretim (Release) EXE'lerinden tamamen kaldırıldı (`#if DEBUG || PWX_TESTHOOKS` koşuluna bağlandı).
- Yönetici ayrıcalıklarıyla çalışan uygulamaların düşük yetkili süreçler tarafından dosya manipülasyonuna maruz bırakılması engellendi.

### 3. Dahili Motor Zip Slip Koruması & Otomatik Güncelleme
- Gömülü `pwxe` motoru `%LOCALAPPDATA%\PwX-Studio\engine` dizinine çıkartılırken tam yol (canonical path) doğrulaması eklendi; zip dizin dışına taşma (Zip Slip) engellendi.
- Motor arşivinin SHA-256 bütünlük kontrolü `.engine_hash` dosyasıyla takip edilerek, PwX Studio güncellendiğinde mevcut kullanıcıların eski motoru kullanmaya devam etmesi sorunu çözüldü.

### 4. Güvenli Log Dizini
- Motor loglarının varsayılan konumu, standart kullanıcıların yazma iznine sahip olduğu `%LOCALAPPDATA%\pwxe\logs` (ve `%TEMP%\pwxe\logs` yedeği) olarak güncellendi. `Install-Module -Scope AllUsers` ile kurulan ortamlardaki yetki hataları (`PWX9000`) giderildi.

### 5. API Anahtarları ve CI/CD Güvenliği
- `Publish-Package.ps1` ve GitHub Actions yayın iş akışında API anahtarlarının komut satırında ve süreç listesinde görünmesi engellendi; ortam değişkenleri üzerinden güvenli aktarım sağlandı.
- `release.yml` iş akışına zorunlu test kontrolü (CI gate) ve etiket-sürüm eşleşme doğrulaması eklendi.

---

## 🛠️ Hata Düzeltmeleri & Geliştirmeler

- **Başlangıç Çökmesi Giderildi:** Temiz ortamlarda ikon dosyası bulunmadığında `Deploy-EmbeddedIcon` fonksiyonunun çağrılmadan önce tanımlanmış olması sağlandı.
- **Dil Butonu & Karakter Kodlama:** Bozuk `???? TR` karakterleri ve mojibake durumları giderildi; XML sayısal karakter referansları ve UTF-8 BOM ile tam kararlılık sağlandı.
- **Eksik Fonksiyonlar:** İkon arama ve SVG dönüşüm yedeğinde kullanılan `Test-ImageFile`, `Save-NormalizedPng` ve `Get-IconPngCandidates` fonksiyonları eksiksiz uygulandı.
- **win-x86 Mimari Desteği:** `pwxe.psm1` modülündeki `Invoke-Pwxe` komutunun mimari doğrulama kümesine `win-x86` eklendi.
- **Destek Sonu Bildirimi:** .NET 8 LTS desteğinin Kasım 2026'da sona ereceği ve .NET 10 LTS geçiş planı belgelere eklendi.

---

## 📦 İndirme & Sürüm Bilgileri

| Bileşen | Sürüm | Bağlantı / Yükleme Komutu |
|---|---|---|
| **PwX Studio (GUI)** | `v1.6.4` | [GitHub Releases](https://github.com/mtahiryilmazz/PwX-Studio/releases/tag/v1.6.4) |
| **pwxe (PowerShell Gallery)** | `pwxe 1.6.4` | `Install-PSResource pwxe` veya [PSGallery](https://www.powershellgallery.com/packages/pwxe/1.6.4) |
| **pwxe (NuGet.org)** | `pwxe 1.6.4` | `dotnet add package pwxe` veya [NuGet](https://www.nuget.org/packages/pwxe/1.6.4) |
| **pwxe (GitHub Packages & Releases)** | `v1.6.4` | [GitHub Releases](https://github.com/mtahiryilmazz/pwxe/releases/tag/v1.6.4) |

---

## 💾 Dağıtım Dosyaları

| Dosya | Açıklama |
|---|---|
| **`PwX-Studio-v1.6.4.exe`** | Sürüm etiketli bağımsız Windows yürütülebilir dosyası |
| **`PwX-Studio-v1.6.4.ps1`** | Açık kaynak PowerShell grafik arayüz betiği (WPF) |
