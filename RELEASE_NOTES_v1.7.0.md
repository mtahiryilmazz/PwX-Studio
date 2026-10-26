# 🚀 PwX Studio v1.7.0 & pwxe v1.7.0 — Kod İmzalama, UAC Denetimi, Evrensel İkon Enjeksiyonu ve Arayüz Modernizasyonu (Release Notes)

**PwX Studio v1.7.0** ve **pwxe v1.7.0**, Authenticode dijital kod imzalama, UAC manifest izin düzeyi denetimi, WinForms ve WPF uygulamaları için evrensel pencere simgesi enjeksiyonu, modern Windows 11 Fluent açılır seçim kutuları (ComboBox) ve kritik güvenlik sıkılaştırmaları getiren büyük bir sürümdür.

---

## 🌟 Yeni Özellikler & Geliştirmeler

### 1. Authenticode Dijital Kod İmzalama (Code Signing)
- Üretilen EXE ikili dosyalarını doğrudan `signtool.exe` (RFC 3161 zaman damgasıyla) veya yerel `Set-AuthenticodeSignature` altyapısıyla imzalama desteği eklendi.
- Arayüzden Windows Sertifika Deposu (Thumbprint / Parmak İzi) veya doğrudan `.pfx` / `.p12` sertifika dosyası seçilebilir.
- Sertifika parolası `PasswordBox` bileşeni ile maskelenir; şifreler loglara veya açık metin değişkenlerine düşmez.

### 2. UAC Çalıştırma Düzeyi (ExecutionLevel) Manifest Denetimi
- Windows uygulama bildirimine (`app.manifest`) doğrudan UAC izin düzeyi gömülür:
  - `asInvoker` (Standart kullanıcı yetkileriyle başlatma)
  - `requireAdministrator` (Yönetici yetkisi / UAC onayı ile başlatma)
  - `highestAvailable` (Kullanıcının erişebileceği en yüksek izinle başlatma)
- Arayüzdeki seçim kutusu (ComboBox) üzerinden tek tıklamayla yapılandırılabilir.

### 3. Evrensel Pencere Simgesi Enjeksiyonu (Universal Icon Injection)
- **Problem:** Bazı durumlarda paketleme yaparken ikon uygulama pencerelerine enjekte olmuyordu (özellikle WPF / XAML pencereleri, dinamik açılan formlar veya farklı yazım kalıpları).
- **Çözüm:** 
  - Hem Windows Forms (`System.Windows.Forms.Form`) hem de modern WPF / XAML (`System.Windows.Window`, `XamlReader`) mimarileri için ikili bellek akışı (`System.Drawing.Icon` + `BitmapFrame`) ile evrensel `Set-PwXAppIcon` enjektörü oluşturuldu.
  - Regex eşleşmesi olmasa dahi çalışma zamanında açılan tüm pencereleri yakalayan otomatik `Application.add_Idle` dinamik kancası eklendi.

### 4. Windows 11 Fluent Seçim Kutuları (ComboBox) & Arayüz Tasarımı
- Arayüzdeki tüm seçim kutuları (ComboBox) ve açılır menü öğeleri (ComboBoxItem) Windows 11 Fluent çizgilerine uyarlandı.
- 6px yuvarlatılmış köşeler, hafif gölge efekti, pürüzsüz ok simgesi, Açık Tema ve Koyu Tema geçişlerinde dinamik fırçalarla (`{DynamicResource ...}`) kusursuz renk adaptasyonu sağlandı.

### 5. Güvenlik Sıkılaştırma & Sızıntı Koruması
- Kök dizindeki bağımsız kurumsal araç betikleri (`Printer_Enterprise_*.ps1`, `Ultimate_Printer_*.ps1`, `WinUtil.*`) `.gitignore` kuralıyla dışlanarak genel GitHub reposuna kazara sızmaları kesin olarak engellendi.
- Betik içerisindeki mükerrer ve güvensiz `Get-PwXEnginePath` / `Deploy-EmbeddedPwXEngine` bloğu (ZipSlip ve CWD script preloading açığı barındıran) kaldırıldı; kanonik kök dizin denetimi yapan güvenli fonksiyon korundu.

---

## 📦 İndirme & Sürüm Bilgileri

| Bileşen | Sürüm | Bağlantı / Yükleme Komutu |
|---|---|---|
| **PwX Studio (GUI)** | `v1.7.0` | [GitHub Releases](https://github.com/mtahiryilmazz/PwX-Studio/releases/tag/v1.7.0) |
| **pwxe (PowerShell Gallery)** | `pwxe 1.7.0` | `Install-PSResource pwxe` veya [PSGallery](https://www.powershellgallery.com/packages/pwxe/1.7.0) |
| **pwxe (NuGet.org)** | `pwxe 1.7.0` | `dotnet add package pwxe` veya [NuGet](https://www.nuget.org/packages/pwxe/1.7.0) |
| **pwxe (GitHub Packages & Releases)** | `v1.7.0` | [GitHub Releases](https://github.com/mtahiryilmazz/pwxe/releases/tag/v1.7.0) |

---

## 💾 Dağıtım Dosyaları

| Dosya | Açıklama |
|---|---|
| **`PwX-Studio-v1.7.0.exe`** | Sürüm etiketli bağımsız Windows yürütülebilir dosyası (669 KB) |
| **`PwX-Studio-v1.7.0.ps1`** | Açık kaynak PowerShell grafik arayüz betiği (WPF) |
