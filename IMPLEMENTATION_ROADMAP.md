# PwX Studio — Implementation Roadmap
## PS2EXE'den Bağımsız EXE Dönüştürme Motoru

| Belge bilgisi | Değer |
|---|---|
| Proje | PwX Studio |
| Modül | PwX Build Engine |
| Mevcut kararlı sürüm | v1.4.2 |
| Belge sürümü | 1.0 |
| Belge tarihi | 15.10.2026 |
| Belge durumu | Uygulama öncesi teknik yol haritası |
| Hedef işletim sistemi | Windows |
| Hedef çalışma ortamları | Windows PowerShell 5.1 ve PowerShell 7 |
| Öncelikli hedef | PS2EXE'den bağımsız, güvenilir ve mümkün olduğunca gömülü EXE üretimi |

---

## 1. Projenin amacı

PwX Studio'nun mevcut çalışan grafik arayüzünü koruyarak PowerShell betiklerini Windows yürütülebilir dosyalarına dönüştüren bağımsız bir motor geliştirmek.

Yeni motorun adı **PwX Build Engine** olacaktır.

Motorun amacı yalnızca bir PowerShell betiğini EXE dosyasına sarmalamak değil; aşağıdaki özellikleri kontrollü biçimde sağlayabilen sürdürülebilir bir paketleme altyapısı oluşturmaktır:

- PowerShell betiklerini EXE biçiminde paketleme.
- PowerShell 5.1 ve PowerShell 7 için ayrı hedefler sunma.
- PowerShell 7 hedefinde çalışma ortamını mümkün olduğunca EXE dağıtımına dahil etme.
- Komut satırı parametrelerini ve çıkış kodlarını doğru aktarma.
- Konsol ve GUI çalışma modlarını destekleme.
- İkon, sürüm bilgileri ve dosya metaverileri ekleme.
- Derleme günlükleri, hata raporları ve ön kontrol sistemi sunma.
- Modül ve harici dosya bağımlılıklarını yönetmeye yönelik altyapı oluşturma.
- Üçüncü taraf lisanslarını takip etme.
- İnternet bağlantısı olmayan hedef makinelerde çalışabilecek paketler üretme; bunun her hedef için ayrıca doğrulanması gerekir.

### 1.1 Temel geliştirme ilkesi

Mevcut `PwX-Studio-v1.4.2.ps1` kaynak dosyası ilk geliştirme aşamasında değiştirilmeden korunacaktır.

Yeni motor ayrı bir geliştirme alanında hazırlanacak, test edilecek ve ancak başarı ölçütlerini karşıladıktan sonra mevcut arayüze entegre edilecektir.

### 1.2 Başarı ölçütleri

| No. | Başarı ölçütü | Kabul koşulu |
|---:|---|---|
| 1 | Mevcut sürüm korunur | v1.4.2 değişmeden çalışmaya devam eder |
| 2 | Bağımsız motor | Derleme işlemi PS2EXE modülünü çağırmaz |
| 3 | PS 5.1 hedefi | Desteklenen Windows ortamlarında doğrulanır |
| 4 | PS 7 hedefi | Uyumlu PowerShell SDK ile paketleme yapılır |
| 5 | Gömülü çalışma ortamı | Self-contained paketleme test edilir |
| 6 | Parametre aktarımı | Adlandırılmış ve konumsal argümanlar doğru aktarılır |
| 7 | Çıkış kodları | Betiğin çıkış kodu doğru yansıtılır |
| 8 | Türkçe karakterler | Kaynak ve çıktı metinleri bozulmaz |
| 9 | Güvenlik | Geçici dosyalar ve kullanıcı girdileri güvenli yönetilir |
| 10 | Dağıtım | Temiz Windows sanal makinesinde test başarılı olur |
| 11 | Lisans | Paketlerin lisans ve bildirimleri kaydedilir |
| 12 | Dokümantasyon | Kurulum, kullanım ve sorun giderme belgeleri tamamlanır |

---

## 2. Proje kapsamı

### 2.1 İlk sürüm kapsamı

- `.ps1` dosyası seçimi.
- Kaynak betiğin temel sözdizimi kontrolü.
- PowerShell hedef sürümünün seçilmesi.
- EXE çıktı yolu ve dosya adının belirlenmesi.
- Konsollu veya penceresiz uygulama seçeneği.
- Betik kaynağının derlenen uygulamaya gömülmesi.
- PowerShell 7 için self-contained paketleme seçeneği.
- Komut satırı argümanlarının aktarılması.
- Standart çıktı, hata çıktısı ve çıkış kodu yönetimi.
- Derleme ilerleme durumu ve ayrıntılı günlük.
- Temel ikon ve sürüm metaverileri.
- Hata durumunda kontrollü temizleme.
- Derleme sonuç raporu.

### 2.2 İlk sürüm dışında bırakılacak özellikler

Aşağıdaki özellikler ilk prototipin başarısı doğrulanmadan vaat edilmeyecektir:

