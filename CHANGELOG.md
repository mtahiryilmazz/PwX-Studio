# PwX Studio — Changelog

PwX Studio geliştirme sürecinde yapılan önemli değişiklikler, yeni özellikler, arayüz iyileştirmeleri ve hata düzeltmeleri bu dosyada kronolojik olarak listelenir.

Biçim: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)  
Sürümleme yaklaşımı: Semantic Versioning  
Proje: PwX Studio — PowerShell to EXE Builder

---

## [Unreleased]

## [1.6.3] — 2026-10-20

### Added
- **🇹🇷 TR / 🇬🇧 EN Bayrak Emojili Dil Seçici:** Arayüz başlığındaki dil seçici butonuna bayrak emojileri (`🇹🇷 TR` / `🇬🇧 EN`) eklendi, buton boyutlandırması ve görsel düzeni iyileştirildi.
- **Tam Kapsamlı Dinamik Dil Değişimi:** İngilizce (`🇬🇧 EN`) seçildiğinde tüm arayüz bileşenleri (kart başlıkları, dosya seçimi yönergeleri, logo/ikon alanı, hedef çalışma zamanı ve türü, derleme seçenekleri onay kutuları, konsol günlüğü, araç ipuçları ve durum metinleri) anında İngilizce'ye çevrilir; `🇹🇷 TR` seçildiğinde eksiksiz Türkçe'ye geri döner.

### Fixed
- **Dil Seçim Butonundaki Karakter Kodlama Hatası (Mojibake):** Dil butonundaki bozuk karakter gösterimi giderildi, dosya UTF-8 BOM standardı ile kaydedilerek Türkçe karakterler ve bayrak emojileri Windows ortamlarında hatasız hale getirildi.
- **Logo Dosyası ve Görünürlük (404) Düzeltmesi:** GitHub deposunda ve belgelerde bağlantısı verilen `ico/pwx_logo.png` dosyası yüksek çözünürlüklü olarak depoya eklendi, logo görüntüleme hatası giderildi.

## [1.6.2] — 2026-10-20

### Added
- **Çift Dil Desteği (TR / EN):** Arayüz üst başlığına dinamik dil değiştirme butonu (`🌐 TR` / `🌐 EN`) eklendi. Tüm etiketler, araç ipuçları, butonlar ve durum mesajları uygulama yeniden başlatılmadan anında Türkçe ve İngilizce arasında değiştirilebilir.
- **pwxe v1.6.2 Motor Güncellemesi:** Dahili gömülü motor temiz İngilizce ASCII standardizasyonuna, Türkçe Windows uyumluluğuna ve NuGet/PSGallery ile tam senkronize güncel `pwxe` v1.6.2 sürümüne yükseltildi.

## [1.6.1] — 2026-10-20

### Added
- **Dahili Gömülü Motor (Embedded Fallback):** `pwxe` derleme motorunun çekirdek betikleri ve C# host şablonları PwX Studio içine gömüldü. Dış klasör olmadan %100 taşınabilir (offline) çalışma sağlandı.
- **Arayüz Seçeneği:** Sol sütundaki hedef çalışma zamanı alanına **"Dahili pwxe Motoru (Taşınabilir / Offline)"** onay kutusu eklendi.
- **Akıllı Motor Arama (Smart Resolution):** Sistem modülleri, geliştirici çalışma alanları (`Documents\Github\pwxe`) ve AppData dizinleri otomatik taranır.
- **Logo ve İkon Entegrasyonu:** `ico\PwX-Studio.ico` dosyası derleme parametresi olarak `.exe` dosya simgesine ve WPF pencere başlığına entegre edildi.

### Fixed
- **WPF Thread Access Hatası:** PowerShell konsolu ve çoklu iş parçacığı senaryolarında `Application.ShutdownMode` üzerinden oluşan erişim hatası güvenli hale getirildi.
- Exe dosyası masaüstüne taşındığında motor bulunamama sorunu giderildi.

## [1.6.0] — 2026-10-19

### Added
- PwX Studio seçenekleri pwxe motoruna gerçek parametreler olarak bağlandı: x86/x64, yönetici yetkisi, DPI, Windows uyumluluğu, uzun yollar, EXE.config, UTF-8/Unicode ve çıktı bastırma.
- PS7 FrameworkDependent + SingleFile küçük dağıtım seçeneği.
- PS5.1, PS7 Console, PS7 GUI, negatif senaryolar ve log doğrulamasını kapsayan test matrisi.

