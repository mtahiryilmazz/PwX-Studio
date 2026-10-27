# PwX Studio — Changelog

PwX Studio geliştirme sürecinde yapılan önemli değişiklikler, yeni özellikler, arayüz iyileştirmeleri ve hata düzeltmeleri bu dosyada listelenir.

Biçim: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)  
Sürümleme yaklaşımı: Semantic Versioning  
Proje: PwX Studio — PowerShell to EXE Builder

---

## [2.0.0] — 2026-10-27

### Added
- **Grand Final Major Release:** PwX Studio ve çekirdek `pwxe` derleme motoru tüm yol haritası aşamalarını tamamlayarak nihai olgunluk ve kararlılık seviyesine ulaştı.
- **pwxe 2.0.0 Entegrasyonu:** Dahili derleme motoru `pwxe v2.0.0` sürümüne yükseltildi. Gömülü motor arşivi (Base64) ve SHA-256 bütünlük kontrolü güncellendi.
- **Süreç İçi Çalıştırma (In-Process SMA Runspace Hosting):** Arayüze "Süreç İçi Çalıştırma (In-Process)" (`ChkInProcess`) seçeneği eklendi. PS51 hedefleri için harici `powershell.exe` alt süreci başlatmadan, bellek içi `System.Management.Automation` Runspace üzerinde sıfır alt süreçle çalıştırma imkanı sunar (EDR/antivirüs dostu).
- **Sadeleştirilmiş UAC Yetki Seçimi:** UAC çalıştırma düzeyi ComboBox etiketleri sade ve anlaşılır terimlerle yenilendi:
  - `Standart` (asInvoker)
  - `En Yüksek` (highestAvailable)
  - `Tam Yetki (Yönetici)` (requireAdministrator)
  - Fare üzerine gelindiğinde beliren zengin `ToolTip` ile teknik detaylar sunuldu.
- **Çift Dilli Arayüz Senkronizasyonu (TR/EN):** Yeni tüm kontroller Türkçe ve İngilizce dil paketlerine eksiksiz entegre edildi.

## [1.8.0] — 2026-10-26

### Added
- **pwxe 1.8.0 Entegrasyonu:** PwX Studio içerisindeki dahili derleme motoru `pwxe v1.8.0` sürümüne yükseltildi. Gömülü motor arşivi (Base64) ve SHA-256 bütünlük kontrolü güncellendi.
- **Yük Koruma & AES-256 Şifreleme (Payload Protection):** Arayüze "Betiği Şifrele (AES-256)" (`ChkEncryptPayload`) onay kutusu eklendi. Gömülü PowerShell betikleri `PWXENC01` şifreli zarfı (AES-256-CBC + rastgele IV + HMAC-SHA256 bütünlük doğrulama) ile derlenerek düz metin sızıntısı engellenir.
- **Makine & Kullanıcı Kilitleme (DPAPI):** Arayüze "Makineye Kilitle (DPAPI)" (`ChkBindToMachine`) onay kutusu eklendi. Şifreleme anahtarı Windows DPAPI ile mevcut makineye ve kullanıcı hesabına kilitlenerek üretilen EXE'nin başka sistemlerde çalıştırılması engellenir.
- **Çift Dilli Arayüz Senkronizasyonu (TR/EN):** Yeni şifreleme ve kilitleme seçenekleri Türkçe ve İngilizce dil paketlerine eksiksiz entegre edildi.

## [1.7.0] — 2026-10-26