- Her PowerShell betiğinin sorunsuz EXE'ye dönüşmesi.
- Her harici modülün otomatik olarak EXE'ye gömülmesi.
- Kaynak kodun tamamen gizlenmesi veya tersine mühendisliğin engellenmesi.
- Windows PowerShell 5.1'in Windows'tan bağımsız bir runtime olarak paketlenmesi.
- Tek EXE'nin bütün Windows mimarilerinde çalışması.
- İlk sürümde Native AOT ve agresif kod kırpma.
- Kod imzalama sertifikasının otomatik oluşturulması.
- Antivirüs uyarılarının kesin olarak ortadan kaldırılması.
- Karmaşık WPF, WinForms, COM ve native DLL bağımlılıklarının otomatik çözümlenmesi.

---

## 3. Teknik mimari

### 3.1 Genel mimari

PwX Studio arayüzü ile derleme motoru birbirinden ayrılacaktır.

```text
PwX Studio GUI
      |
      v
BuildRequest
      |
      v
PwX Build Engine
      |
      +----------------------------+
      |                            |
      v                            v
PowerShell 5.1 Backend       PowerShell 7 Backend
      |                            |
      v                            v
Windows PowerShell Host      .NET / PowerShell SDK Host
      |                            |
      v                            v
PS 5.1 hedefli EXE            Self-contained EXE
      |                            |
      +-------------+--------------+
                    |
                    v
            BuildResult / Log
                    |
                    v
             PwX Studio GUI
```

Bu mimari, her PowerShell sürümü için ayrı uygulama mantığı geliştirilmesini ve ortak sonuçların tek arayüzde gösterilmesini sağlar.

### 3.2 Önerilen klasör yapısı

```text
PwXStudio/
│
├── README.md
├── CHANGELOG.md
├── LICENSE
├── IMPLEMENTATION_ROADMAP.md
│
├── src/
│   ├── PwX.Studio/
│   │   └── PwX-Studio.ps1
│   │
│   ├── PwX.BuildEngine.Abstractions/
│   │   ├── BuildRequest.cs
│   │   ├── BuildResult.cs
│   │   └── BuildDiagnostic.cs
│   │
│   ├── PwX.BuildEngine.Core/
│   │   ├── BuildCoordinator.cs
│   │   ├── SourceValidator.cs
│   │   ├── DependencyInspector.cs
│   │   └── BuildLogger.cs
│   │
│   ├── PwX.BuildEngine.PowerShell51/
│   │   ├── PowerShell51Backend.cs
│   │   └── HostLauncher.cs
│   │
│   ├── PwX.BuildEngine.PowerShell7/
│   │   ├── PowerShell7Backend.cs
│   │   └── EmbeddedPowerShellHost.cs
│   │
│   └── PwX.BuildHost/
│       └── Program.cs
│
├── tests/
│   ├── PwX.BuildEngine.UnitTests/
│   ├── PwX.BuildEngine.IntegrationTests/
│   └── samples/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── BUILDING.md
│   ├── COMPATIBILITY.md
│   ├── SECURITY.md
│   ├── TROUBLESHOOTING.md
│   └── THIRD_PARTY_NOTICES.md
│
├── licenses/
│   └── THIRD_PARTY_LICENSES.md
│
├── scripts/
│   ├── Check-Environment.ps1
│   ├── Build-Engine.ps1
│   └── Run-Tests.ps1
│
└── artifacts/
    ├── logs/
    └── test-results/
```

**Not:** Bu yapı hedeflenen mimaridir. İlk prototipte bütün projeler bir kerede oluşturulmayacaktır. Öncelikle minimal çalışan motor geliştirilecek, klasör yapısı aşamalı biçimde genişletilecektir.

### 3.3 Bileşenlerin görevleri

| Bileşen | Sorumluluk |
|---|---|
| `PwX.Studio` | Kullanıcı arayüzü ve ayarlar |
| `Abstractions` | Ortak veri modelleri ve arayüzler |
| `Core` | Ön kontrol, derleme koordinasyonu ve loglama |
| `PowerShell51Backend` | Windows PowerShell 5.1 hedefi |
| `PowerShell7Backend` | PowerShell 7 hedefi |
| `BuildHost` | Gömülü betiği çalıştıran ana uygulama |
| `UnitTests` | Bileşen testleri |
| `IntegrationTests` | Uçtan uca derleme ve çalıştırma testleri |
| `scripts` | Ortam kontrolü ve otomatik test araçları |

---

## 4. PowerShell 5.1 ve PowerShell 7 hedefleri

Bu iki hedef aynı teknolojiymiş gibi ele alınmamalıdır. Farklı runtime ve uyumluluk koşulları vardır.

### 4.1 Windows PowerShell 5.1

Önerilen ilk yaklaşım:

- EXE, küçük bir host veya başlatıcı uygulama olarak üretilir.
- Betik kaynak kodu uygulamanın içine kaynak olarak eklenir.
- Host, hedef sistemdeki `powershell.exe` üzerinden betiği çalıştırabilir.
- Parametreler, hata çıktısı ve çıkış kodları doğru şekilde aktarılır.
- Windows PowerShell 5.1'in sistemde mevcut olması gereksinimi kullanıcıya açıkça gösterilir.

Bu ilk yaklaşım, Windows PowerShell 5.1'i bağımsız bir runtime olarak yeniden dağıtma iddiasında bulunmaz.

