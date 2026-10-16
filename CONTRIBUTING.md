# PwX Studio Katkı Rehberi (Contributing Guide)

PwX Studio projesine katkıda bulunmak istediğiniz için teşekkür ederiz!

## 🛠️ Geliştirme Ortamı Kurulumu

PwX Studio tamamen Windows PowerShell ve yerleşik C# altyapısı üzerine inşa edilmiştir:
- **Windows 10 / 11**
- **Windows PowerShell 5.1** (Windows ile yerleşik gelir)
- *(İsteğe Bağlı)* **PowerShell 7.4+** ve **.NET 8 SDK** (Modern derleme motoru testleri için)

## 🌿 İş Akışı

1. Projeyi çatallayın (Fork).
2. Özellik veya hata düzeltmeniz için yeni bir dal oluşturun:
   ```bash
   git checkout -b feature/harika-ozellik
   ```
3. Değişikliklerinizi yapın ve test edin:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\pwxengine\tests\Run-Smoke.ps1
   ```
4. Kodlama standartlarına ve UTF-8 BOM karakter kodlamasına dikkat edin.
5. Değişikliklerinizi commit edin:
   ```bash
   git commit -m "feat: harika ozellik eklendi"
   ```
6. Dalınızı GitHub'a gönderin ve bir Pull Request (PR) açın.

## 📜 Kodlama İlkeleri

- **Harici Bağımlılık Yok:** PwX Studio'nun temel felsefesi sıfır harici modül bağımlılığı ile çevrimdışı çalışabilmesidir. Harici PowerShell modülü zorunluluğu getiren kodlar kabul edilmez.
- **Karakter Kodlaması:** Betik dosyaları Türkçe karakter desteği için **UTF-8 with BOM** olarak kaydedilmelidir.
- **Geriye Dönük Uyumluluk:** PowerShell 5.1 desteği her zaman korunmalıdır.
