# PwX Studio

<p align="center">
  <img src="ico/pwx_logo.png" alt="PwX Studio Logo" width="128" height="128">
</p>

<p align="center">
  <strong>PowerShell Script to EXE Builder — Windows GUI Application</strong><br>
  <em>PowerShell betiklerinizi grafik arayüz üzerinden modern, bağımsız ve yerel Windows (.exe) uygulamalarına dönüştürün.</em>
</p>

<p align="center">
  <a href="https://github.com/mtahiryilmazz/pwxstudio/releases/latest"><img src="https://img.shields.io/badge/release-v1.5.0-blue.svg?style=flat-square" alt="Latest Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6.svg?style=flat-square" alt="Platform: Windows">
  <img src="https://img.shields.io/badge/Engine-pwxe-success.svg?style=flat-square" alt="Engine: pwxe">
</p>

---

> ⚡ **Komut Satırı / CI/CD Kullanıcıları:** PwX Studio'nun arka planında çalışan çekirdek dönüştürme motoru bağımsız bir CLI ve PowerShell modülü olarak da sunulmaktadır. Terminalden derleme ve otomasyon için [**pwxe (PwX Engine)**](https://github.com/mtahiryilmazz/pwxe) reposunu ziyaret edebilirsiniz.

---

## 📖 İçindekiler

- [Hakkında](#-hakkında)
- [Öne Çıkan Özellikler](#-öne-çıkan-özellikler)
- [Arayüz ve Ekran Görüntüsü](#-arayüz-ve-ekran-görüntüsü)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Hızlı Başlangıç & Kullanım](#-hızlı-başlangıç--kullanım)
- [Simge (Icon) Yönetimi](#-simge-icon-yönetimi)
- [Açık / Koyu Tema Desteği](#-açık--koyu-tema-desteği)
- [Lisans](#-lisans)

---

## 🌟 Hakkında

**PwX Studio**, PowerShell (`.ps1`) betiklerinizi tek bir tıklamayla taşınabilir Windows çalıştırılabilir (`.exe`) dosyalarına dönüştürmek için tasarlanmış, modern ve kullanıcı dostu bir masaüstü uygulamasıdır.

Komut satırı karmaşası olmadan betiklerinizi seçebilir, görsel uygulama simgeleri ekleyebilir, PowerShell 5.1 veya modern PowerShell 7.4+ çalışma zamanlarını belirleyerek son kullanıcıya dağıtılabilir profesyonel uygulamalar üretebilirsiniz.

---

## 🚀 Öne Çıkan Özellikler

- **🖥️ Tamamen Responsive Arayüz:** Sabit pencere kısıtlaması olmadan pencereyi serbestçe yeniden boyutlandırabilir, ekranı kaplayabilir ve küçük ekranlarda otomatik kaydırma çubuğu ile rahatça çalışabilirsiniz.
- **⚡ Dahili pwxe Motoru:** Harici `ps2exe` modülü zorunluluğu yoktur. İzole veya kapalı devre ağlarda tamamen çevrimdışı (offline) çalışır.
- **🎯 Çift Hedef Çalışma Zamanı:**
  - **PowerShell 5.1:** Sıfır ek gereksinimle hafif ve anında açılan yerel `.exe` çıktısı (~500 KB).
  - **PowerShell 7.4+:** En yeni PowerShell dil özellikleri ve opsiyonel **Tek Dosya (Single-File)** paketleme desteği.
- **🖼️ Dahili Web İkon Arama:** Iconify ve Icons8 entegrasyonuyla binlerce vektörel ikonu uygulama içinden arayabilir, tek tıkla indirip çok boyutlu `.ico` formatına otomatik dönüştürebilirsiniz.
- **🛡️ Otomatik Form Simgesi Enjeksiyonu:** Seçilen simge yalnızca Windows Gezgini'nde değil, betik içindeki WinForms pencerelerinin başlık çubuğunda ve Windows görev çubuğunda da otomatik olarak gösterilir.
- **🌗 Lucide Açık / Koyu Tema:** Göz yormayan, sistemle uyumlu modern tema geçişi.
- **📋 Gerçek Zamanlı Günlük Kayıtları:** Derleme sürecini, parametreleri ve varsa hata detaylarını adım adım gösteren konsol ekranı.

---

## 📸 Arayüz ve Ekran Görüntüsü

<p align="center">
  <img src="screenshots/pwx_main_window.png" alt="PwX Studio Ana Pencere" width="800">
</p>

---

## 💻 Sistem Gereksinimleri

- **İşletim Sistemi:** Windows 10, Windows 11 veya Windows Server 2016+ (x64 / x86)
- **PowerShell:** Windows PowerShell 5.1 (Windows ile yerleşik gelir)
- *(İsteğe Bağlı)* Yalnızca PowerShell 7.4+ hedefiyle derleme yapmak için: [.NET 8 SDK](https://dotnet.microsoft.com/download)

---

## 📥 Hızlı Başlangıç & Kullanım

PwX Studio taşınabilirdir (portable), kurulum gerektirmez:

1. [Releases](https://github.com/mtahiryilmazz/pwxstudio/releases/latest) sayfasından `PwX-Studio-v1.5.0.exe` dosyasını indirin ve çalıştırın.
2. **Kaynak Betik:** Dönüştürmek istediğiniz `.ps1` dosyasını seçin.
3. **Çıktı Yolu:** Üretilecek `.exe` dosyasının adını ve kaydedileceği konumu belirleyin.
4. **Simge Ekleme:** Kendi `.ico` dosyanızı seçin veya "Web'den Ara" butonuna basarak kütüphaneden beğendiğiniz bir ikonu seçin.
5. **Hedef Çalışma Zamanı:** PowerShell 5.1 veya PowerShell 7.4+ seçeneğini belirleyin.
6. **Seçenekler:** Konsol uygulaması veya pencereli (arka plan) mod, yönetici yetkisi (UAC), x64/x86 mimari tercihlerini yapılandırın.
7. **"EXE OLUŞTUR"** butonuna tıklayın.

---

## 🖼️ Simge (Icon) Yönetimi

PwX Studio, simgeleri iki ayrı katmanda işler:
1. **EXE Dosya Simgesi:** Windows Gezgini, masaüstü kısayolları ve dosya listelerinde görünen simgedir.
2. **Pencere Simgesi (Bootstrap):** Betiğiniz WinForms arayüzü içeriyorsa, form kurucuları otomatik tespit edilerek simge pencerenin sol üst köşesine ve görev çubuğuna otomatik entegre edilir.

---

## 🔗 Ekosistem & Dönüştürme Motoru

PwX ekosistemi iki ana parçadan oluşur:

| Proje | Tür | Açıklama |
| :--- | :--- | :--- |
| **[PwX Studio](https://github.com/mtahiryilmazz/pwxstudio)** | Desktop GUI | Grafik arayüz, tema, simge seçici ve görsel derleme |
| **[pwxe](https://github.com/mtahiryilmazz/pwxe)** | CLI / Modül | Terminal, otomasyon, PSGallery (`Install-Module pwxe`) ve CI/CD derleme motoru |

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında lisanslanmıştır.