**Araştırılacak alternatif:** Betiğin geçici bir `.ps1` dosyasına çıkarılmadan, Windows PowerShell otomasyon arayüzleri üzerinden bellekte çalıştırılması. Bu yöntem; argüman aktarımı, güvenlik, STA/MTA davranışı, modül yükleme ve hata ayıklama testlerinden geçmeden varsayılan yapılmamalıdır.

### 4.2 PowerShell 7

Önerilen yaklaşım:

- .NET tabanlı bir host geliştirmek.
- Uyumlu PowerShell SDK sürümünü kullanmak.
- Desteklenen hedef .NET sürümünü seçmek.
- `dotnet publish` ile hedef mimariye göre paket üretmek.
- `SelfContained` ve `PublishSingleFile` seçeneklerini değerlendirmek.
- Gerekli PowerShell çalışma ortamını dağıtım paketine dahil etmek.

Self-contained paketleme, uygun yapılandırmayla .NET ve PowerShell çalışma bileşenlerini hedefe taşımaya yardımcı olur. Bununla birlikte, betiğin kullandığı bütün modüller, harici dosyalar ve native DLL'ler kendiliğinden çözümlenmiş sayılmaz.

### 4.3 Hedef karşılaştırma çizelgesi

| Özellik | Windows PowerShell 5.1 | PowerShell 7 |
|---|---|---|
| Çalışma ortamı | Windows'taki `powershell.exe` | PowerShell 7 runtime/SDK |
| Bağımsız motor | Geliştirilecek | Geliştirilecek |
| Runtime'ı gömme | İlk sürümde vaat edilmez | Self-contained paketleme hedeflenir |
| Tek dosya dağıtımı | Host yaklaşımına bağlı | Teknik olarak değerlendirilebilir |
| Windows'a bağımlılık | Evet | Windows EXE hedefinde evet |
| Modül uyumluluğu | PS 5.1 uyumlu modüller | PS 7 uyumlu modüller |
| .NET uyumluluğu | .NET Framework tabanlı ortam | Seçilen PowerShell SDK/.NET sürümü |
| İlk hedef mimari | `win-x64` ile başlanması önerilir | `win-x64` ile başlanması önerilir |
| Temiz makine testi | Zorunlu | Zorunlu |
| Destek durumu | Test edilen Windows sürümleriyle sınırlı | Test edilen PowerShell/.NET hedefleriyle sınırlı |

### 4.4 Runtime sürümünün belirlenmesi

Proje başlangıcında rastgele bir .NET veya PowerShell SDK sürümü seçilmeyecektir.

Şu kontroller yapılacaktır:

1. Hedeflenen PowerShell 7 sürümünün hangi .NET sürümüyle uyumlu olduğu doğrulanır.
2. Microsoft'un resmi belgelerindeki destek ve dağıtım koşulları incelenir.
3. Seçilen SDK sürümü sabitlenir.
4. Örnek host derlenir.
5. Çıktı boyutu ve açılış süresi ölçülür.
6. Lisans ve yeniden dağıtım koşulları kaydedilir.

Referans: https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/choosing-the-right-nuget-package

---

## 5. Ortak motor API tasarımı

### 5.1 BuildRequest

Derleme isteğinin bütün ayarlarını temsil eder.

| Alan | Açıklama |
|---|---|
| `SourcePath` | Kaynak `.ps1` dosyası |
| `OutputPath` | Üretilecek EXE'nin yolu |
| `Target` | PowerShell 5.1 veya PowerShell 7 |
| `Architecture` | Hedef mimari |
| `ApplicationMode` | Console veya GUI |
| `RuntimeMode` | Sistem runtime'ı veya self-contained |
| `IconPath` | İsteğe bağlı ikon |
| `ProductName` | Ürün adı |
| `CompanyName` | Yayıncı/şirket bilgisi |
| `FileVersion` | Dosya sürümü |
| `ProductVersion` | Ürün sürümü |
| `DependencyManifest` | Harici bağımlılık listesi |
| `WorkingDirectory` | Çalışma dizini politikası |
| `BuildOptions` | Diğer paketleme seçenekleri |

### 5.2 BuildResult

Derleme sonunda döndürülen sonucu temsil eder.

| Alan | Açıklama |
|---|---|
| `Success` | Başarı durumu |
| `OutputPath` | Üretilen dosya |
| `ExitCode` | Derleme işlemine ait sonuç kodu |
| `Duration` | Derleme süresi |
| `Warnings` | Uyarılar |
| `Errors` | Hatalar |
| `LogPath` | Ayrıntılı günlük |
| `OutputSize` | Üretilen dosyanın boyutu |
| `TargetRuntime` | Kullanılan hedef runtime |
| `Diagnostics` | Ayrıntılı tanılama kayıtları |

### 5.3 BuildDiagnostic

Her hata veya uyarı standart bir yapıda raporlanır.

| Alan | Örnek |
|---|---|
| `Severity` | Info, Warning, Error |
| `Code` | `PWX1001` |
| `Message` | Açıklayıcı hata mesajı |
| `SourcePath` | Kaynak dosya |
| `Line` | Satır numarası |
| `Column` | Sütun numarası |

Hata kodları kullanıcıya anlaşılır açıklama sunmalı ve sorun giderme belgelerinde karşılık bulmalıdır.

---

## 6. Derleme işlem hattı

