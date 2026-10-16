# 🚀 PwX Studio v1.5.0 — Release Notes

**PwX Studio v1.5.0**, harici `ps2exe` modülü bağımlılığını tamamen ortadan kaldırarak **%100 yerli ve bağımsız [pwxe (PwX Engine)](https://github.com/mtahiryilmazz/pwxe)** motoruna geçiş yapılan dönüm noktası bir sürümdür. Artık PowerShell betiklerinizi hiçbir harici modül indirmeden, tamamen çevrimdışı (offline) ve yüksek performansla Windows çalıştırılabilir (`.exe`) dosyalarına dönüştürebilirsiniz.

---

## 🌟 Öne Çıkan Yenilikler

### 1. ⚙️ Tamamen Bağımsız Çekirdek Motor: [pwxe](https://github.com/mtahiryilmazz/pwxe)
- **Sıfır Dış Bağımlılık:** `ps2exe` PowerShell modülü, PSGallery indirme mekanizmaları ve harici betik bağımlılıkları tamamen kaldırıldı.
- **Tamamen Çevrimdışı (Offline) Çalışabilirlik:** İnternet erişimi olmayan kurumsal ve izole sistemlerde sorunsuz çalışır.
- **Ayrı CLI & Modül:** Çekirdek motor artık [github.com/mtahiryilmazz/pwxe](https://github.com/mtahiryilmazz/pwxe) adresinde bağımsız bir CLI ve modül olarak da sunulmaktadır (`pwxe script.ps1` veya `Install-Module pwxe`).
- **Doğrudan C# Derleme:** Windows ile yerleşik gelen `csc.exe` (Roslyn / .NET Framework) ve modern `.NET SDK` altyapısı doğrudan kullanılır.

### 2. 🎯 Çift Hedef Çalışma Zamanı (Target Runtime) Desteği
- **PowerShell 5.1 (Klasik / Hafif):**
  - Windows dahili `csc.exe` kullanılarak üretilir.
  - Ek hiçbir SDK veya runtime kurulumu gerektirmez.
  - Minimum dosya boyutu (~500 KB), ultra hafif ve hızlı `.exe` çıktısı.
- **PowerShell 7.4+ (Modern & Çapraz Platform Gücü):**
  - Modern `.NET 8 SDK` ve `Microsoft.PowerShell.SDK` ile tam uyumlu.
  - Gelişmiş PowerShell 7 dil özelliklerini ve modüllerini destekler.
- **📦 Tek Dosya (Single-File) Paketleme:**
  - PowerShell 7 hedefinde tüm runtime ve bağımlılıkları tek bir bağımsız `.exe` içine gömebilme seçeneği.

### 3. 🖼️ Gelişmiş Simge ve WinForms Entegrasyonu
- **Otomatik Form Simgesi Enjeksiyonu:** Seçilen uygulama simgesi yalnızca Windows Gezgini'ndeki `.exe` simgesini değil, aynı zamanda betik içindeki WinForms pencerelerinin başlık çubuğu ve görev çubuğu simgelerini de otomatik olarak besler.
- Çok boyutlu ICO formatı dönüştürme ve güvenli bootstrap mekanizması.

### 4. 🖥️ Tamamen Responsive & Yeniden Boyutlandırılabilir Arayüz
- Sabit pencere boyutu kilidi kaldırıldı; pencere serbestçe yeniden boyutlandırılabilir ve tam ekran yapılabilir.
- Küçük veya dizüstü ekranlar için otomatik dikey kaydırma çubuğu (`AutoScroll`) desteği eklendi.
- Yeni **"Hedef Çalışma Zamanı (pwxe)"** kontrol grubu eklendi.
- Açık (Light) ve Koyu (Dark) Lucide tema desteği korundu.

### 5. 🔄 Dinamik Başlık & EXE İsmi Senkronizasyonu
- **Gerçek Zamanlı Çıktı Güncelleme:** "Uygulama Adı / Başlık" alanında yapılan herhangi bir değişiklik, hedef `.exe` dosya adına anında yansıtılır (örn. `app-v1.ps1` seçilip başlık `app` ve sürüm `1.0.0.0` yapıldığında dosya adı kesin olarak `app.exe` olur).
- **Akıllı Betik Geçişi:** Yeni veya farklı bir `.ps1` dosyası yüklendiğinde, başlık ve hedef dosya adı otomatik olarak yeni betiğe göre güncellenir.
- **Kullanıcı Tercihi Koruması:** "Farklı Kaydet..." ile kullanıcı tarafından özel olarak belirlenen çıktı dosya yolları korunur.

### 6. 🎨 10x5 Kompakt Vektör İkon Izgarası & Popüler Kaynaklar
- İkon arama ve seçim ızgarası 10x5 ölçüsüne optimize edildi; daha fazla simge kompakt ve temiz bir düzende görüntülenir.
- Dış API bağımlılıkları kaldırılarak popüler, ücretsiz vektör ikon kütüphaneleri (Iconify, Lucide, Material) yerel vektörel önizleme ile entegre edildi.

### 7. 🛡️ CI/CD ve Kararlılık İyileştirmeleri
- GitHub Actions CI/CD test ortamında sözdizimi doğrulama ve derleme testleri %100 başarılı (yeşil) hâle getirildi.
- Hedef çalışma zamanı (PS5.1 / PS7) ile çalıştırma modları (Konsol / GUI) tamamen bağımsızlaştırıldı.
- Derleme anında pencere kapanmasına neden olan beklenmedik doğrulama ve simge işleme hataları tamamen giderildi.
- Türkçe karakter desteği (`ş, ğ, ü, ç, ö, ı, İ`) ve UTF-8 BOM kodlama kararlılığı sağlandı.

---

## 📋 Değişiklik Listesi (Changelog)

### 🗑️ Kaldırılanlar (Removed)
- `ps2exe` modül denetimi, PSGallery otomatik kurulum adımları ve `Invoke-PS2EXE` çağrıları tamamen temizlendi.
- Dış modül veya internet erişimi zorunluluğu sonlandırıldı.

### ➕ Eklenenler (Added)
- `pwxengine` dönüştürme motoru doğrudan GUI içerisine entegre edildi.
- PowerShell 5.1 ve PowerShell 7.4+ çalışma zamanı radyo butonları ve "Tek Dosya (Single-File)" onay kutusu.
- WinForms form kurucuları için güvenli `$script:PwXEmbeddedIcon` bootstrap enjeksiyonu.
- Dinamik iki yönlü başlık ve EXE dosya adı senkronizasyonu (`Add_TextChanged`).
- 10x5 vektör ikon ızgarası ve genişletilmiş ücretsiz ikon kaynakları.

### 🔧 Düzeltmeler (Fixed)
- Yeni `.ps1` seçildiğinde başlığın eski dosyada takılı kalması düzeltildi.
- Başlık değiştirildiğinde veya sürüm girildiğinde EXE adının eski betik adı kalması sorunu giderildi.
- Belirli kombinasyonlarda "EXE Oluştur"a basıldığında GUI'nin kapanma hatası giderildi.
- `pwxengine/tests/Run-Smoke.ps1` test betiğinde kasıtlı sözdizimi hatası testi (`T-009`) sonrası kalan `$LASTEXITCODE` sızıntısı giderildi.
- Dağıtım ve simge işleme sıralamasındaki zamanlama hataları düzeltildi.

---

## 📦 Dağıtım Dosyaları (Release Assets)

| Dosya Adı | Açıklama |
| :--- | :--- |
| **`PwX-Studio-v1.5.0.exe`** | Kurulum gerektirmeyen taşınabilir (portable) Windows GUI uygulaması |
| **`PwX-Studio-v1.5.0.ps1`** | Kaynak PowerShell grafik arayüz betiği |
| **`Source code (zip / tar.gz)`** | PwX Studio ve PwX Build Engine tam kaynak kodu |

---

## 💻 Sistem Gereksinimleri
- **İşletim Sistemi:** Windows 10 / 11 veya Windows Server 2016+
- **Minimum:** Windows PowerShell 5.1 (Windows ile yerleşik gelir)
- *(İsteğe Bağlı)* PowerShell 7.4+ hedefiyle derleme yapmak için: **.NET 8 SDK**