### Changed
- SelfContained varsayılan olarak korundu; FrameworkDependent açık bir küçük boyut seçeneği olarak kaldı.
- Runtime gereksinimleri build-machine ve target-machine olarak belgelerde ayrıştırıldı.

Henüz yayımlanmamış geliştirmeler.

### Added
- Studio seçenekleri pwxe motoruna bağlandı: x86/x64, yönetici, DPI, Windows uyumluluğu, uzun yollar, EXE.config, UTF-8/Unicode ve çıktı bastırma.
- PS7 FrameworkDependent + SingleFile kombinasyonu desteklendi.
- PS7: eksik .NET SDK 8+ veya NuGet kaynağı algılanırsa onay penceresiyle otomatik kurulum/düzeltme teklifi
- PS7: **"Küçük boyut"** (`FrameworkDependent`) onay kutusu; hedefte .NET 8 Runtime gerekir (`pwsh` gerekmez)

### Fixed
- Pencere küçük ve yüksek DPI'lı ekranlara (ör. 15.6") sığacak şekilde sınırlandı; başlık çubuğu/butonlar ekran dışında kalmıyor
- Derleme hatalarında motorun gerçek hata metni gösteriliyor (önceden olmayan `$res.Error` alanı okunuyordu)
- Gömülü `pwxe` kopyası güncel motorla eşitlendi; Studio artık önce bağımsız `pwxe` klasörünü (kardeş dizin) veya kurulu modülü tercih ediyor
- PS7 varsayılanı `SelfContained` olarak korundu; önceki README'deki "FrameworkDependent varsayılan, `pwsh` gerekir" ifadeleri düzeltildi
- Depo köküne yanlışlıkla eklenen `.patch` dosyaları kaldırıldı

### Planned
- [ ] Windows sürümleri ve farklı ekran ölçeklerinde arayüz testlerinin yapılması.
- [ ] Kurulum, kullanım ve sorun giderme belgelerinin tamamlanması.
- [ ] Gerçek uygulama ekran görüntülerinin hazırlanması.
- [ ] GitHub sürüm ve dağıtım paketlerinin standartlaştırılması.

> Bu bölümdeki maddeler planlanan çalışmalardır; tamamlanmış özellik olarak değerlendirilmemelidir.

## [1.5.0] — 2026-10-16

### Removed
- **Harici Bağımlılıklar Tamamen Kaldırıldı:** Eski dönüştürücü modül bağımlılıkları, PSGallery indirme mekanizmaları, harici çağrılar ve tüm ilişkili parametre eşlemeleri projeden tamamen temizlendi.
- Dış modül veya internetten modül çekme zorunluluğu sonlandırıldı.

### Added
- **%100 Yerli PwX Build Engine:** PwX Studio'nun tek ve bağımsız dönüştürme motoru olarak `pwxengine` doğrudan entegre edildi.
- **Hedef Çalışma Zamanı (Target Runtime) Seçimi:**
  - **PowerShell 5.1:** Windows dahili `csc.exe` C# derleyicisiyle sıfır bağımlılıkla hafif ve yerel `.exe` üretimi.
  - **PowerShell 7.4+:** Modern `.NET 8 SDK` ve `Microsoft.PowerShell.SDK` ile self-contained `.exe` üretimi.
  - **Tek Dosya (Single-File):** PowerShell 7 için tüm çalışma zamanını tek bir `.exe` içerisine paketleme desteği.
- **Dinamik Hedef Arayüzü:** "Hedef Çalışma Zamanı (PwX Build Engine)" grubu eklendi; PS7 seçildiğinde Tek Dosya seçeneği dinamik olarak aktifleşir.
- **Dinamik Başlık ve EXE Adı Senkronizasyonu:** "Uygulama Adı / Başlık" alanında yapılan düzenlemeler, çıktı `.exe` dosyasının adını anlık (`Add_TextChanged`) olarak günceller; özel sürüm veya adlandırmalar doğrudan hedef dosyaya yansıtılır.
- **10x5 Kompakt Vektör İkon Izgarası:** İkon arama ve önizleme alanı 10x5 düzenine genişletildi, simgelerin daha düzenli, kompakt ve akıcı listelenmesi sağlandı.
- **Ücretsiz & Popüler Vektör İkon Kaynakları:** Harici API zorunlulukları kaldırılarak ücretsiz ve zengin ikon kaynakları önceliklendirildi.