| Adım | İşlem | Başarı koşulu |
|---:|---|---|
| 1 | Kaynak dosyayı doğrula | Dosya mevcut ve okunabilir |
| 2 | Çıktı yolunu doğrula | Hedef yazılabilir |
| 3 | Kaynak kodu analiz et | Temel sözdizimi hataları belirlenmiş |
| 4 | Hedef runtime'ı kontrol et | Gerekli SDK/araçlar belirlenmiş |
| 5 | Bağımlılıkları incele | Bilinen gereksinimler raporlanmış |
| 6 | Geçici build alanı oluştur | Çakışma olmadan klasör hazırlanmış |
| 7 | Host uygulamayı hazırla | Hedefe uygun host oluşturulmuş |
| 8 | Betiği paketle | Kaynak hosta dahil edilmiş |
| 9 | Yayınla | EXE üretilmiş |
| 10 | Çıktıyı doğrula | Dosya var ve beklenen özelliklere sahip |
| 11 | Kontrollü test yap | Test senaryoları başarılı |
| 12 | Rapor oluştur | Sonuç, uyarılar ve log kaydedilmiş |
| 13 | Geçicileri temizle | Yalnızca PwX tarafından oluşturulan dosyalar temizlenmiş |

### 6.1 Ön kontrol

Derleme başlamadan önce:

- Kaynak dosya var mı?
- Dosya okunabiliyor mu?
- Çıktı yolu yazılabilir mi?
- Kaynak ve çıktı yolları yanlışlıkla aynı dosyaya mı işaret ediyor?
- Seçilen runtime hedefi destekleniyor mu?
- Gerekli .NET SDK veya build araçları mevcut mu?
- İkon dosyası geçerli mi?
- Kaynak kod ayrıştırılabiliyor mu?
- Harici bağımlılık gereksinimleri var mı?

Eksik bileşen durumunda arayüz hangi bileşenin eksik olduğunu açıklamalı; kullanıcı onayı olmadan sistem bileşenlerini değiştirmemelidir.

### 6.2 İptal ve hata yönetimi

- Derleme işlemi iptal edilebilir olmalıdır.
- İptal sırasında alt süreçler kontrollü biçimde sonlandırılmalıdır.
- Tamamlanmamış EXE, başarılı çıktı gibi gösterilmemelidir.
- Hatalar kullanıcıya ve günlük dosyasına yazılmalıdır.
- Kullanıcının kaynak dosyası otomatik olarak değiştirilmemelidir.
- Temizlik işlemi yalnızca PwX tarafından oluşturulan geçici dosyalarla sınırlandırılmalıdır.

---

## 7. Gömülü betik ve güvenlik

### 7.1 Gömülü betiğin anlamı

Bir `.ps1` dosyasının EXE içine gömülmesi, kaynak kodun tamamen gizlendiği anlamına gelmez. Gömülü kaynak dosyadan çıkarılabilir veya uygulamanın çalışması sırasında gözlemlenebilir.

Bu nedenle ürün, gömme özelliğini **paketleme kolaylığı** olarak tanımlamalı; kesin kod koruması veya tersine mühendislik engeli olarak tanıtmamalıdır.

### 7.2 Güvenlik gereksinimleri

- Her derleme için benzersiz geçici çalışma alanı oluşturulmalı.
- Öngörülebilir sabit geçici dosya adlarından kaçınılmalı.
- Argümanlar güvenli şekilde aktarılmalı; kullanıcı girdileri doğrudan shell komut dizelerine eklenmemeli.
- Yol ve dosya adlarında Türkçe karakter, boşluk ve özel karakterler test edilmeli.
- Kaynak betik derleme sırasında kendiliğinden çalıştırılmamalı.
- Hassas parametreler loglarda varsayılan olarak maskelenmeli.
- Sertifika ve özel anahtarlar kaynak depoda tutulmamalı.
- Harici dosyaların ve native DLL'lerin güvenilirliği değerlendirilmelidir.
- Antivirüs veya işletim sistemi güvenlik kontrollerini atlatmaya yönelik özellik eklenmemeli.

### 7.3 Güvenlik test çizelgesi

| Test | Beklenen davranış |
|---|---|
| Boşluklu dosya yolu | Doğru işlenir |
| Türkçe karakterli yol | Bozulma yaşanmaz |
| Özel karakterli argüman | Tek argüman olarak korunur |
| Derleme iptali | Geçiciler kontrollü temizlenir |
| Eşzamanlı iki derleme | Geçici dosya çakışması oluşmaz |
| Hatalı kaynak | Çalıştırılmadan hata raporlanır |
| Harici bağımlılık | Eksikse açıklayıcı uyarı verilir |
| Hassas argüman | Günlükte gereksiz biçimde açığa çıkarılmaz |
| Bozuk çıktı | Başarılı derleme olarak sunulmaz |

---

## 8. PwX Studio v1.4.2 ile entegrasyon

Mevcut uygulama yeni motorun geliştirilmesi sırasında kullanılabilir durumda kalmalıdır.

### 8.1 Geçiş stratejisi

