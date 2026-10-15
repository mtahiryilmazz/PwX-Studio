# PwX Studio

**PowerShell Script to EXE Builder — Windows GUI Application**

PwX Studio, PowerShell (`.ps1`) betiklerini Windows üzerinde çalıştırılabilir `.exe` dosyalarına dönüştürmek için tasarlanmış, grafik arayüzlü bir masaüstü uygulamasıdır. PowerShell betiklerini paketleme sürecini kolaylaştırmayı, derleme seçeneklerini tek bir arayüzde sunmayı ve uygulamalara özel simge eklemeyi amaçlar.

> **Proje:** PwX Studio  
> **Mevcut sürüm:** v1.4.2  
> **Platform:** Microsoft Windows  
> **Programlama dili:** Windows PowerShell  
> **Arayüz teknolojisi:** Windows Forms (WinForms)  
> **EXE dönüştürme altyapısı:** PS2EXE  
> **Lisans:** Henüz belirlenmedi

---

## İçindekiler

- [Proje Hakkında](#proje-hakkında)
- [Temel Amaç](#temel-amaç)
- [Özellikler](#özellikler)
- [Teknik Altyapı](#teknik-altyapı)
- [Uygulama Mimarisi](#uygulama-mimarisi)
- [Sistem Gereksinimleri](#sistem-gereksinimleri)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Simge Yönetimi](#simge-yönetimi)
- [Güvenlik ve Sınırlamalar](#güvenlik-ve-sınırlamalar)
- [Sorun Giderme](#sorun-giderme)
- [Geliştirme Yol Haritası](#geliştirme-yol-haritası)
- [Katkıda Bulunma](#katkıda-bulunma)

## Proje Hakkında

PwX Studio, PowerShell betiklerini EXE biçiminde paketlemek isteyen sistem yöneticileri, yazılım geliştiricileri, bilgi işlem personeli ve ileri düzey Windows kullanıcıları için geliştirilmiştir.

PS2EXE altyapısını grafik arayüz üzerinden kullanarak komut satırında elle girilmesi gereken işlemleri daha erişilebilir hâle getirmeyi hedefler.

Uygulama; kaynak dosyanın seçilmesi, çıktı dosyasının belirlenmesi, simge seçimi ve derleme işlemlerinin yönetilmesi gibi adımları tek bir masaüstü arayüzünde bir araya getirir.

PwX Studio, PowerShell kodunu başka bir programlama diline dönüştüren bir derleyici değildir. PS2EXE aracılığıyla PowerShell betiğini bir Windows çalıştırılabilir dosyası olarak paketler.

## Temel Amaç

PwX Studio'nun temel hedefleri şunlardır:

- PowerShell betiklerini EXE biçiminde paketlemeyi kolaylaştırmak.
- Derleme sürecini grafik arayüz üzerinden yönetmek.
- Kullanıcıların kendi uygulama simgelerini kullanabilmesini sağlamak.
- PS2EXE altyapısının hazırlanmasını ve kullanılmasını kolaylaştırmak.
- Derleme sürecine ilişkin mesajları ve hata çıktılarını kullanıcıya göstermek.
- Modern, kompakt ve temaya uyumlu bir Windows arayüzü sunmak.

## Özellikler

### 1. PowerShell'den EXE'ye dönüştürme

PwX Studio, `.ps1` kaynak dosyalarını PS2EXE altyapısı üzerinden `.exe` biçiminde paketlemeye yönelik bir arayüz sağlar.

Hedeflenen iş akışı:

1. PowerShell kaynak dosyasını seçmek.
2. Çıktı EXE dosyasını belirlemek.
3. Kullanılacak simgeyi seçmek.
4. Derleme seçeneklerini yapılandırmak.
5. Derlemeyi başlatmak.
6. İşlem sonuçlarını ve hata mesajlarını incelemek.

Dönüştürme işlemi, PS2EXE'nin desteklediği seçenekler ve kaynak betiğin uyumluluğu ile sınırlıdır.

### 2. Özel uygulama simgesi

PwX Studio, EXE dosyasına özel bir ICO simgesi eklenmesini desteklemek üzere tasarlanmıştır.

Simge yönetiminde birbirinden farklı iki konu bulunur:

- **EXE simgesi:** Windows Gezgini, dosya listeleri ve uygun kısayollarda görünen uygulama simgesi.
- **WinForms pencere simgesi:** Uygulamanın başlık çubuğunda ve Windows görev çubuğunda kullanılan simge.

EXE dosyasına simge gömmek, çalışan uygulamanın bütün pencerelerinin simgesini otomatik olarak değiştirmez. WinForms uygulamalarında ilgili `Form` nesnesinin `Icon` özelliğinin de doğru şekilde ayarlanması gerekir.

PwX Studio'nun simge desteği, bu iki alanın ayrı ayrı ele alınmasını amaçlar. Kaynak kodda otomatik simge uygulaması yapılırken yalnızca desteklenen WinForms kalıpları güvenilir biçimde tespit edilebilir; her türlü özel pencere oluşturma yöntemi için ek uyarlama gerekebilir.

### 3. PS2EXE altyapısı

PwX Studio'nun EXE paketleme iş akışında PS2EXE kullanılır.

PS2EXE, PowerShell betiklerini yürütülebilir dosya biçiminde paketlemeye yarayan bir araçtır. PwX Studio, bu altyapının kullanımını grafik arayüz üzerinden kolaylaştırır.

PS2EXE'nin desteklediği seçenekler, kullanılan sürüme göre değişebilir. Üretim ortamında kullanılacak sürüm ve parametreler ayrıca doğrulanmalıdır.

### 4. Tema desteği

PwX Studio, açık ve koyu tema arasında geçiş yapılabilen bir arayüz sunar.

Tema sisteminin hedefleri:

- Arayüzün okunabilirliğini korumak.
- Kontrollerin tema değişiminde uygun renkleri kullanmasını sağlamak.
- Marka rengini tutarlı biçimde göstermek.
- Kullanıcı deneyimini daha modern hâle getirmek.

### 5. İşlem günlüğü

Derleme sırasında ortaya çıkan mesajlar, uyarılar ve hatalar arayüzdeki günlük alanı üzerinden izlenebilir.

Günlük, sorunların teşhis edilmesine yardımcı olur. Ancak günlükte bir işlem mesajının görünmesi, tek başına EXE dosyasının başarıyla çalıştığını kanıtlamaz; üretilen dosyanın ayrıca test edilmesi gerekir.

### 6. Kompakt masaüstü arayüzü

PwX Studio'nun mevcut arayüz tasarımı, Windows masaüstü kullanımına yönelik sabit boyutlu bir WinForms penceresi üzerine kuruludur.

Arayüzde temel hedefler:

- Kontrollerin düzenli yerleşimi.
- Tema değişiminde görünümün korunması.
- Derleme günlüğünün okunabilir olması.
- Sık kullanılan işlemlere kolay erişim.

Arayüzün farklı ekran çözünürlüklerinde ve Windows ölçeklendirme ayarlarında doğrulanması önerilir.

### 7. Logo ve görsel varlıklar

Proje paketinde PwX Studio markası için SVG logo ve tema simgeleri bulunabilir.

SVG dosyaları görsel varlık olarak kullanılabilir; ancak Windows uygulama simgesi ve EXE içine gömülecek simge için genellikle ICO biçimi tercih edilir.

## Teknik Altyapı

| Bileşen | Teknoloji | Görevi |
|---|---|---|
| Uygulama dili | Windows PowerShell | İş mantığı ve derleme akışı |
| Grafik arayüz | Windows Forms | Masaüstü kullanıcı arayüzü |
| Paketleme altyapısı | PS2EXE | PowerShell betiğini EXE olarak paketleme |
| Simge biçimi | ICO | Windows uygulama simgesi |
| Logo biçimi | SVG | Marka ve arayüz görselleri |
| Dağıtım paketi | ZIP | Kaynak kod ve yardımcı dosyaların bir arada sunulması |

### PowerShell

Uygulamanın iş akışı PowerShell ile yönetilir. Dosya seçimi, yapılandırma, harici araçların kullanımı ve hata mesajlarının gösterilmesi bu katmanda gerçekleştirilir.

### Windows Forms

WinForms, Windows masaüstü arayüzünü oluşturmak için kullanılan .NET grafik arayüz teknolojisidir.

Pencere simgesinin değiştirilmesi gerektiğinde ilgili formun `Icon` özelliği kullanılır:

```powershell
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(
    "C:\Uygulama\PwXApp.exe"
)
```

Bu örnek, mevcut bir EXE dosyasının ilişkili simgesini kullanmaya yöneliktir. Özel bir ICO dosyası kullanılacaksa uygun ICO dosyasından `System.Drawing.Icon` nesnesi oluşturulmalıdır. Gerçek uygulamada dosya yolu, kaynakların yaşam döngüsü ve hata yönetimi de ele alınmalıdır.

### PS2EXE

PS2EXE, PowerShell betiklerini Windows çalıştırılabilir dosyası olarak paketleme işleminde kullanılır.

Genel kullanım örneği:

```powershell
Invoke-PS2EXE `
    -InputFile ".\MyScript.ps1" `
    -OutputFile ".\MyScript.exe" `
    -IconFile ".\MyIcon.ico"
```

Bu komut genel bir kullanım örneğidir. PwX Studio'nun kullandığı gerçek parametreler ve desteklenen seçenekler, kurulu PS2EXE sürümüyle uyumlu olmalıdır.

## Uygulama Mimarisi

PwX Studio'nun iş akışı kavramsal olarak aşağıdaki katmanlardan oluşur:

```text
+-------------------------------------+
|          PwX Studio GUI             |
|      Windows Forms / PowerShell     |
+------------------+------------------+
                   |
                   v
+-------------------------------------+
|       Kullanıcı Girdileri           |
| Kaynak PS1 / Çıktı EXE / ICO         |
+------------------+------------------+
                   |
                   v
+-------------------------------------+
|       Derleme İş Akışı              |
| Kontroller / Parametreler / Günlük  |
+------------------+------------------+
                   |
                   v
+-------------------------------------+
|              PS2EXE                 |
|       PowerShell -> EXE paketi      |
+------------------+------------------+
                   |
                   v
+-------------------------------------+
|          Çıktı ve Doğrulama         |
|       EXE dosyası / Testler         |
+-------------------------------------+
```

Bu şema mantıksal iş akışını gösterir; bağımsız modüllerin veya ayrı süreçlerin mevcut uygulamada tam olarak bu şekilde uygulandığı iddiasını taşımaz.

## Sistem Gereksinimleri

Beklenen çalışma ortamı:

- Microsoft Windows.
- Uygulamanın kullandığı Windows PowerShell sürümüyle uyumlu bir sistem.
- .NET Framework veya WinForms için gerekli Windows bileşenleri.
- PS2EXE altyapısı ve ihtiyaç duyduğu bağımlılıklar.
- Kaynak `.ps1` dosyasına erişim.
- Özel simge kullanılacaksa geçerli bir `.ico` dosyası.
- Çıktı klasörüne yazma izni.

**Not:** Kesin Windows ve PowerShell sürüm desteği, kullanılan sürümün gerçek ortam testleriyle belgelenmelidir. Bu README, henüz doğrulanmamış işletim sistemi uyumluluklarını garanti etmez.

## Kurulum

### Yöntem 1: ZIP paketi

1. PwX Studio ZIP paketini indirin.
2. Paketi bir klasöre çıkarın.
3. README dosyasındaki yönergeleri inceleyin.
4. `PwX-Studio-v1.4.2.ps1` dosyasını uygun PowerShell ortamında çalıştırın.

PowerShell betiklerinin çalıştırılması sistemdeki yürütme ilkelerine bağlıdır. Kurum ortamında güvenlik ilkelerini değiştirmeden önce yöneticinizin yönergelerini izleyin.

### Yöntem 2: Kaynak kod üzerinden çalıştırma

PowerShell'i açın ve kaynak dosyanın bulunduğu klasöre geçin:

```powershell
Set-Location "C:\PwX-Studio"
.\PwX-Studio-v1.4.2.ps1
```

Dosya adını ve klasör yolunu indirdiğiniz pakete göre düzenleyin.

## Kullanım

### EXE oluşturma

1. PwX Studio'yu açın.
2. Paketlenecek PowerShell betiğini seçin.
3. Oluşturulacak EXE dosyasının konumunu belirleyin.
4. İsteğe bağlı olarak ICO simgesini seçin.
5. Mevcut arayüzde sunulan derleme seçeneklerini yapılandırın.
6. Derleme işlemini başlatın.
7. Günlük mesajlarını inceleyin.
8. Oluşturulan EXE'yi kontrollü bir test ortamında çalıştırın.

### Derleme sonrası doğrulama

Oluşturulan dosya için şu kontrolleri yapın:

- EXE dosyasının oluştuğunu doğrulayın.
- Dosya boyutunun makul olduğunu kontrol edin.
- EXE simgesini Windows Gezgini'nde inceleyin.
- Uygulamayı çalıştırıp pencere başlık çubuğu simgesini kontrol edin.
- Görev çubuğu simgesini inceleyin.
- Kaynak betiğin beklenen işlevlerini test edin.
- Hata ve bağımlılık davranışlarını doğrulayın.

## Simge Yönetimi

Windows'ta aşağıdaki simgeler birbirinden farklı davranabilir:

| Simge alanı | Nerede görünür? | Nasıl belirlenir? |
|---|---|---|
| EXE dosya simgesi | Dosya Gezgini ve bazı kısayollar | EXE kaynakları |
| WinForms pencere simgesi | Pencere başlık çubuğu | `Form.Icon` |
| Görev çubuğu simgesi | Çalışan uygulama | Pencere ve süreç kimliği, Windows davranışı |
| Sabitlenmiş kısayol simgesi | Başlat veya görev çubuğu | Kısayol hedefi ve Windows simge önbelleği |

Görev çubuğunda varsayılan simge görünmesi durumunda yalnızca EXE simgesini değiştirmek yeterli olmayabilir. Form simgesi, süreç kimliği, kısayol hedefi ve Windows simge önbelleği de kontrol edilmelidir.

Kaynak koda otomatik simge ataması uygulanırken dikkat edilmesi gereken noktalar:

- WinForms formunun gerçekten tespit edilmesi.
- `Form` örneği oluşturulduktan sonra simgenin atanması.
- Özel pencere oluşturma kalıplarının değerlendirilmesi.
- ICO dosyasının çalışma sırasında erişilebilir olması veya uygun şekilde gömülmesi.
- Hata durumlarının günlüğe yazılması.

## Güvenlik ve Sınırlamalar

### EXE biçimi kodu gizlemez

PowerShell betiğinin EXE biçiminde paketlenmesi, kaynak kodun güvenli biçimde şifrelendiği veya tersine mühendisliğe karşı korunduğu anlamına gelmez.

Gizli anahtarlar, parolalar, API belirteçleri ve hassas bilgiler kaynak betiklere gömülmemelidir.

### Yönetici yetkileri

PwX Studio veya oluşturulan EXE her durumda yönetici yetkisi gerektirmez. Yetki ihtiyacı, kaynak betiğin gerçekleştirdiği işlemlere bağlıdır.

Gereksiz yönetici yetkisi verilmemelidir.

### Antivirüs ve güvenlik yazılımları

Paketlenmiş betikler, yaptıkları işlemlere ve paketleme biçimlerine bağlı olarak güvenlik yazılımlarınca incelemeye alınabilir. Bu durum otomatik olarak dosyanın zararlı olduğu anlamına gelmez; ancak güvenlik uyarıları göz ardı edilmemelidir.

### Kaynak kod uyumluluğu

Her PowerShell betiği PS2EXE ile sorunsuz paketlenmeyebilir. Modüller, harici dosyalar, çalışma dizini varsayımları, kullanıcı profiline bağlı yollar ve etkileşimli komutlar ayrıca değerlendirilmelidir.

### Test durumu

Sürüm açıklamalarında statik kaynak kontrolleri ile gerçek Windows çalıştırma testleri birbirinden ayrılmalıdır. Windows üzerinde doğrulanmamış özellikler, test edilmiş özellikler olarak sunulmamalıdır.

## Sorun Giderme

### EXE oluşturulamıyor

- PS2EXE altyapısının kullanılabilir olduğunu doğrulayın.
- Kaynak dosya yolunun doğru olduğunu kontrol edin.
- Çıktı klasöründe yazma izni bulunduğundan emin olun.
- Derleme günlüğündeki ilk hata mesajını inceleyin.

### EXE simgesi değişmiyor

- Seçilen ICO dosyasının geçerli olduğunu kontrol edin.
- Derlemenin yeni çıktı dosyasını oluşturduğunu doğrulayın.
- Eski EXE dosyasını veya eski kısayolu kullanmadığınızdan emin olun.

### WinForms başlık çubuğunda varsayılan simge görünüyor

- İlgili pencerenin bir WinForms `Form` nesnesi olduğunu doğrulayın.
- Formun `Icon` özelliğinin atandığını kontrol edin.
- Simge atamasının pencere gösterilmeden önce gerçekleştirildiğinden emin olun.
- Kaynak kodun özel bir form oluşturma yöntemi kullanıp kullanmadığını inceleyin.

### Görev çubuğunda varsayılan simge görünüyor

- Çalışan uygulamanın pencere simgesini kontrol edin.
- Sabitlenmiş kısayolun doğru EXE dosyasına işaret ettiğini doğrulayın.
- Uygulamayı yeni EXE dosyasından başlatın.
- Gerekirse eski kısayolu kaldırıp yenisini sabitleyin.
- Windows simge önbelleğinin eski simgeyi gösterme olasılığını değerlendirin.

## Geliştirme Yol Haritası

Gelecekte değerlendirilebilecek geliştirmeler:

- [ ] Farklı Windows ve PowerShell sürümlerinde otomatik uyumluluk kontrolü.
- [ ] PS2EXE sürümünü görüntüleme ve bağımlılık teşhisi.
- [ ] Derleme öncesi kaynak betik doğrulaması.
- [ ] Gelişmiş derleme seçenekleri.
- [ ] WinForms simge uygulaması için daha kapsamlı kaynak kod tespiti.
- [ ] Derleme sonrası EXE doğrulama raporu.
- [ ] Çoklu ICO boyutlarının ve yüksek DPI simgelerinin test edilmesi.
- [ ] Daha kapsamlı hata günlükleri.
- [ ] Otomatik test ve sürüm paketleme iş akışı.
- [ ] GitHub Actions üzerinden doğrulanmış sürüm paketleri.

Bu liste olası geliştirmeleri gösterir; tamamlanmış özelliklerin listesi değildir.

## Katkıda Bulunma

Projeye katkıda bulunmak isteyenler:

1. Depoyu forklayabilir.
2. Değişiklikler için ayrı bir dal oluşturabilir.
3. Değişikliklerini küçük ve açıklayıcı commit'lerle gönderebilir.
4. Uygun testleri çalıştırabilir.
5. Değişikliklerin kapsamını ve test sonuçlarını açıklayan bir Pull Request açabilir.

Hata bildirimlerinde mümkünse aşağıdaki bilgileri paylaşın:

- Windows sürümü.
- PowerShell sürümü.
- PwX Studio sürümü.
- PS2EXE sürümü.
- Hata mesajının tamamı.
- Sorunu yeniden oluşturma adımları.

Gizli bilgileri, kişisel verileri ve hassas dosya içeriklerini hata raporlarına eklemeyin.

## Lisans

Bu proje için lisans henüz belirtilmemiştir. Depo sahibi bir lisans seçip `LICENSE` dosyası ekleyene kadar yeniden dağıtım ve değiştirme izinlerinin otomatik olarak verildiği varsayılmamalıdır.

## Sürüm Bilgisi

Mevcut proje sürümü: **v1.4.2**

Sürüm değişiklikleri için GitHub deposunda ayrıca bir `CHANGELOG.md` dosyası tutulması önerilir.

---

**PwX Studio — PowerShell betiklerini Windows uygulaması olarak paketleme sürecini daha erişilebilir hâle getirmek için tasarlanmıştır.**