### Changed
- PwX Studio tamamen harici paket bağımlılıksız, çevrimdışı çalışabilen bağımsız bir yapıya kavuşturuldu.
- **Responsive & Sizable Pencere:** Sabit boyut kilidi kaldırıldı; pencere serbestçe yeniden boyutlandırılabilir, tam ekran yapılabilir hâle getirildi ve küçük ekranlar için dinamik kaydırma çubuğu (`AutoScroll`) eklendi.
- **Motor Ayrıştırması (pwxe):** Çekirdek derleme motoru `pwxe` olarak adlandırılarak [github.com/mtahiryilmazz/pwxe](https://github.com/mtahiryilmazz/pwxe) adresinde bağımsız bir CLI & modül deposuna ayrıldı; PwX Studio hem sistemdeki `pwxe` modülünü hem de dahili kopyayı destekleyen hibrit yapıya kavuşturuldu.
- **Betik Değişiminde Otomatik Yenileme:** Kullanıcı yeni veya farklı bir `.ps1` dosyası seçtiğinde, uygulama adı ve hedef EXE adı yeni seçilen dosya adıyla otomatik olarak güncellenir.
- **Bağımsız Çalışma Zamanı ve Konsol Modu:** PowerShell 5.1 / PowerShell 7 seçimi ile Konsol / GUI (Pencere) modu seçimleri birbirinden bağımsız, birbirini ezmeyen uyumlu bir yapıya kavuşturuldu.
- Uygulama marka başlığı `PwX Studio v1.5.0` olarak güncellendi.

### Fixed
- Farklı `.ps1` dosyaları yüklendiğinde uygulama adının eski seçilen dosyada takılı kalma sorunu giderildi.
- "Uygulama Adı" değiştirildiğinde veya sürüm numarası girildiğinde dosya adının eski betik adı olarak kalması sorunu çözüldü; doğrudan kullanıcının yazdığı isimle derlenmesi sağlandı.
- Belirli kombinasyonlarda "EXE Oluştur" butonuna basıldığında uygulamanın beklenmedik şekilde kapanmasına yol açan doğrulama ve enjeksiyon hataları giderildi.
- `pwxengine/tests/Run-Smoke.ps1` test betiğinde kasıtlı sözdizimi reddi (`T-009`) sonrası kalan `$LASTEXITCODE = 1` sızıntısı giderildi; açık `exit 0` eklenerek GitHub Actions Windows CI süreci (Run #31) tamamen başarılı (yeşil) hâle getirildi.
- Arayüz içindeki tüm User-Agent istemci tanımlayıcıları `PwX-Studio/1.5.0` olarak güncellendi.
- Türkçe karakterler (`ş, ğ, ü, ç, ö, ı, İ`) ve UTF-8 BOM kodlama uyumluluğu korundu.

### Governance & Community
- MIT Açık Kaynak Lisansı (`LICENSE`) projeye tanımlandı.
- GitHub topluluk standartları eklendi: Hata Bildirimi (Bug Report), Özellik İsteği (Feature Request), PR Şablonu, `CONTRIBUTING.md` ve `SECURITY.md`.
- Temiz ve kapsamlı `.gitignore` yapılandırması oluşturuldu.

---

## [1.4.2] — 2026-10-15

### Fixed
- EXE simgesi entegrasyonunda işlem sırası kaynaklı sorunlar giderildi.
- Kaynak PowerShell betiği işlenmeden önce ICO dosyasının hazırlanması sağlandı.
- Simge atama işleminin zamanlaması ve uygulama sırası iyileştirildi.
- WinForms formlarına simge uygulama sürecindeki sorunları gidermeye yönelik düzenlemeler yapıldı.

### Added
- Form algılama sürecini incelemeye yardımcı günlük kayıtları eklendi.
- Simge uygulama işleminin takibini kolaylaştıran hata ayıklama düzenlemeleri yapıldı.

---

## [1.4.1] — 2026-10-15

### Added
- Seçilen ICO simgesini oluşturulan EXE dosyasına entegre etmeye yönelik geliştirmeler yapıldı.
- WinForms tabanlı formlara uygulama simgesi atama desteği hedeflendi.

### Changed
- Simge işleme ve form simgesi atama akışı geliştirildi.

### Notes
- Bu sürümdeki simge entegrasyonu çalışmalarının ardından işlem sırası sorunları tespit edildi ve sonraki sürümde düzeltildi.

---

## [1.4.0] — 2026-10-15

### Added
- PwX Studio marka kimliği projeye uygulandı.
- PwX Studio adı ve görsel kimliği için düzenlemeler yapıldı.
- Marka adıyla uyumlu dağıtım dosyaları hazırlandı.

### Changed
- Önceki prototip adlandırmasından PwX Studio markasına geçiş yapıldı.
- Uygulama başlığı ve paketleme adlandırmaları yeni marka doğrultusunda düzenlendi.
- ZIP paketleme yapısı ve proje tanıtım belgeleri PwX Studio markasına uyarlandı.

### Maintained
- Sürüm kontrolüne yönelik mevcut mekanizma korundu.
- EXE oluşturma işlevi korundu.
- ICO simgesi seçme işlevi korundu.
- Açık ve koyu tema desteği korundu.
- Günlük kayıt alanının kaydırılabilir yapısı korundu.

### Packaging
- PwX Studio kaynak ve dağıtım paketleri düzenlendi.
- PowerShell kaynak dosyası, logo ve README dosyası paketleme kapsamına alındı.

---

## Önceki geliştirme aşaması — Prototip Süreci

### Core
- PowerShell tabanlı masaüstü uygulamasının geliştirilmesi.
- Windows Forms (WinForms) tabanlı Türkçe kullanıcı arayüzünün oluşturulması.
- PowerShell betiklerini EXE dosyasına dönüştürmeye yönelik temel iş akışının oluşturulması.
- Derleme sürecinin uygulama arayüzünden yönetilmesi.

### Interface
- Türkçe kullanıcı arayüzünün hazırlanması.
- Güneş ve ay simgeleriyle açık/koyu tema geçişi tasarlanması.
- Ayrı görünüm menüsü yerine doğrudan tema değiştirme düğmesinin kullanılması.
- Pencere yeniden boyutlandırma ve responsive yerleşim iyileştirmeleri.
- Kısa ekranlarda kullanılabilirliği artırmaya yönelik kaydırma düzenlemeleri.

### Build and Icon Management
- Bağımlılık ve sürüm kontrolü üzerinde çalışılması.
- Kaynak PowerShell dosyası seçme ve EXE oluşturma akışının geliştirilmesi.
- EXE simgesi seçimi ve simgenin çıktı dosyasına uygulanması üzerinde çalışılması.
- Derleme günlüklerinin görüntülenmesi ve hata ayıklama sürecinin iyileştirilmesi.

### Architecture Research
- Mevcut PowerShell ve WinForms tabanlı çözümün ana araç olarak korunması.
- PoshToExe yaklaşımının alternatif C# tabanlı çözüm olarak değerlendirilmesi.
- Visual Studio 2022 ve C#/.NET masaüstü altyapısıyla alternatif motor geliştirme olanaklarının incelenmesi.
- İki yaklaşımın özellik ve test sonuçları bakımından karşılaştırılması hedefinin belirlenmesi.

---

## Sürüm geçmişi hakkında

- Bu kayıt, önceki geliştirme çalışmalarından elde edilen bilgilere göre hazırlanmıştır.
- Prototip aşamasındaki her geliştirme için kesin sürüm numarası ve tamamlanma tarihi doğrulanmış değildir.
- Gerçek testlerle doğrulanmamış özellikler için kesin başarı veya uyumluluk iddiasında bulunulmaz.
- Yeni sürüm yayımlanmadan önce değişiklikler, gerçek kaynak kodu ve test sonuçlarıyla karşılaştırılmalıdır.
- Yeni sürümlerde yalnızca ilgili değişiklikler eklenmeli; eski sürüm kayıtları geriye dönük olarak değiştirilmemelidir.