1. v1.4.2 kaynak dosyasının ayrı bir kopyasını sakla.
2. Kaynak dosyanın SHA-256 özetini kaydet.
3. Yeni motoru ayrı klasör veya Git dalında geliştir.
4. Mevcut derleme işlevlerini ve arayüz davranışlarını kaydet.
5. Yeni motoru önce bağımsız bir prototip olarak test et.
6. GUI'ye deneysel motor seçeneği ekle.
7. Başarısızlık durumunda mevcut kararlı akışa dönülebilmesini sağla.
8. Testler tamamlanınca sürüm yükseltmesini değerlendir.

### 8.2 Mevcut kaynakta incelenecek noktalar

v1.4.2 kaynak kodunda şu alanlar bulunuyor:

- `Import-Module ps2exe -RequiredVersion 1.0.18`
- `Invoke-PS2EXE @params`
- `StubTemplate` adlı C# taslağı.

`StubTemplate`, incelenmesi gereken bir başlangıç taslağıdır; tek başına üretim kalitesinde bir dönüştürme motoru sayılmaz. Yeni motor, PS2EXE kodunu kullanmadan ayrı şekilde tasarlanmalıdır.

### 8.3 Sürümleme önerisi

| Sürüm | Amaç |
|---|---|
| v1.4.2 | Korunacak kararlı temel |
| v1.5.0-preview.1 | Bağımsız motor prototipinin ilk entegrasyonu |
| v1.5.0-preview.2 | Test düzeltmeleri ve hedef runtime desteği |
| v1.5.0 | Kabul kriterleri karşılanırsa ilk kararlı bağımsız motor sürümü |

Bu sürüm numaraları öneridir; takvim veya yayın taahhüdü değildir.

---

## 9. Uygulama aşamaları

| Aşama | İş paketi | Teslimat | Tamamlanma ölçütü |
|---:|---|---|---|
| 0 | Mevcut sürümü koruma | Kaynak kopyası, hash, özellik envanteri | Geri dönüş doğrulanır |
| 1 | Teknik fizibilite | Ortam kontrolü, SDK araştırması | PS 5.1 ve PS 7 için net karar |
| 2 | Minimal motor | Komut satırı prototipi | Basit betik EXE olarak çalışır |
| 3 | PS 7 paketleme | Self-contained host | Temiz VM testi başarılı |
| 4 | PS 5.1 desteği | Başlatıcı/host | Test edilmiş Windows hedeflerinde çalışır |
| 5 | Kaynak metaverileri | İkon ve sürüm bilgisi | Dosya özellikleri doğru |
| 6 | GUI entegrasyonu | Motor seçimi ve log ekranı | GUI'den build yapılır |
| 7 | Test ve lisans | Test raporu ve lisans envanteri | Kritik engeller giderilir |
| 8 | Önizleme/yayın | Dokümantasyon ve sürüm paketi | Dağıtım koşulları belgelenir |

### Aşama 0 — Mevcut sürümü güvenceye alma

- v1.4.2 kaynak dosyasını değiştirmeden koru.
- Dosyanın SHA-256 değerini kaydet.
- GUI açılışı ve temel işlevleri doğrula.
- Mevcut derleme akışını kaydet.
- Geri dönüş adımını dokümante et.

### Aşama 1 — Teknik fizibilite

- Windows sürümünü belirle.
- `powershell.exe` ve `pwsh.exe` varlığını kontrol et.
- `dotnet --info` ve kurulu SDK sürümlerini kaydet.
- Uyumlu PowerShell SDK ve .NET hedefini belirle.
- Minimal host uygulamasının boyutunu ve açılış süresini ölç.
- Üçüncü taraf lisanslarını ön incelemeden geçir.

### Aşama 2 — Minimal prototip

Öncelikle aşağıdaki betik için çalışan bir prototip oluştur:

```powershell
param(
    [string]$Message = "PwX Studio",
    [int]$Code = 0
)

Write-Output $Message
exit $Code
```

Prototip şu davranışları göstermelidir:

- EXE açılır.
- Varsayılan mesajı yazdırır.
- Komut satırından mesaj alır.
- Çıkış kodunu aktarır.
- Kaynak betiği build sırasında çalıştırmaz.
- PS2EXE modülünü yüklemeden çalışır.

### Aşama 3 — PowerShell 7 paketleme

- SDK host geliştirilir.
- Hedef RID seçilir.
- Self-contained ve tek dosya yayın seçenekleri test edilir.
- Paket boyutu, açılış süresi ve bağımlılıklar ölçülür.
- Temiz Windows sanal makinesinde çalıştırılır.

### Aşama 4 — Windows PowerShell 5.1

- Sistem `powershell.exe` kullanımının koşulları belirlenir.
- Parametre aktarımı ve hata kodları test edilir.
- Konsol ve GUI betikleri ayrı test edilir.
- Bellek içi çalıştırma yaklaşımı fizibilite açısından incelenir.
- Desteklenmeyen senaryolar belgelenir.

### Aşama 5 — Windows kaynakları ve metaverileri

- İkon ekleme.
- Product Name ve Company Name.
- File Version ve Product Version.
- Description ve diğer temel dosya özellikleri.
- İsteğe bağlı kod imzalama desteği.

### Aşama 6 — GUI entegrasyonu

- Runtime hedef seçimi.
- Konsol/GUI seçimi.
- Paketleme seçenekleri.
- Ön kontrol ve bağımlılık uyarıları.
- İlerleme durumu.
- İptal ve hata yönetimi.
- Log ve sonuç raporu.
- Mevcut PwX tasarım sistemiyle uyum.