### Added
- **pwxe 1.7.0 Entegrasyonu:** PwX Studio içerisindeki dahili motor `pwxe v1.7.0` sürümüne yükseltildi, dahili Base64 zip arşivi ve `.engine_hash` bütünlük takibi yenilendi.
- **Authenticode Dijital Kod İmzalama:** Arayüze Authenticode kod imzalama kartı eklendi. Windows Sertifika Deposu (Thumbprint) veya PFX/P12 dosyası ile RFC 3161 zaman damgalı otomatik imzalama desteği sağlandı. Parolalar `PasswordBox` bileşeni ile maskelenir.
- **UAC Manifest İzin Düzeyi (ExecutionLevel):** Windows uygulama bildirimine (`app.manifest`) doğrudan `asInvoker`, `requireAdministrator` veya `highestAvailable` izin düzeylerini ekleyen seçim kutusu eklendi; mevcut `ChkAdmin` onay kutusu ile çift yönlü senkronize edildi.
- **Evrensel Pencere Simgesi Enjeksiyonu (Universal Icon Injection):** Hem Windows Forms (`Form`) hem de modern WPF / XAML (`Window`) pencerelerini bellek akışı (`System.Drawing.Icon` + `BitmapFrame`) üzerinden otomatik yakalayıp simge atayan evrensel `Set-PwXAppIcon` altyapısı ve çalışma zamanı `add_Idle` dinamik kancası uygulandı.
- **Windows 11 Fluent Seçim Kutuları (ComboBox):** Tüm ComboBox ve ComboBoxItem kontrolleri, Açık ve Koyu tema fırçalarıyla (`{DynamicResource ...}`) dinamik renk alan, 6px yuvarlatılmış köşeli, zarif ok ve gölge efektli modern XAML şablonuna kavuşturuldu.

### Security & Hardening
- **Bağımsız Betik İzolasyonu (.gitignore):** Kök dizinde bulunan bağımsız kurumsal araç betikleri (`Printer_Enterprise_*.ps1`, `Ultimate_Printer_*.ps1`, `WinUtil.*`) `.gitignore` kuralıyla dışlanarak genel depoya sızma riski ortadan kaldırıldı.
- **Mükerrer ve Güvensiz Fonksiyon Temizliği:** Betik içerisindeki mükerrer ve güvensiz `Get-PwXEnginePath` / `Deploy-EmbeddedPwXEngine` bloğu (ZipSlip ve CWD script preloading açığı barındıran) kaldırılarak kanonik kök dizin denetimi yapan güvenli fonksiyon korundu.

## [1.6.4] — 2026-10-21

### Security & Hardening
- **Güvenilir Motor Arama Yolu (Search Path Planting Koruması):** `Get-PwXEnginePath` içerisindeki `(Get-Location)` (çalışma dizini), `Downloads\pwxe` ve `Desktop\pwxe` aramaları kaldırılarak arama yolu ele geçirme riski engellendi. Motor yalnızca `$PSScriptRoot`, resmi PowerShell modülü (`Get-Module pwxe`) veya doğrulanmış gömülü AppData motorundan çalıştırılır.
- **Zip Slip Koruması:** Dahili `pwxe` motoru zip arşivinden `%LOCALAPPDATA%\PwX-Studio\engine` dizinine çıkartılırken kanonik yol sınır kontrolü getirilerek dizin dışına dosya yazma zafiyeti kapatıldı.
- **Dahili Motor Otomatik Güncelleme:** Gömülü motorun SHA-256 özeti `.engine_hash` dosyası ile doğrulanarak, Studio güncellemelerinde kullanıcıların eski motoru kullanmaya devam etmesi engellendi.
- **Bilinmeyen Parametre Uyarıları:** Derleme motorunun desteklemediği parametreler sessizce yutulmak yerine canlı konsol günlüğünde kullanıcıya uyarı (`[UYARI]`) olarak bildirilir.

### Fixed
- **Temiz Ortam Başlangıç Çökmesi:** Temiz kurulumlarda ikon bulunmadığında `Deploy-EmbeddedIcon` çağrısının tanımsız fonksiyon hatası fırlatması fonksiyon sıralaması düzeltilerek giderildi.
- **Karakter Kodlaması ve Dil Butonu:** Bozuk karakter kodlamaları XML sayısal karakter referansları ve UTF-8 BOM ile tamamen düzeltildi.
- **Eksik İkon Fonksiyonları:** Web ikon indirme ve normalleştirme işlemlerinde kullanılan `Test-ImageFile`, `Save-NormalizedPng` ve `Get-IconPngCandidates` fonksiyonları uygulandı.
- **Dokümantasyon & Bağımlılık Yolları:** PR şablonu ve katkı rehberindeki eski `pwxengine` referansları `pwxe` olarak güncellendi; telif hakkı isimleri eşitlendi.
- **Depo Temizliği:** Eski sürümlere ait ikili dosyalar (`PwX-Studio-v1.6.3.exe`, `PwX-Studio-v1.6.3.ps1`) ve eski sürüm notları depodan kaldırılarak repo boyutu optimize edildi.
