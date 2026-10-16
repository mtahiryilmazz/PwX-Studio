# Agent Kuralları ve Geliştirme Yönergeleri

## Otomatik Git Senkronizasyonu (Zorunlu)
Kullanıcının evden ve farklı cihazlardan kesintisiz çalışabilmesi için:
- Yapılan her geliştirme, hata düzeltmesi veya özellik tamamlandığında değişiklikler otomatik olarak derlenmeli (`.exe`), test edilmeli ve GitHub reposuna (`origin main`) push edilmelidir.
- Sürüm yükseltmeleri veya etiketli sürümlerde `git tag` güncellenmeli ve `--force` ile GitHub'a yansıtılmalıdır.
- Kullanıcının ayrıca "repoyu güncelle" demesine gerek kalmadan işlem biter bitmez otomatik commit & push gerçekleştirilmelidir.