### Aşama 7 — Test ve lisans kontrolü

- Otomatik testler.
- Temiz makine testleri.
- Harici modül ve dosya testleri.
- Güvenlik kontrolleri.
- Paket bazlı lisans incelemesi.
- Üçüncü taraf bildirimleri.

### Aşama 8 — Önizleme ve yayın

- Sürüm notları hazırlanır.
- Örnek projeler eklenir.
- Kullanım ve sorun giderme belgeleri tamamlanır.
- Hash/checksum bilgileri oluşturulur.
- Kararlı sürüme geri dönüş planı korunur.

---

## 10. Test matrisi

| ID | Kategori | Test | Beklenen sonuç | Öncelik |
|---|---|---|---|---|
| T-001 | Temel | `Write-Output "PwX OK"` | Çıktı doğru | P0 |
| T-002 | Argüman | Adlandırılmış parametre | Değer doğru aktarılır | P0 |
| T-003 | Argüman | Boşluk içeren parametre | Argüman bölünmez | P0 |
| T-004 | Çıkış kodu | `exit 17` | Kod 17 olarak aktarılır | P0 |
| T-005 | Unicode | Türkçe karakterler | Metin bozulmaz | P0 |
| T-006 | Dosya yolu | Boşluklu yol | Derleme başarılı | P0 |
| T-007 | Encoding | UTF-8 BOM | Kaynak doğru okunur | P0 |
| T-008 | Encoding | BOM'suz UTF-8 | Desteklenen biçimde doğru okunur | P0 |
| T-009 | Hata | Sözdizimi hatası | Anlaşılır hata raporu | P0 |
| T-010 | Konsol | Stdout/stderr | Beklenen davranış | P0 |
| T-011 | Runtime | PS 5.1 hedefi | Gerekli runtime kontrol edilir | P0 |
| T-012 | Runtime | PS 7 self-contained | Hedeflenen temiz makinede çalışır | P0 |
| T-013 | GUI | Penceresiz mod | Konsol penceresi açılmaz | P1 |
| T-014 | Bağımlılık | Harici JSON | Paketlenir veya uyarı verilir | P1 |
| T-015 | Bağımlılık | PowerShell modülü | Gereksinim raporlanır | P1 |
| T-016 | Kaynak | İkon | EXE özelliklerinde görünür | P1 |
| T-017 | Metaveri | Sürüm bilgisi | Dosya özellikleri doğru | P1 |
| T-018 | İptal | Build iptali | Kontrollü sonlanır | P1 |
| T-019 | Paralellik | İki eşzamanlı build | Dosya çakışması oluşmaz | P1 |
| T-020 | Güvenlik | Özel karakterli argüman | Güvenli aktarım | P0 |
| T-021 | Dağıtım | İnternetsiz temiz VM | Belgelenen koşullarda çalışır | P0 |
| T-022 | Lisans | Paket envanteri | Bütün dağıtılan bileşenler kayıtlı | P0 |
| T-023 | Geri dönüş | Eski motor akışı | v1.4.2 işlevleri korunur | P0 |

**Öncelik tanımları:** P0 = yayın öncesi zorunlu; P1 = kararlı sürüm için planlanmış özellik.

---

## 11. Performans ve boyut ölçümleri

Bağımsız motorun başarısı yalnızca EXE üretmesiyle ölçülmemelidir.

| Ölçüm | Kaydedilecek değer |
|---|---|
| Host derleme süresi | Saniye |
| Betik paketleme süresi | Saniye |
| İlk açılış süresi | Saniye |
| Sonraki açılış süresi | Saniye |
| EXE dosya boyutu | Bayt/MB |
| Ek dosyaların toplam boyutu | Bayt/MB |
| Boşta bellek kullanımı | MB |
| Basit betik bellek kullanımı | MB |
| Başarılı test oranı | Yüzde |
| Hata başına tanılama süresi | Dakika |

Başlangıçta gerçekçi hedef değerler belirlemek için ölçüm alınmalıdır. Boyut ve hız için sayısal hedefler, prototip sonuçları görülmeden kesinleştirilmemelidir.

---

## 12. Lisans ve üçüncü taraf bileşenler

### 12.1 Bağımsızlık ilkesi

Yeni motor PS2EXE veya PS2EXE.Core kaynak kodunu kopyalamamalı ya da bunları çalışma zamanı bağımlılığı olarak kullanmamalıdır.

Bu projeler yalnızca özellik ve davranış karşılaştırması amacıyla incelenebilir.

Başka bir projeyi kullanmak, çatallamak veya yalnızca yeniden adlandırmak bağımsız motor geliştirmekle aynı şey değildir.

### 12.2 Kontrol edilecek bileşenler

- .NET SDK ve runtime.
- PowerShell SDK/NuGet paketleri.
- Doğrudan ve transitif NuGet bağımlılıkları.
- İkon kaynakları ve ikon kütüphaneleri.
- Fontlar ve arayüz kaynakları.
- Compiler ve resource düzenleme araçları.
- Kod imzalama araçları.
- EXE ile dağıtılacak native DLL'ler.
- Örnek betikler ve üçüncü taraf kaynaklar.

