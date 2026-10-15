# PwX Studio — Changelog

PwX Studio geliştirme sürecinde yapılan önemli değişiklikler, yeni özellikler, arayüz iyileştirmeleri ve hata düzeltmeleri bu dosyada kronolojik olarak listelenir.

Biçim: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)  
Sürümleme yaklaşımı: Semantic Versioning  
Proje: PwX Studio — PowerShell to EXE Builder

---

## [Unreleased]

Henüz yayımlanmamış geliştirmeler.

### Planned
- [ ] Mevcut özelliklerin kapsamlı testlerinin tamamlanması.
- [ ] Windows sürümleri ve farklı ekran ölçeklerinde arayüz testlerinin yapılması.
- [ ] Kurulum, kullanım ve sorun giderme belgelerinin tamamlanması.
- [ ] Gerçek uygulama ekran görüntülerinin hazırlanması.
- [ ] GitHub sürüm ve dağıtım paketlerinin standartlaştırılması.

> Bu bölümdeki maddeler planlanan çalışmalardır; tamamlanmış özellik olarak değerlendirilmemelidir.

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
- Önceki PS2EXE Builder PRO adlandırmasından PwX Studio markasına geçiş yapıldı.
- Uygulama başlığı ve paketleme adlandırmaları yeni marka doğrultusunda düzenlendi.
- ZIP paketleme yapısı ve proje tanıtım belgeleri PwX Studio markasına uyarlandı.

### Maintained
- ps2exe 1.0.18 sürümünü kontrol etmeye yönelik mevcut mekanizma korundu.
- EXE oluşturma işlevi korundu.
- ICO simgesi seçme işlevi korundu.
- Açık ve koyu tema desteği korundu.
- Günlük kayıt alanının kaydırılabilir yapısı korundu.

### Packaging
- PwX Studio kaynak ve dağıtım paketleri düzenlendi.
- PowerShell kaynak dosyası, logo ve README dosyası paketleme kapsamına alındı.

---

## Önceki geliştirme aşaması — PS2EXE Builder PRO

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
- ps2exe bağımlılık ve sürüm kontrolü üzerinde çalışılması.
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
- PS2EXE Builder PRO aşamasındaki her geliştirme için kesin sürüm numarası ve tamamlanma tarihi doğrulanmış değildir.
- Gerçek testlerle doğrulanmamış özellikler için kesin başarı veya uyumluluk iddiasında bulunulmaz.
- Yeni sürüm yayımlanmadan önce değişiklikler, gerçek kaynak kodu ve test sonuçlarıyla karşılaştırılmalıdır.
- Yeni sürümlerde yalnızca ilgili değişiklikler eklenmeli; eski sürüm kayıtları geriye dönük olarak değiştirilmemelidir.