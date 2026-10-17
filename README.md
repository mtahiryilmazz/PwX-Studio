# PwX Studio

<p align="center">
  <img src="ico/pwx_logo.png" alt="PwX Studio Logo" width="128" height="128">
</p>

<p align="center">
  <strong>PowerShell Script to EXE Builder — Windows GUI Application</strong><br>
  <em>Convert PowerShell scripts into native Windows executables with a lightweight default build strategy.</em>
</p>

<p align="center">
  <a href="https://github.com/mtahiryilmazz/PwX-Studio/releases/latest"><img src="https://img.shields.io/badge/release-v1.5.1-blue.svg?style=flat-square" alt="Latest Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6.svg?style=flat-square" alt="Platform: Windows">
  <img src="https://img.shields.io/badge/Engine-pwxe-success.svg?style=flat-square" alt="Engine: pwxe">
</p>

---

> ⚡ **PS7 size optimization:** PwX Studio now prefers the smaller `FrameworkDependent` mode for PowerShell 7 builds by default. This keeps generated `.exe` files significantly smaller while still allowing `SelfContained` and `SingleFile` builds when needed.

---

## 📖 İçindekiler

- [Hakkında](#-hakkında)
- [Öne Çıkan Özellikler](#-öne-çıkan-özellikler)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Hızlı Başlangıç & Kullanım](#-hızlı-başlangıç--kullanım)
- [Örnek derleme modları](#-örnek-derleme-modları)
- [Ekosistem & Dönüştürme Motoru](#-ekosistem--dönüştürme-motoru)
- [Lisans](#-lisans)

---

## 🌟 Hakkında

**PwX Studio**, PowerShell (`.ps1`) betiklerinizi tek bir tıklamayla taşınabilir Windows çalıştırılabilir (`.exe`) dosyalarına dönüştürmek için tasarlanmış, modern ve kullanıcı dostu bir masaüstü uygulamasıdır.

PwX Studio içinde çalışan çekirdek derleme motoru `pwxe` olarak bağımsız bir PowerShell modülü ve CLI aracı olarak da kullanılabilir. Güncel davranışta PS7 çıktıları varsayılan olarak `FrameworkDependent` çalışır; böylece hedef sistemde uygun `pwsh` kuruluysa çok daha küçük EXE üretimi elde edilir.

---

## 🚀 Öne Çıkan Özellikler

- **🖥️ Responsive arayüz:** pencere yeniden boyutlandırılabilir ve küçük ekranlarda kullanılabilir
- **⚡ Dahili pwxe motoru:** harici `ps2exe` bağımlılığı yok, tamamen çevrimdışı çalışır
- **🎯 Çift hedef çalışma zamanı:**
  - **PowerShell 5.1:** hafif ve yerel `.exe` çıktısı
  - **PowerShell 7.4+:** modern dil özellikleri ve modern `.NET` altyapısı
- **📦 Küçük varsayılan PS7 çıktısı:** `FrameworkDependent` modu varsayılandır; EXE boyutunu önemli ölçüde düşürür
- **🧩 İsteğe bağlı sıkıştırma ve trimming:** `-EnableTrim` ve `-EnableUpx` seçenekleri kullanılabilir
- **🖼️ Simge ve WinForms entegrasyonu:** uygulama simgesi ve form başlık simgesi otomatik olarak eklenir
- **🌗 Açık / koyu tema:** modern kullanıcı deneyimi

---

## 💻 Sistem Gereksinimleri

- **İşletim Sistemi:** Windows 10, Windows 11 veya Windows Server 2016+
- **PowerShell:** Windows PowerShell 5.1 (Windows ile yerleşik gelir)
- *(İsteğe Bağlı)* PowerShell 7.4+ hedefi için: [.NET 8 SDK](https://dotnet.microsoft.com/download)

---

## 📥 Hızlı Başlangıç & Kullanım

1. [Releases](https://github.com/mtahiryilmazz/PwX-Studio/releases/latest) sayfasından son sürümü indirin.
2. **Kaynak Betik:** Dönüştürmek istediğiniz `.ps1` dosyasını seçin.
3. **Çıktı Yolu:** Üretilecek `.exe` dosyasının adını ve konumunu belirleyin.
4. **Hedef Çalışma Zamanı:** PowerShell 5.1 veya PowerShell 7.4+ seçin.
5. **Seçenekler:** Konsol / GUI modunu, simgeyi ve mimari seçimini ayarlayın.
6. **"EXE OLUŞTUR"** butonuna tıklayın.

---

## 🧩 Örnek derleme modları

### PS7 default (daha küçük .exe)

Bu seçenek, hedef PC'de compatible `pwsh` kurulu olduğu varsayımıyla en küçük çıktı için idealdir.

```powershell
Invoke-Pwxe -Source .\modern.ps1 -Output .\modern.exe -Target PS7
```

### PS7 self-contained (daha büyük ama tek başına çalışır)

```powershell
Invoke-Pwxe -Source .\modern.ps1 -Output .\modern-selfcontained.exe -Target PS7 -Runtime SelfContained -SingleFile
```

### PS7 trimming denemesi

```powershell
Invoke-Pwxe -Source .\modern.ps1 -Output .\modern-trimmed.exe -Target PS7 -Runtime FrameworkDependent -EnableTrim
```

### PS7 UPX sıkıştırması (opsiyonel)

```powershell
Invoke-Pwxe -Source .\modern.ps1 -Output .\modern-upx.exe -Target PS7 -Runtime FrameworkDependent -EnableUpx
```

---

## 🔗 Ekosistem & Dönüştürme Motoru

| Proje | Tür | Açıklama |
| :--- | :--- | :--- |
| **[PwX Studio](https://github.com/mtahiryilmazz/PwX-Studio)** | Desktop GUI | Grafik arayüz, tema, simge seçici ve görsel derleme |
| **[pwxe](https://github.com/mtahiryilmazz/pwxe)** | CLI / Modül | Terminal, otomasyon, CI/CD ve PowerShell modülü motoru |

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında lisanslanmıştır.