### 12.3 Lisans envanteri çizelgesi

| Alan | Açıklama |
|---|---|
| Paket adı | Bileşenin tam adı |
| Sürüm | Kesin sürüm numarası |
| Kaynak | Resmî depo veya paket adresi |
| Lisans | Lisans adı |
| Lisans metni | Lisans dosyası bağlantısı |
| Bağımlılık türü | Doğrudan/transitif |
| Paketleme | EXE içine gömülü/harici |
| Dağıtım koşulu | Yeniden dağıtım gereksinimleri |
| Atıf | NOTICE veya bildirim gereksinimi |
| Kontrol tarihi | İnceleme tarihi |
| Durum | Onaylandı/İnceleniyor/Kullanılmayacak |

Lisans bilgileri yalnızca paket adından tahmin edilmemelidir. Kullanılan gerçek sürümün lisans dosyası incelenmelidir.

Bu belge hukuki görüş değildir. Her dağıtım sürümü için gerçek paketlerin lisans koşulları yeniden kontrol edilmelidir.

---

## 13. Dokümantasyon planı

| Dosya | İçerik | Tamamlanma aşaması |
|---|---|---|
| `README.md` | Proje amacı, özellikler, kurulum, hızlı başlangıç | İlk prototip |
| `CHANGELOG.md` | Sürüm değişiklikleri | Her sürüm |
| `LICENSE` | PwX kaynak kodunun lisansı | Dağıtım öncesi |
| `IMPLEMENTATION_ROADMAP.md` | Mimari ve uygulama planı | Proje başlangıcı |
| `ARCHITECTURE.md` | Bileşenler ve veri akışı | Aşama 1–2 |
| `BUILDING.md` | Kaynak koddan derleme | Aşama 2 |
| `COMPATIBILITY.md` | Runtime ve Windows uyumluluğu | Her test aşaması |
| `SECURITY.md` | Güvenlik modeli ve sınırlar | Aşama 2–7 |
| `TROUBLESHOOTING.md` | Hata kodları ve çözümler | Aşama 2–8 |
| `THIRD_PARTY_NOTICES.md` | Üçüncü taraf bildirimleri | Dağıtım öncesi |
| `licenses/THIRD_PARTY_LICENSES.md` | Lisans envanteri | Dağıtım öncesi |
| `screenshots/` | Gerçek uygulama ekran görüntüleri | GUI entegrasyonu sonrası |

Ekran görüntüleri, gerçek uygulamanın ilgili sürümünden alınmalıdır. Henüz geliştirilmemiş özellikleri varmış gibi gösteren temsili görseller kullanılmamalıdır.

---

## 14. Risk analizi

| Risk | Olasılık | Etki | Azaltma yaklaşımı |
|---|---|---|---|
| PS 5.1 ve PS 7 farkları | Yüksek | Yüksek | İki ayrı backend |
| Büyük self-contained EXE | Yüksek | Orta | Boyut ölçümü ve paketleme seçenekleri |
| Harici modül eksikliği | Yüksek | Yüksek | Bağımlılık manifesti |
| Native DLL uyumsuzluğu | Orta | Yüksek | Hedef makine testleri |
| Dinamik PowerShell davranışları | Yüksek | Orta | İlk aşamada trimming/AOT kullanmama |
| GUI betiklerinde STA/MTA farkı | Orta | Yüksek | Ayrı GUI testleri |
| Geçici dosya sızıntısı | Orta | Yüksek | Benzersiz klasör ve kontrollü temizlik |
| Lisans belirsizliği | Orta | Yüksek | Paket bazlı lisans kapısı |
| v1.4.2'nin bozulması | Düşük | Yüksek | Ayrı dal ve geri dönüş planı |
| Güvenlik yazılımlarının uyarısı | Orta | Orta | Şeffaf dağıtım, isteğe bağlı imzalama |
| Hatalı kaynakta yanlış başarı | Orta | Yüksek | Build sonrası doğrulama ve testler |

---

## 15. Yayın öncesi kontrol listesi

### Kaynak kod ve mimari

- [ ] v1.4.2 kaynak dosyası korundu.
- [ ] Yeni motor ayrı geliştirme alanında.
- [ ] PS2EXE kodu kullanılmadı.
- [ ] PS2EXE modülüne çalışma zamanı bağımlılığı yok.
- [ ] PS 5.1 ve PS 7 backend'leri birbirinden ayrıldı.

### Derleme ve çalıştırma

- [ ] Basit betik testi başarılı.
- [ ] Argüman aktarımı başarılı.
- [ ] Çıkış kodu testi başarılı.
- [ ] Türkçe karakter testi başarılı.
- [ ] Hata ve log testi başarılı.
- [ ] Temiz Windows VM testi başarılı.
- [ ] Runtime gereksinimleri belgelenmiş.
- [ ] Paket boyutu ve açılış süresi ölçülmüş.

### Güvenlik ve lisans

- [ ] Geçici dosyalar güvenli yönetiliyor.
- [ ] Kullanıcı girdileri güvenli aktarılıyor.
- [ ] Hassas veriler gereksiz loglanmıyor.
- [ ] Üçüncü taraf lisansları incelendi.
- [ ] Gerekli bildirimler hazır.
- [ ] İmzalama ve dağıtım koşulları belgelendi.

