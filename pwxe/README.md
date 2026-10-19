# PwX Studio — PwX Build Engine (ilk prototip)

PS2EXE'den bağımsız `.ps1 → .exe` dönüştürme motoru. `IMPLEMENTATION_ROADMAP.md` Aşama 0–5 + Bölüm 17 (ilk oturum) karşılığıdır.
Mevcut `PwX-Studio-v1.4.2.ps1` dosyasına **dokunulmaz**; bu klasör ayrı geliştirme alanıdır.

## Klasör yapısı

```
scripts/Check-Environment.ps1        Ortam kontrolü (PS 5.1, pwsh, .NET SDK, csc.exe, NuGet erişimi)
scripts/PwX-Build.ps1                Motor (komut satırı): ön kontrol -> paketle -> doğrula -> günlük
src/PwX.BuildHost.PS7/               PowerShell 7 hostu (Microsoft.PowerShell.SDK, self-contained)
src/PwX.BuildHost.PS51/Stub.cs       Windows PowerShell 5.1 başlatıcısı (csc.exe ile derlenir, .NET SDK gerekmez)
tests/Run-Smoke.ps1                  T-001..T-005, T-009 duman testleri
tests/samples/hello.ps1              Roadmap Aşama 2 örnek betiği
```

## Kullanım

```powershell
# 1) Ortam
.\scripts\Check-Environment.ps1

# 2) PS 5.1 hedefi (.NET SDK gerekmez, hedefte powershell.exe şart)
.\scripts\PwX-Build.ps1 -Source .\tests\samples\hello.ps1 -Output .\out\hello51.exe -Target PS51 -Force

# 3) PS 7 hedefi, self-contained (ilk derlemede internet ister)
.\scripts\PwX-Build.ps1 -Source .\tests\samples\hello.ps1 -Output .\out\hello7.exe -Target PS7 -Force
.\scripts\PwX-Build.ps1 -Source .\tests\samples\hello.ps1 -Output .\out\hello7.exe -Target PS7 -SingleFile -Force   # deneysel

# 4) Testler
.\tests\Run-Smoke.ps1
```

Seçenekler: `-Mode Console|Gui`, `-Icon x.ico`, `-ProductName`, `-CompanyName`, `-Description`, `-FileVersion 1.2.3.4`,
`-ProductVersion`, `-RuntimeMode SelfContained|FrameworkDependent`, `-Architecture win-x64|win-arm64`, `-LogPath`, `-Force`, `-KeepTemp`.

## Güncel çıktı seçenekleri

SelfContained varsayılandır. FrameworkDependent küçük çıktı seçeneğidir; Console hedefinde .NET 8 Runtime, GUI hedefinde Windows Desktop Runtime 8 gerekir. SingleFile iki runtime modu ile de kullanılabilir. Mimari win-x86, win-x64 veya win-arm64 seçilebilir. Yönetici, DPI, Windows uyumluluğu, uzun yollar, EXE.config, UTF-8/Unicode ve çıktı bastırma seçenekleri desteklenir.

## Tasarım kararları

- Kaynak betik derleme sırasında **çalıştırılmaz**, yalnızca `Parser::ParseFile` ile ayrıştırılır (hata kodu `PWX1003`, satır/sütun ile).
- Payload her zaman **UTF-8 BOM** ile gömülür; BOM'suz dosya UTF-8 sayılır, geçerli UTF-8 değilse Windows-1254 uyarısıyla okunur.
- Her çalıştırma benzersiz `pwx-<guid>` geçici klasörü kullanır; yalnızca o klasör silinir.
- Argümanlar `CommandLineToArgvW` kurallarıyla tırnaklanır (PS 5.1) / `ConsoleShell` argüman dizisi olarak geçer (PS 7); shell komut dizesi birleştirilmez.
- Mevcut çıktı/klasör `-Force` olmadan ezilmez; klasör yalnızca `.pwx-build` işareti varsa silinir.
- Trimming/AOT yok (Roadmap Bölüm 14).

## Bilinen sınırlar / henüz doğrulanmadı

- Bu prototip **Windows'ta henüz derlenip çalıştırılmadı**. İlk iş `tests\Run-Smoke.ps1` çalıştırmak; sonuçları `COMPATIBILITY.md`'ye yazın (Aşama 3–4).
- `PsSdkVersion 7.4.6` / `net8.0` varsayılandır; Roadmap 4.4'e göre güncel sürüm uyumluluğunu doğrulayıp sabitleyin.
- PS 7 `-SingleFile` + PowerShell SDK birlikte sorun çıkarabilir (modül dosyaları, açılış süresi). Varsayılan çıktı klasör düzenindedir.
- PS 7 GUI modu konsol etkileşimi (Read-Host) desteklemez; WinForms/WPF betikleri Aşama 4'te ayrıca test edilmeli.
- PS 5.1 hedefi hedef makinedeki `powershell.exe`'yi kullanır (runtime gömülmez).
- Harici modül/dosya bağımlılık manifesti, kod imzalama ve GUI entegrasyonu sonraki aşamalardır.
