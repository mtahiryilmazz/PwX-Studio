# 🏆 PwX Studio v2.0.0 & pwxe v2.0.0 — Grand Final Major Release (Sürüm Notları)

**PwX Studio v2.0.0** ve **pwxe v2.0.0**, projenin planlanan tüm yol haritası hedeflerini tamamlayarak nihai olgunluk ve kararlılık seviyesine ulaştığı **Grand Final Major Release** sürümüdür.

---

## 🌟 Yeni Özellikler & Geliştirmeler

### 1. Süreç İçi Çalıştırma (In-Process SMA Runspace Hosting)
- **Sıfır Alt Süreç:** PS5.1 hedefleri için harici `powershell.exe` alt süreci başlatılmadan, doğrudan `System.Management.Automation` Runspace içerisinde bellek içi çalıştırma imkanı sunar (`-HostMode InProcess` / `-InProcess`).
- **Kurumsal Güvenlik ve EDR Dostu:** Harici alt süreç oluşturma kısıtlamalarına sahip kurumsal ortamlarda ve antivirüs / EDR koruma sistemlerinde sorunsuz çalışır.
- **Parametre & Çıkış Kodu Sadakati:** AST tabanlı gelişmiş parametre çözümleme (`ScriptArguments`), betik çıkış kodlarının (`exit N`) birebir taşınması ve UTF-8 / Türkçe karakter desteği.

### 2. Sadeleştirilmiş UAC Yetki Denetimi
- Arayüzdeki UAC izin düzeyi seçenekleri herkesin anlayabileceği açık ve sade Türkçe terimlerle güncellendi:
  - **`Standart`** (`asInvoker`): Standart kullanıcı haklarıyla çalışır.
  - **`En Yüksek`** (`highestAvailable`): Kullanıcının erişebileceği en yüksek yetkiyle başlar.
  - **`Tam Yetki (Yönetici)`** (`requireAdministrator`): Yönetici ayrıcalıkları ve UAC onayı gerektirir.
- Fare ile seçim öğelerinin üzerine gelindiğinde beliren zengin `ToolTip` ile teknik manifest parametreleri ve izin kapsamı açıkça gösterilir.

### 3. Kurumsal Yük Şifreleme & Donanım Kilitleme (Payload Protection & DPAPI)
- **AES-256-CBC + HMAC-SHA256:** Gömülü betikler `PWXENC01` şifreli zarfı ile korunur; PE dosyasından düz metin kod ayıklanması engellenir.
- **Windows DPAPI Makine & Kullanıcı Kilitleme:** İsteğe bağlı olarak şifreleme anahtarı hedef Windows makinesine ve kullanıcı hesabına kilitlenerek üretilen EXE'nin izinsiz sistemlerde çalışması engellenir.

### 4. Authenticode Kod İmzalama & Evrensel Simge Enjeksiyonu
- Doğrudan `signtool.exe` (RFC 3161 zaman damgası) veya yerel `Set-AuthenticodeSignature` ile otomatik ikili dosya imzalama.
- Hem WinForms hem modern WPF/XAML formlarına çalışma zamanında dinamik simge bağlayan `Set-PwXAppIcon` altyapısı.

### 5. Yüzde Yüz CI Doğrulaması & Çok Kanallı Dağıtım
- GitHub Actions CI üzerinde tüm test senaryoları (Modül, PS7 GUI Host, Smoke testleri) %100 başarıyla tamamlandı.
- PowerShell Gallery (`pwxe`), NuGet.org ve GitHub Releases üzerinden eşzamanlı resmi yayımlama.

---

## 📦 İndirme & Sürüm Bilgileri

| Bileşen | Sürüm | Bağlantı / Yükleme Komutu |
|---|---|---|
| **PwX Studio (GUI)** | `v2.0.0` | [GitHub Releases](https://github.com/mtahiryilmazz/PwX-Studio/releases/tag/v2.0.0) |
| **pwxe (PowerShell Gallery)** | `pwxe 2.0.0` | `Install-PSResource pwxe` veya [PSGallery](https://www.powershellgallery.com/packages/pwxe/2.0.0) |
| **pwxe (NuGet.org)** | `pwxe 2.0.0` | `dotnet add package pwxe` veya [NuGet](https://www.nuget.org/packages/pwxe/2.0.0) |
| **pwxe (GitHub Packages & Releases)** | `v2.0.0` | [GitHub Releases](https://github.com/mtahiryilmazz/pwxe/releases/tag/v2.0.0) |

---

## 💾 Dağıtım Dosyaları & SHA-256 Özeti

| Dosya | Boyut | SHA-256 Özeti |
|---|---|---|
| **`PwX-Studio-v2.0.0.exe`** | 736 KB | `f27e41573a32b6441a8cd23d8b2c7ba29e0644aa2d9d38e4a6d4b012657f4d82` |
| **`PwX-Studio-v2.0.0.ps1`** | 413 KB | `1a1eafa97faeba9a4b97cfd99fa573943b0163323dfbbfb59fe52a1c5f9b204e` |
| **`SHA256SUMS.txt`** | - | `SHA256 doğrulama tablosu` |