### Dokümantasyon

- [ ] README güncellendi.
- [ ] CHANGELOG hazır.
- [ ] LICENSE kararı verildi.
- [ ] ARCHITECTURE ve COMPATIBILITY belgeleri hazır.
- [ ] TROUBLESHOOTING belgesi hazır.
- [ ] Gerçek ekran görüntüleri eklendi.
- [ ] Bilinen kısıtlar açıkça yazıldı.

---

## 16. Karar kapıları: GO / NO-GO

### GO — Uygulamaya devam et

Şu koşullar karşılandığında bir sonraki aşamaya geçilebilir:

- Minimal motor kontrollü betikleri başarıyla paketliyor.
- PS2EXE olmadan derleme yapılabiliyor.
- Hedef runtime ve SDK sürümleri belirlenmiş.
- v1.4.2 korunmuş.
- Kritik güvenlik sorunları yok.
- Dağıtılacak bileşenlerin lisansları incelenebilir durumda.

### NO-GO — Yeniden tasarla

Aşağıdaki durumlardan biri varsa ilerleme durdurulmalı veya kapsam daraltılmalıdır:

- Hedef runtime güvenilir şekilde çalıştırılamıyor.
- Argümanlar veya çıkış kodları doğru aktarılamıyor.
- Paketleme temiz makinede başarısız oluyor.
- Kritik güvenlik sorunu giderilemiyor.
- Dağıtılacak bileşenlerin lisans koşulları belirsiz kalıyor.

### Kapsam daraltma seçeneği

İlk sürümde PS 5.1 için Windows'taki `powershell.exe` kullanımını destekleyip PS 7 için self-contained paketlemeyi ana geliştirme hedefi yapmak mümkündür. Bu, iki runtime'ı tek bir yöntemle çözmeye çalışmaktan daha gerçekçi bir başlangıçtır.

---

## 17. İlk geliştirme oturumunun görevleri

| Sıra | Görev | Çıktı |
|---:|---|---|
| 1 | v1.4.2 dosyasını doğrula ve hash al | Korunan temel sürüm |
| 2 | Ortam kontrol betiği yaz | `Check-Environment.ps1` |
| 3 | .NET ve PowerShell SDK uyumluluğunu belirle | Runtime kararı |
| 4 | PS 7 minimal host oluştur | İlk prototip |
| 5 | PS 5.1 başlatıcı prototipi oluştur | İkinci prototip |
| 6 | Ortak örnek betikle test et | Karşılaştırma sonuçları |
| 7 | Boyut ve açılış süresini ölç | Performans raporu |
| 8 | Lisans envanterini başlat | `THIRD_PARTY_NOTICES.md` |
| 9 | Test sonuçlarını belgele | `COMPATIBILITY.md` |
| 10 | GO/NO-GO kararı ver | Sonraki aşamanın kapsamı |

### İlk oturumun teslimatları

- `Check-Environment.ps1`
- `ARCHITECTURE.md` ilk taslağı
- `COMPATIBILITY.md` test sonuçları
- PS 7 minimal host prototipi
- PS 5.1 minimal başlatıcı prototipi
- `THIRD_PARTY_NOTICES.md` başlangıç envanteri
- Boyut ve açılış süresi ölçümleri
- GO/NO-GO karar kaydı

---

## 18. Teknik referanslar

1. **PS2EXE — yalnızca özellik ve davranış karşılaştırması:**  
   https://github.com/MScholtes/PS2EXE

2. **PS2EXE.Core — yalnızca alternatif yaklaşım karşılaştırması:**  
   https://github.com/FabienTschanz/PS2EXE.Core

3. **PS2EXE.Core paket sayfası:**  
   https://www.powershellgallery.com/packages/PS2EXE.Core

4. **Microsoft Learn — .NET single-file deployment:**  
   https://learn.microsoft.com/en-us/dotnet/core/deploying/single-file/overview

5. **Microsoft Learn — PowerShell SDK/NuGet sürüm seçimi:**  
   https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/choosing-the-right-nuget-package

Referanslar uygulama öncesinde tekrar kontrol edilmelidir. SDK, runtime, paket ve lisans sürümleri zaman içinde değişebilir.

---

## 19. Sonuç

PwX Studio'nun bağımsız EXE dönüştürme motoru projesi, mevcut arayüzü koruyarak ayrı bir derleme altyapısı geliştirme yaklaşımıyla yürütülecektir.

İlk hedef, bütün özellikleri aynı anda tamamlamak değil; **PS2EXE'ye bağımlı olmayan, kontrollü testleri geçen minimal bir motor** oluşturmaktır.

PowerShell 7 için self-contained paketleme ana teknik hedeflerden biridir. Windows PowerShell 5.1 içinse Windows'taki mevcut çalışma ortamını kullanma yaklaşımı başlangıçta daha uygulanabilir görünmektedir.

Proje ancak teknik testler, güvenlik kontrolleri ve lisans incelemeleri tamamlandıktan sonra kararlı sürüm olarak yayımlanmalıdır.

**Belge durumu:** Planlama tamamlandı; uygulama ve prototip testleri henüz gerçekleştirilmiş sayılmaz.
