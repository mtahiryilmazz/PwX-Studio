#Requires -Version 5.1
<#
    PwX Studio v1.8.0 - PowerShell Executable Builder
    - Windows 11 Modern Arayüz (Saf WPF/XAML Mimarisi)
    - Dinamik Tema Desteği: Açık Tema ve Koyu Tema geçişi
    - PowerShell 5.1 (Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Çok kaynaklı Web İkon Arama Hub'ı (Gelişmiş Türkçe/İngilizce Arama & Renk Kartelası)
    - Türkçe karakter uyumlu (UTF-8 dosya ve konsol UTF-8 çıktı motoru)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v1.8.0.ps1
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
[Net.ServicePointManager]::DefaultConnectionLimit = 16

# WPF Uygulama Yaşam Döngüsü: İkincil modal pencereler kapatıldığında ana pencerenin kapanmasını önle
try {
    if ($null -eq [System.Windows.Application]::Current) {
        $app = New-Object System.Windows.Application
        $app.ShutdownMode = [System.Windows.ShutdownMode]::OnExplicitShutdown
    } else {
        $currApp = [System.Windows.Application]::Current
        if ($currApp.Dispatcher -and $currApp.Dispatcher.CheckAccess()) {
            $currApp.ShutdownMode = [System.Windows.ShutdownMode]::OnExplicitShutdown
        }
    }
} catch {
    # Çoklu iş parçacığı veya önceden oluşturulmuş Application durumlarında hatayı yut
}

$trCulture = [System.Globalization.CultureInfo]::GetCultureInfo('tr-TR')

# ------------------------------------------------------------------
#  Gelişmiş Türkçe -> İngilizce İkon Sözlüğü (250+ Terim)
# ------------------------------------------------------------------
$TrMap = @{
    # Klasör, Dosya ve Belge
    'klasör' = 'folder'; 'klasor' = 'folder'; 'dosya' = 'file'; 'belge' = 'document'; 'evrak' = 'document'
    'arşiv' = 'archive'; 'arsiv' = 'archive'; 'yedek' = 'backup'; 'yedekleme' = 'backup'; 'kaydet' = 'save'
    'yazıcı' = 'printer'; 'yazici' = 'printer'; 'yazdır' = 'printer'; 'yazdir' = 'printer'; 'tarayıcı' = 'scanner'; 'tarayici' = 'scanner'
    'kopyala' = 'copy'; 'yapıştır' = 'paste'; 'yapistir' = 'paste'; 'kes' = 'cut'; 'pano' = 'clipboard'
    'not' = 'note'; 'defter' = 'notebook'; 'kitap' = 'book'; 'kalem' = 'pencil'; 'silgi' = 'eraser'; 'çöp' = 'trash'; 'cop' = 'trash'
    'sil' = 'delete'; 'kaldır' = 'remove'; 'kaldir' = 'remove'; 'düzenle' = 'edit'; 'duzenle' = 'edit'
    
    # Bilgisayar, Donanım ve Sistem
    'bilgisayar' = 'computer'; 'laptop' = 'laptop'; 'dizüstü' = 'laptop'; 'dizustu' = 'laptop'; 'masaüstü' = 'desktop'; 'masaustu' = 'desktop'
    'ekran' = 'monitor'; 'monitör' = 'monitor'; 'klavye' = 'keyboard'; 'fare' = 'mouse'; 'kulaklık' = 'headphones'; 'kulaklik' = 'headphones'
    'hoparlör' = 'speaker'; 'hoparlor' = 'speaker'; 'mikrofon' = 'microphone'; 'kamera' = 'camera'; 'webcam' = 'camera'
    'bellek' = 'memory'; 'ram' = 'memory'; 'disk' = 'harddrive'; 'sürücü' = 'drive'; 'surucu' = 'drive'; 'usb' = 'usb'
    'işlemci' = 'cpu'; 'islemci' = 'cpu'; 'çip' = 'chip'; 'cip' = 'chip'; 'sunucu' = 'server'; 'bulut' = 'cloud'
    'terminal' = 'terminal'; 'konsol' = 'console'; 'kod' = 'code'; 'yazılım' = 'software'; 'yazilim' = 'software'
    'uygulama' = 'app'; 'program' = 'application'; 'araç' = 'tools'; 'arac' = 'tools'; 'ayarlar' = 'settings'
    'ayar' = 'settings'; 'yapılandırma' = 'settings'; 'kurulum' = 'install'; 'yükle' = 'download'; 'yukle' = 'download'; 'indir' = 'download'
    'güncelle' = 'update'; 'guncelle' = 'update'; 'yenile' = 'refresh'; 'döngü' = 'sync'; 'dongu' = 'sync'
    
    # Güvenlik, Kimlik & Ağ
    'güvenlik' = 'security'; 'guvenlik' = 'security'; 'kalkan' = 'shield'; 'kilit' = 'lock'; 'kilitli' = 'lock'
    'anahtar' = 'key'; 'şifre' = 'password'; 'sifre' = 'password'; 'parola' = 'password'; 'kullanıcı' = 'user'
    'kullanici' = 'user'; 'hesap' = 'account'; 'profil' = 'profile'; 'grup' = 'group'; 'yönetici' = 'admin'; 'yonetici' = 'admin'
    'yetki' = 'permission'; 'koruma' = 'protect'; 'virüs' = 'virus'; 'virus' = 'virus'; 'hata' = 'error'; 'böcek' = 'bug'; 'bocek' = 'bug'
    'ağ' = 'network'; 'ag' = 'network'; 'internet' = 'globe'; 'dünya' = 'globe'; 'dunya' = 'globe'; 'web' = 'web'
    'wifi' = 'wifi'; 'bağlantı' = 'link'; 'baglanti' = 'link'; 'bluetooth' = 'bluetooth'
    
    # İletişim, Medya & Sosyal
    'mesaj' = 'message'; 'sohbet' = 'chat'; 'posta' = 'mail'; 'mektup' = 'mail'; 'eposta' = 'email'; 'mail' = 'mail'
    'gönder' = 'send'; 'gonder' = 'send'; 'gelen' = 'inbox'; 'telefon' = 'phone'; 'ara' = 'search'; 'arama' = 'search'
    'bul' = 'search'; 'büyüteç' = 'search'; 'buyutec' = 'search'; 'bildirim' = 'bell'; 'zil' = 'bell'
    'ses' = 'volume'; 'sessiz' = 'mute'; 'müzik' = 'music'; 'muzik' = 'music'; 'şarkı' = 'music'; 'sarki' = 'music'; 'oynat' = 'play'
    'durdur' = 'stop'; 'duraklat' = 'pause'; 'video' = 'video'; 'film' = 'movie'; 'resim' = 'image'; 'görsel' = 'image'; 'gorsel' = 'image'
    'fotoğraf' = 'photo'; 'fotograf' = 'photo'; 'galeri' = 'gallery'; 'paylaş' = 'share'; 'paylas' = 'share'
    'kalp' = 'heart'; 'sev' = 'heart'; 'beğen' = 'like'; 'begen' = 'like'; 'yıldız' = 'star'; 'yildiz' = 'star'; 'etiket' = 'tag'
    
    # Ticaret, Finans & Ofis
    'sepet' = 'cart'; 'çanta' = 'shopping-bag'; 'canta' = 'shopping-bag'; 'mağaza' = 'store'; 'magaza' = 'store'
    'dükkan' = 'shop'; 'dukkan' = 'shop'; 'para' = 'money'; 'nakit' = 'cash'; 'dolar' = 'dollar'; 'euro' = 'euro'; 'lira' = 'currency'
    'kart' = 'credit-card'; 'ödeme' = 'payment'; 'odeme' = 'payment'; 'fatura' = 'invoice'; 'banka' = 'bank'
    'indirim' = 'discount'; 'yüzde' = 'percent'; 'yuzde' = 'percent'; 'hediye' = 'gift'; 'paket' = 'package'
    'kargo' = 'delivery'; 'kamyon' = 'truck'; 'sipariş' = 'order'; 'siparis' = 'order'; 'grafik' = 'chart'; 'rapor' = 'chart'
    'tablo' = 'table'; 'hesaplama' = 'calculator'; 'takvim' = 'calendar'; 'saat' = 'clock'; 'zaman' = 'time'
    
    # Durumlar, Eylemler & Yönler
    'onay' = 'check'; 'tamam' = 'check'; 'doğru' = 'check'; 'dogru' = 'check'; 'evet' = 'check'; 'kapat' = 'close'; 'çarpı' = 'close'; 'carpi' = 'close'
    'iptal' = 'cancel'; 'uyarı' = 'warning'; 'uyari' = 'warning'; 'bilgi' = 'info'; 'yardım' = 'help'; 'yardim' = 'help'
    'soru' = 'help'; 'ekle' = 'plus'; 'artı' = 'plus'; 'arti' = 'plus'; 'çıkar' = 'minus'; 'cikar' = 'minus'; 'eksi' = 'minus'
    'ileri' = 'forward'; 'geri' = 'back'; 'yukarı' = 'arrow-up'; 'yukari' = 'arrow-up'; 'aşağı' = 'arrow-down'; 'asagi' = 'arrow-down'; 'sol' = 'arrow-left'; 'sağ' = 'arrow-right'; 'sag' = 'arrow-right'
    'güç' = 'power'; 'guc' = 'power'; 'aç' = 'power'; 'ac' = 'power'; 'pil' = 'battery'; 'batarya' = 'battery'; 'şarj' = 'charge'; 'sarj' = 'charge'
    'roket' = 'rocket'; 'yıldırım' = 'bolt'; 'yildirim' = 'bolt'; 'şimşek' = 'bolt'; 'simsek' = 'bolt'; 'ateş' = 'fire'; 'ates' = 'fire'; 'su' = 'water'
    'ev' = 'home'; 'okul' = 'school'; 'harita' = 'map'; 'konum' = 'pin'; 'işaret' = 'pin'; 'isaret' = 'pin'
    'bayrak' = 'flag'; 'kupa' = 'trophy'; 'ödül' = 'award'; 'odul' = 'award'; 'oyun' = 'game'; 'kumanda' = 'gamepad'
    'çevir' = 'flip'; 'cevir' = 'flip'; 'döndür' = 'rotate'; 'dondur' = 'rotate'; 'yansıt' = 'reflect'; 'yansit' = 'reflect'; 'ayna' = 'mirror'
}

# ------------------------------------------------------------------
#  Yardımcı Fonksiyonlar & İkon İşlemleri
# ------------------------------------------------------------------

function Convert-ToIco([string]$srcPath, [string]$dstPath) {
    $bytes = [System.IO.File]::ReadAllBytes($srcPath)
    $ms0 = New-Object System.IO.MemoryStream (,$bytes)
    $img = [System.Drawing.Image]::FromStream($ms0)
    try {
        $frames = @()
        foreach ($s in 256, 48, 32, 16) {
            $bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $scale = [Math]::Min($s / $img.Width, $s / $img.Height)
            $w = [int][Math]::Max(1, [Math]::Round($img.Width * $scale))
            $h = [int][Math]::Max(1, [Math]::Round($img.Height * $scale))
            $x = [int](($s - $w) / 2)
            $y = [int](($s - $h) / 2)
            $g.DrawImage($img, $x, $y, $w, $h)
            $g.Dispose()
            $ms = New-Object System.IO.MemoryStream
            $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $frames += , @{ Size = $s; Data = $ms.ToArray() }
            $bmp.Dispose(); $ms.Dispose()
        }

        $fs = [System.IO.File]::Create($dstPath)
        $bw = New-Object System.IO.BinaryWriter $fs
        try {
            $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$frames.Count)
            $offset = 6 + 16 * $frames.Count
            foreach ($f in $frames) {
                $dim = if ($f.Size -ge 256) { 0 } else { $f.Size }
                $bw.Write([byte]$dim); $bw.Write([byte]$dim)
                $bw.Write([byte]0);    $bw.Write([byte]0)
                $bw.Write([uint16]1);  $bw.Write([uint16]32)
                $bw.Write([uint32]$f.Data.Length)
                $bw.Write([uint32]$offset)
                $offset += $f.Data.Length
            }
            foreach ($f in $frames) { $bw.Write([byte[]]$f.Data) }
            $bw.Flush()
        }
        finally { $bw.Close(); $fs.Close() }
    }
    finally { $img.Dispose(); $ms0.Dispose() }
}

function Convert-TrQuery([string]$q) {
    $rawWords = $q.Trim().ToLower($trCulture) -split '\s+' | Where-Object { $_ }
    $out = foreach ($raw in $rawWords) {
        $w = $raw
        if ($TrMap.ContainsKey($w)) { 
            $TrMap[$w] 
        } else {
            # Çoğul ve yönelme eklerini temizleyerek kök ara
            $trimmed = $w -replace '(ler|lar|nin|nın|nun|nün|ye|ya|de|da|den|dan|i|ı|u|ü)$', ''
            if ($trimmed -and $TrMap.ContainsKey($trimmed)) {
                $TrMap[$trimmed]
            } else {
                $w
            }
        }
    }
    return ($out -join ' ')
}

function Search-Icons([string]$query, [int]$sourceIndex) {
    $script:iconifySearchWarning = $false
    $qTranslated = Convert-TrQuery $query
    $items = New-Object System.Collections.Generic.List[object]
    $seen = New-Object System.Collections.Generic.HashSet[string]

    $prefixes = switch ($sourceIndex) {
        0 { '' } # Tüm Kaynaklar: Filtresiz global arama (tüm kütüphaneler dahil)
        1 { 'material-symbols,material-symbols-light,material-icon-theme' }
        2 { 'fa6-solid,fa6-regular,fa6-brands,fa,fa-brands' }
        3 { 'lucide,feather' }
        4 { 'tabler' }
        5 { 'ri' }
        6 { 'bi' }
        7 { 'fluent' }
        8 { 'bx,bxs' }
        9 { 'carbon' }
        10 { 'ph,ph-bold,ph-fill' }
        11 { 'thesvg-color,streamline-color,fluent-color,flat-color-icons,fluent-emoji,noto,logos,vscode-icons' }
        12 { 'thesvg-color,streamline-color,icon-park,fluent-color,flat-color-icons,openmoji,fluent-emoji,fluent-emoji-flat,twemoji,noto,noto-v1,emojione,logos,vscode-icons,fluent,bi,tabler,ri' }
        13 { 'solar,iconmind,iconoven,keyline-icons,iconoir,system-uicons,iconamoon,majesticons,tabler,lucide,mingcute,tdesign' }
        default { '' }
    }

    # Hem İngilizce çeviriyle hem de orijinal kelimeyle arama yaparak en zengin sonuçları topla
    $searchQueries = New-Object System.Collections.Generic.List[string]
    if ($qTranslated) { $searchQueries.Add($qTranslated) }
    $rawTrim = $query.Trim().ToLower()
    if ($rawTrim -and $rawTrim -ne $qTranslated -and -not $searchQueries.Contains($rawTrim)) {
        $searchQueries.Add($rawTrim)
    }

    # Eş anlamlı / varyant kelimeler (kütüphaneler arası isimlendirme farklarını kapatır)
    $synonyms = @{
        'flip'     = @('reflect', 'mirror')
        'reflect'  = @('flip', 'mirror')
        'mirror'   = @('flip', 'reflect')
        'rotate'   = @('turn', 'sync', 'refresh')
        'settings' = @('gear', 'cog', 'preferences', 'tools')
        'trash'    = @('delete', 'bin', 'remove')
        'delete'   = @('trash', 'bin', 'remove')
        'edit'     = @('pencil', 'write', 'modify')
    }
    foreach ($sq in @($searchQueries)) {
        if ($synonyms.ContainsKey($sq)) {
            foreach ($syn in $synonyms[$sq]) {
                if (-not $searchQueries.Contains($syn)) {
                    $searchQueries.Add($syn)
                }
            }
        }
    }

    foreach ($currentQ in $searchQueries) {
        try {
            $queryPart = '?query=' + [uri]::EscapeDataString($currentQ) + '&limit=250'
            if ($prefixes) { $queryPart += '&prefixes=' + [uri]::EscapeDataString($prefixes) }
            $json = $null
            foreach ($apiHost in @('https://api.iconify.design','https://api.simplesvg.com','https://api.unisvg.com')) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Encoding = [System.Text.Encoding]::UTF8
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.8.0'
                    $json = $wc.DownloadString($apiHost + '/search' + $queryPart) | ConvertFrom-Json
                    if ($json -and $null -ne $json.icons) { break }
                } catch { }
            }
            if ($json -and $json.icons) {
                $providerName = switch ($sourceIndex) {
                    12 { 'Flaticon Koleksiyonu' }
                    13 { 'Magnific Koleksiyonu' }
                    default { 'Iconify' }
                }
                foreach ($name in @($json.icons)) {
                    $strName = [string]$name
                    if ($strName -match '^([^:]+):(.+)$' -and -not $seen.Contains($strName)) {
                        [void]$seen.Add($strName)
                        $items.Add([pscustomobject]@{ Name=$strName; Provider=$providerName; PreviewUrl=$null; DownloadUrl=$null; License='Açık Kaynak (Ücretsiz / Özgür Lisans)' })
                    }
                }
            }
        } catch {
            $script:iconifySearchWarning = $true
        }
    }

    return @{ Query = $qTranslated; Icons = @($items | Select-Object -First 300) }
}

function Convert-SvgToDrawingGroup([string]$svgContent, [string]$overrideHex = '') {
    try {
        [xml]$xml = $svgContent
        $svg = $xml.svg
        if (-not $svg) { return $null }

        $dg = New-Object System.Windows.Media.DrawingGroup
        
        $cleanHex = $overrideHex -replace '^#',''
        $defaultBrush = if ($cleanHex) { 
            [System.Windows.Media.BrushConverter]::new().ConvertFromString("#$cleanHex") 
        } else { 
            [System.Windows.Media.Brushes]::Black 
        }

        $process = {
            param($node, $parentFill, $parentStroke, $parentStrokeWidth)
            $nodeFill = if ($node.HasAttribute('fill')) { $node.GetAttribute('fill') } else { $null }
            $nodeStroke = if ($node.HasAttribute('stroke')) { $node.GetAttribute('stroke') } else { $null }
            $nodeStrokeWidth = if ($node.HasAttribute('stroke-width')) { $node.GetAttribute('stroke-width') } else { $null }

            $curFill = if ($null -ne $nodeFill) { $nodeFill } else { $parentFill }
            $curStroke = if ($null -ne $nodeStroke) { $nodeStroke } else { $parentStroke }
            $curStrokeWidth = if ($null -ne $nodeStrokeWidth) { $nodeStrokeWidth } else { $parentStrokeWidth }

            $brush = $null
            if ($curFill -and $curFill -ne 'none') {
                if ($cleanHex -and ($curFill -eq 'currentColor' -or $curFill -eq 'black' -or $curFill -eq '#000' -or $curFill -eq '#000000')) {
                    $brush = $defaultBrush
                } elseif ($cleanHex -and -not $nodeFill -and -not $parentFill) {
                    $brush = $defaultBrush
                } else {
                    try { $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($curFill) } catch { $brush = $defaultBrush }
                }
            }

            $pen = $null
            if ($curStroke -and $curStroke -ne 'none') {
                $sBrush = if ($cleanHex -and ($curStroke -eq 'currentColor' -or $curStroke -eq 'black' -or $curStroke -eq '#000' -or $curStroke -eq '#000000')) {
                    $defaultBrush
                } else {
                    try { [System.Windows.Media.BrushConverter]::new().ConvertFromString($curStroke) } catch { $defaultBrush }
                }
                $sw = 1.0
                if ($curStrokeWidth) {
                    [double]::TryParse($curStrokeWidth, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$sw) | Out-Null
                }
                $pen = New-Object System.Windows.Media.Pen ($sBrush, $sw)
                $pen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
                $pen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
                $pen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
            }

            $geom = $null
            switch ($node.LocalName) {
                'path' {
                    $d = $node.GetAttribute('d')
                    if ($d) { try { $geom = [System.Windows.Media.Geometry]::Parse($d) } catch {} }
                }
                'rect' {
                    $rx = 0.0; $ry = 0.0; $rw = 0.0; $rh = 0.0; $rcx = 0.0; $rcy = 0.0
                    [double]::TryParse($node.GetAttribute('x'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rx) | Out-Null
                    [double]::TryParse($node.GetAttribute('y'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$ry) | Out-Null
                    [double]::TryParse($node.GetAttribute('width'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rw) | Out-Null
                    [double]::TryParse($node.GetAttribute('height'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rh) | Out-Null
                    [double]::TryParse($node.GetAttribute('rx'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rcx) | Out-Null
                    [double]::TryParse($node.GetAttribute('ry'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rcy) | Out-Null
                    if ($rw -gt 0 -and $rh -gt 0) {
                        $rct = New-Object System.Windows.Rect $rx, $ry, $rw, $rh
                        $geom = New-Object System.Windows.Media.RectangleGeometry $rct, $rcx, $rcy
                    }
                }
                'circle' {
                    $cx = 0.0; $cy = 0.0; $r = 0.0
                    [double]::TryParse($node.GetAttribute('cx'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$cx) | Out-Null
                    [double]::TryParse($node.GetAttribute('cy'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$cy) | Out-Null
                    [double]::TryParse($node.GetAttribute('r'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$r) | Out-Null
                    if ($r -gt 0) {
                        $pt = New-Object System.Windows.Point $cx, $cy
                        $geom = New-Object System.Windows.Media.EllipseGeometry $pt, $r, $r
                    }
                }
                'line' {
                    $x1 = 0.0; $y1 = 0.0; $x2 = 0.0; $y2 = 0.0
                    [double]::TryParse($node.GetAttribute('x1'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$x1) | Out-Null
                    [double]::TryParse($node.GetAttribute('y1'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$y1) | Out-Null
                    [double]::TryParse($node.GetAttribute('x2'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$x2) | Out-Null
                    [double]::TryParse($node.GetAttribute('y2'), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$y2) | Out-Null
                    $p1 = New-Object System.Windows.Point $x1, $y1
                    $p2 = New-Object System.Windows.Point $x2, $y2
                    $geom = New-Object System.Windows.Media.LineGeometry $p1, $p2
                }
            }

            if ($geom) {
                if (-not $brush -and -not $pen) { $brush = $defaultBrush }
                $dg.Children.Add((New-Object System.Windows.Media.GeometryDrawing ($brush, $pen, $geom)))
            }

            foreach ($child in $node.ChildNodes) {
                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    & $process $child $curFill $curStroke $curStrokeWidth
                }
            }
        }

        foreach ($child in $svg.ChildNodes) {
            if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                & $process $child 'currentColor' 'none' '1'
            }
        }

        return $dg
    } catch {
        return $null
    }
}

function Convert-SvgToPngFile([string]$svgContent, [string]$destinationPng, [string]$hexColor = '0078D4', [int]$size = 256) {
    try {
        $dg = Convert-SvgToDrawingGroup $svgContent $hexColor
        if (-not $dg -or $dg.Children.Count -eq 0) { return $false }

        $bounds = [System.Windows.Rect]::Empty
        foreach ($d in $dg.Children) {
            $bounds.Union($d.Bounds)
        }
        if ($bounds.IsEmpty -or $bounds.Width -le 0 -or $bounds.Height -le 0) {
            $bounds = New-Object System.Windows.Rect 0, 0, 24, 24
        }

        $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap ($size, $size, 96.0, 96.0, [System.Windows.Media.PixelFormats]::Pbgra32)
        $dv = New-Object System.Windows.Media.DrawingVisual
        $dc = $dv.RenderOpen()

        $targetInner = [double]($size - 24)
        $scale = [Math]::Min($targetInner / [Math]::Max(1.0, $bounds.Width), $targetInner / [Math]::Max(1.0, $bounds.Height))
        $tg = New-Object System.Windows.Media.TransformGroup
        $tg.Children.Add((New-Object System.Windows.Media.TranslateTransform (-$bounds.X), (-$bounds.Y)))
        $tg.Children.Add((New-Object System.Windows.Media.ScaleTransform ($scale, $scale)))
        $tg.Children.Add((New-Object System.Windows.Media.TranslateTransform ((([double]$size - ($bounds.Width * $scale)) / 2.0), (([double]$size - ($bounds.Height * $scale)) / 2.0))))

        $dc.PushTransform($tg)
        $dc.DrawDrawing($dg)
        $dc.Pop()
        $dc.Close()

        $rtb.Render($dv)

        $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create([System.Windows.Media.Imaging.BitmapSource]$rtb))
        $fs = [System.IO.File]::Create($destinationPng)
        try {
            $enc.Save($fs)
        } finally {
            $fs.Close()
        }
        return (Test-Path -LiteralPath $destinationPng)
    } catch {
        return $false
    }
}

function Safe-Prop($obj, [string]$propName, $defaultVal = $null) {
    if ($null -ne $obj -and $obj.PSObject.Properties[$propName]) {
        return $obj.PSObject.Properties[$propName].Value
    }
    return $defaultVal
}

function Get-IconBatchSvgs($iconItems) {
    $byPrefix = @{}
    foreach ($item in $iconItems) {
        $name = [string]$item.Name
        $parts = $name.Split(':', 2)
        if ($parts.Count -eq 2) {
            $p = $parts[0]; $iName = $parts[1]
            if (-not $byPrefix.ContainsKey($p)) { $byPrefix[$p] = New-Object System.Collections.Generic.List[string] }
            $byPrefix[$p].Add($iName)
        }
    }

    $svgCache = @{}
    $wc = New-Object System.Net.WebClient
    $wc.Encoding = [System.Text.Encoding]::UTF8
    $wc.Headers['User-Agent'] = 'PwX-Studio/1.8.0'

    foreach ($p in $byPrefix.Keys) {
        $list = $byPrefix[$p]
        for ($i = 0; $i -lt $list.Count; $i += 40) {
            $chunk = @($list | Select-Object -Skip $i -First 40)
            $namesStr = $chunk -join ','
            $url = "https://api.iconify.design/$p.json?icons=$namesStr"
            try {
                $json = $wc.DownloadString($url) | ConvertFrom-Json
                $pWidth = Safe-Prop $json 'width' 24
                $pHeight = Safe-Prop $json 'height' 24
                $iconsProp = Safe-Prop $json 'icons' $null
                if ($null -ne $iconsProp) {
                    foreach ($prop in $iconsProp.PSObject.Properties) {
                        $iName = $prop.Name
                        $iVal = $prop.Value
                        $w = Safe-Prop $iVal 'width' $pWidth
                        $h = Safe-Prop $iVal 'height' $pHeight
                        $body = Safe-Prop $iVal 'body' ''
                        if ($body) {
                            $svgStr = "<svg xmlns=`"http://www.w3.org/2000/svg`" viewBox=`"0 0 $w $h`" width=`"$w`" height=`"$h`">$body</svg>"
                            $svgCache["${p}:$iName"] = $svgStr
                        }
                    }
                }
            } catch {}
        }
    }

    foreach ($item in $iconItems) {
        $name = [string]$item.Name
        if (-not $svgCache.ContainsKey($name)) {
            $parts = $name.Split(':', 2)
            if ($parts.Count -eq 2) {
                try {
                    $s = $wc.DownloadString("https://api.iconify.design/$($parts[0])/$($parts[1]).svg")
                    if ($s -and $s.Contains('<svg')) {
                        $svgCache[$name] = $s
                    }
                } catch {}
            }
        }
    }

    return $svgCache
}

function Get-PreviewBitmapImage([string]$path) {
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $fullPath = (Resolve-Path -LiteralPath $path).Path
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $ms = New-Object System.IO.MemoryStream (,$bytes)
        $bi = New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit()
        $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bi.StreamSource = $ms
        $bi.EndInit()
        $bi.Freeze()
        return $bi
    } catch {
        return $null
    }
}

# ------------------------------------------------------------------
#  XAML Arayüz Tanımı (Dinamik Tema Desteği & 2 Sütunlu Düzen)
# ------------------------------------------------------------------

# Kucuk ekranlar (15.6" dizustu, yuksek DPI olcekleme) icin pencereyi calisma alanina sigdir
function Set-WindowFitToWorkArea {
    param([System.Windows.Window]$Win, [double]$Margin = 24, [switch]$Center)
    try {
        $wa   = [System.Windows.SystemParameters]::WorkArea
        $maxW = [Math]::Max(480, $wa.Width  - $Margin)
        $maxH = [Math]::Max(420, $wa.Height - $Margin)
        $Win.MaxWidth  = $maxW
        $Win.MaxHeight = $maxH
        if ($Win.MinWidth  -gt $maxW) { $Win.MinWidth  = $maxW }
        if ($Win.MinHeight -gt $maxH) { $Win.MinHeight = $maxH }
        if ($Win.Width  -gt $maxW) { $Win.Width  = $maxW }
        if ($Win.Height -gt $maxH) { $Win.Height = $maxH }
        if ($Center) {
            $Win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
            $Win.Left = $wa.Left + [Math]::Max(0, ($wa.Width  - $Win.Width)  / 2)
            $Win.Top  = $wa.Top  + [Math]::Max(0, ($wa.Height - $Win.Height) / 2)
        }
    } catch {}
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PwX Studio v1.8.0 - PowerShell Executable Builder"
        Height="840" Width="980" MinHeight="680" MinWidth="840"
        WindowStartupLocation="CenterScreen"
        Background="{DynamicResource BgBrush}" Foreground="{DynamicResource TextBrush}" 
        FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif"
        AllowDrop="True">

    <Window.Resources>
        <!-- Tema Renk Fırçaları (Varsayılan Koyu Tema) -->
        <SolidColorBrush x:Key="BgBrush" Color="#202020"/>
        <SolidColorBrush x:Key="CardBrush" Color="#262626"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#333333"/>
        <SolidColorBrush x:Key="TextBrush" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="SubTextBrush" Color="#A0A0A0"/>
        <SolidColorBrush x:Key="InputBgBrush" Color="#1C1C1C"/>
        <SolidColorBrush x:Key="InputBorderBrush" Color="#383838"/>
        <SolidColorBrush x:Key="BtnBgBrush" Color="#333333"/>
        <SolidColorBrush x:Key="BtnBorderBrush" Color="#3D3D3D"/>
        <SolidColorBrush x:Key="BtnTextBrush" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TerminalBgBrush" Color="#141414"/>
        <SolidColorBrush x:Key="TerminalBorderBrush" Color="#282828"/>
        <SolidColorBrush x:Key="TerminalTextBrush" Color="#E0E0E0"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#0078D4"/>
        <SolidColorBrush x:Key="AccentBorderBrush" Color="#005A9E"/>

        <!-- Standart Buton Stili -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource BtnBgBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource BtnTextBrush}" />
            <Setter Property="Padding" Value="14,8" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="BorderBrush" Value="{DynamicResource BtnBorderBrush}" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Primary Buton Stili -->
        <Style x:Key="PrimaryBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{DynamicResource AccentBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource AccentBorderBrush}" />
            <Setter Property="Foreground" Value="#FFFFFF" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1084D9"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#2B95E0"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Giriş Kutusu Stili -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{DynamicResource InputBgBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource InputBorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="10,7" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="CaretBrush" Value="{DynamicResource AccentBrush}" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden" Padding="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- CheckBox & RadioButton Stilleri -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Margin" Value="0,5,8,5" />
        </Style>

        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Margin" Value="0,4,12,4" />
        </Style>

        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#2D2D2D" />
            <Setter Property="Foreground" Value="#FFFFFF" />
            <Setter Property="BorderBrush" Value="#454545" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="10,6" />
            <Setter Property="FontSize" Value="12" />
        </Style>

        <!-- Windows 11 Fluent Tema Anahtarı (Toggle Switch) Stili -->
        <Style x:Key="ThemeToggleSwitch" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="ToolTip" Value="Açık ve Koyu tema arasında geçiş yapar."/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock x:Name="lblThemeText" Text="🌙 Koyu Tema" FontSize="12" FontWeight="SemiBold" 
                                       Foreground="{DynamicResource SubTextBrush}" VerticalAlignment="Center" Margin="0,0,10,0"/>
                            <Grid Width="56" Height="28">
                                <!-- Kapsül Gövde (Track) -->
                                <Border x:Name="track" Background="#181818" BorderBrush="#3D3D3D" BorderThickness="1.5" CornerRadius="14">
                                    <Grid>
                                        <TextBlock Text="☀️" FontSize="10" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="7,0,0,0" Opacity="0.6"/>
                                        <TextBlock Text="🌙" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,7,0" Opacity="0.8"/>
                                    </Grid>
                                </Border>
                                <!-- Kayan Yuvarlak Topuz (Knob) -->
                                <Border x:Name="knob" Background="#FFFFFF" Width="20" Height="20" CornerRadius="10" 
                                        HorizontalAlignment="Left" VerticalAlignment="Center" Margin="4,0,0,0">
                                    <Border.Effect>
                                        <DropShadowEffect BlurRadius="4" ShadowDepth="1" Opacity="0.35"/>
                                    </Border.Effect>
                                </Border>
                            </Grid>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <!-- IsChecked = True (Açık Tema Seçildiğinde) -->
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="lblThemeText" Property="Text" Value="☀️ Açık Tema"/>
                                <Setter TargetName="track" Property="Background" Value="#0078D4"/>
                                <Setter TargetName="track" Property="BorderBrush" Value="#005A9E"/>
                                <Setter TargetName="knob" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="knob" Property="Margin" Value="0,0,4,0"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="track" Property="BorderBrush" Value="#0078D4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    
        <!-- Fluent ComboBox ToggleButton Şablonu -->
        <ControlTemplate x:Key="FluentComboBoxToggleButton" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition />
                    <ColumnDefinition Width="32" />
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" CornerRadius="6" 
                        Background="{DynamicResource InputBgBrush}" 
                        BorderBrush="{DynamicResource InputBorderBrush}" 
                        BorderThickness="1" />
                <Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" 
                      Data="M 0 0 L 4.5 4.5 L 9 0" Stroke="{DynamicResource TextBrush}" StrokeThickness="1.5" 
                      StrokeStartLineCap="Round" StrokeEndLineCap="Round" SnapsToDevicePixels="True"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                    <Setter TargetName="Arrow" Property="Stroke" Value="{DynamicResource AccentBrush}"/>
                </Trigger>
                <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                    <Setter TargetName="Arrow" Property="Data" Value="M 0 4.5 L 4.5 0 L 9 4.5"/>
                    <Setter TargetName="Arrow" Property="Stroke" Value="{DynamicResource AccentBrush}"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter TargetName="Border" Property="Opacity" Value="0.45"/>
                    <Setter TargetName="Arrow" Property="Opacity" Value="0.45"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <!-- Fluent ComboBoxItem Şablonu -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="ItemBorder" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}" Margin="3,1.5">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="{DynamicResource AccentBrush}"/>
                                <Setter Property="TextElement.Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="{DynamicResource AccentBorderBrush}"/>
                                <Setter Property="TextElement.Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Genel ComboBox Stili -->
        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="Background" Value="{DynamicResource InputBgBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource InputBorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,4"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton" 
                                          Template="{StaticResource FluentComboBoxToggleButton}" 
                                          Focusable="false"
                                          IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}"
                                          ClickMode="Press">
                            </ToggleButton>
                            <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="10,3,32,3"
                                              VerticalAlignment="Center"
                                              HorizontalAlignment="Left" />
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True" 
                                   Focusable="False"
                                   PopupAnimation="Fade">
                                <Grid Name="DropDown"
                                      SnapsToDevicePixels="True"
                                      MinWidth="{TemplateBinding ActualWidth}"
                                      MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border x:Name="DropDownBorder"
                                            Background="{DynamicResource CardBrush}"
                                            BorderThickness="1"
                                            BorderBrush="{DynamicResource BorderBrush}"
                                            CornerRadius="6"
                                            Margin="0,4,0,4"
                                            Padding="4">
                                        <Border.Effect>
                                            <DropShadowEffect BlurRadius="8" ShadowDepth="2" Opacity="0.3" Color="#000000"/>
                                        </Border.Effect>
                                        <ScrollViewer SnapsToDevicePixels="True" MaxHeight="240">
                                            <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained" />
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="HasItems" Value="false">
                                <Setter TargetName="DropDownBorder" Property="MinHeight" Value="40"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- PasswordBox Stili -->
        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="{DynamicResource InputBgBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource InputBorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="10,7" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="CaretBrush" Value="{DynamicResource AccentBrush}" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="PasswordBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden" Padding="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="170" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- 1. Header (Marka Başlığı & Sağda Tema Anahtarı) -->
        <Border Grid.Row="0" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="⚡ PwX Studio" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource TextBrush}" />
                        <Border Background="{DynamicResource BorderBrush}" CornerRadius="4" Padding="8,2" Margin="12,2,0,2" VerticalAlignment="Center">
                            <TextBlock Text="v1.8.0" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
                        </Border>
                    </StackPanel>
                    <TextBlock x:Name="LblSubtitle" Text="PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." 
                               FontSize="13" Foreground="{DynamicResource SubTextBrush}" Margin="0,3,0,0" />
                </StackPanel>

                <!-- Açık / Koyu Tema Geçiş Anahtarı (Toggle Switch) -->
                <!-- SaÄŸ Butonlar: Dil SeÃ§ici ve Tema AnahtarÄ± -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnLangToggle" Content="&#x1F310; TR" Height="30" MinWidth="85" Padding="8,2" Margin="0,0,12,0" 
                            FontWeight="Bold" FontSize="12" ToolTip="Dili DeÄŸiÅŸtir (Ä°ngilizce'ye geÃ§ / Switch to English)"/>
                    <CheckBox x:Name="BtnThemeToggle" Style="{StaticResource ThemeToggleSwitch}" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- 2. Orta Kartlar (ScrollViewer) -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="0,0,0,10" Padding="0,0,6,0">
            <StackPanel>

                <!-- Kart: Dosya Yapılandırması -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock x:Name="LblFileConfigTitle" Text="📁 Dosya Yapılandırması" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,12"/>
                        
                        <TextBlock x:Name="LblSourcePs1" Text="Kaynak PowerShell Betiği (.ps1):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,12">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="10" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="TxtPs1" Grid.Column="0" Height="38" ToolTip="Dönüştürülecek .ps1 betiğini seçin veya dosyayı buraya sürükleyin."/>
                            <Button x:Name="BtnPs1Browse" Grid.Column="2" Content="📁 Gözat..." Width="100" Height="38"/>
                        </Grid>

                        <TextBlock x:Name="LblTargetExe" Text="Hedef Yürütülebilir Dosya (.exe):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,4">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="10" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="TxtOut" Grid.Column="0" Height="38" ToolTip="Oluşturulacak .exe dosyasının kaydedileceği konumu belirleyin."/>
                            <Button x:Name="BtnOutBrowse" Grid.Column="2" Content="💾 Farklı Kaydet..." Width="120" Height="38"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Kart: İkon ve Logo Seçimi -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="20" />
                            <ColumnDefinition Width="90" />
                        </Grid.ColumnDefinitions>

                        <StackPanel Grid.Column="0">
                            <TextBlock x:Name="LblAppIcon" Text="🎨 Uygulama Logosu &amp; Simgesi" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <TextBlock x:Name="LblIconFile" Text="Görsel Dosyası (PNG, JPG, BMP, ICO):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                            <Grid Margin="0,0,0,8">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*" />
                                    <ColumnDefinition Width="8" />
                                    <ColumnDefinition Width="Auto" />
                                    <ColumnDefinition Width="8" />
                                    <ColumnDefinition Width="Auto" />
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="TxtLogo" Grid.Column="0" Height="38" ToolTip="Uygulama simgesi olarak gömülecek görseli seçin."/>
                                <Button x:Name="BtnLogoBrowse" Grid.Column="2" Content="🖼️ Dosyadan Seç" Height="38" Padding="12,0"/>
                                <Button x:Name="BtnWebSearch" Grid.Column="4" Content="🌐 Web'den İkon Ara" Height="38" Padding="12,0"/>
                            </Grid>
                            <TextBlock x:Name="LblIconHint" Text="Seçilen PNG/JPG görseller derleme anında otomatik olarak 256x256 ICO formatına dönüştürülür." FontSize="11" Foreground="{DynamicResource SubTextBrush}"/>
                        </StackPanel>

                        <!-- Canlı Önizleme Kutusu -->
                        <StackPanel Grid.Column="2" VerticalAlignment="Center" HorizontalAlignment="Center">
                            <Border Width="76" Height="76" Background="{DynamicResource InputBgBrush}" BorderBrush="{DynamicResource InputBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="4">
                                <Grid>
                                    <TextBlock x:Name="TxtNoIcon" Text="SİMGE YOK" FontSize="10" Foreground="{DynamicResource SubTextBrush}" HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center" FontWeight="SemiBold"/>
                                    <Image x:Name="ImgPreview" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                                </Grid>
                            </Border>
                            <TextBlock x:Name="LblPreview" Text="Önizleme" FontSize="10" Foreground="{DynamicResource SubTextBrush}" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- Kart: Meta Veriler -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock x:Name="LblAppInfo" Text="ℹ️ Uygulama Bilgileri &amp; Meta Veriler" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,12"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="2*" />
                                <ColumnDefinition Width="14" />
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="14" />
                                <ColumnDefinition Width="2*" />
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0">
                                <TextBlock x:Name="LblAppTitle" Text="Uygulama Adı / Başlık:" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                                <TextBox x:Name="TxtTitle" Height="38"/>
                            </StackPanel>

                            <StackPanel Grid.Column="2">
                                <TextBlock x:Name="LblVersion" Text="Sürüm (x.x.x.x):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                                <TextBox x:Name="TxtVer" Height="38" Text="1.0.0.0"/>
                            </StackPanel>

                            <StackPanel Grid.Column="4">
                                <TextBlock x:Name="LblCompany" Text="Şirket / Yayıncı:" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                                <TextBox x:Name="TxtCompany" Height="38"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Kart: 2 Sütunlu Düzenli Seçenekler Alanı (Sol: Motor & Tür | Sağ: Derleme Seçenekleri) -->
                <Grid Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="14" />
                        <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>

                    <!-- Sol Sütun: Hedef Çalışma Zamanı & Uygulama Türü -->
                    <Border Grid.Column="0" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16">
                        <StackPanel>
                            <TextBlock x:Name="LblTargetRuntime" Text="⚙️ Hedef Çalışma Zamanı" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <RadioButton x:Name="RbTargetPS51" GroupName="TargetRuntime" Content="PowerShell 5.1 (Dahili csc.exe)" IsChecked="True" 
                                         ToolTip="Windows ile dahili gelen csc.exe derleyicisini kullanır." Margin="0,2,0,8"/>
                            <RadioButton x:Name="RbTargetPS7" GroupName="TargetRuntime" Content="PowerShell 7.4+ (.NET 8 SDK)" 
                                         ToolTip="Modern PowerShell 7 ve .NET 8 SDK altyapısını kullanır." Margin="0,0,0,6"/>
                            <CheckBox x:Name="ChkSingleFile" Content="Tek Dosya (Single-File)" IsEnabled="False" Margin="22,0,0,6"/>
                            <CheckBox x:Name="ChkSmallSize" Content="Küçük boyut (hedefte .NET 8 Runtime gerekir)" IsEnabled="False" Margin="22,0,0,16"
                                      ToolTip="FrameworkDependent: .NET çalışma zamanı EXE'ye eklenmez, çıktı çok daha küçük olur. Çalıştıracak bilgisayarda .NET 8 Runtime (GUI için Windows Desktop Runtime 8) kurulu olmalıdır. pwsh gerekmez."/>

                            <Border Height="1" Background="{DynamicResource BorderBrush}" Margin="0,0,0,14"/>

                            <TextBlock x:Name="LblAppType" Text="🖥️ Uygulama Türü" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <RadioButton x:Name="RbConsole" GroupName="AppMode" Content="Konsol Uygulaması (CLI)" IsChecked="True" Margin="0,2,0,8"/>
                            <RadioButton x:Name="RbGui" GroupName="AppMode" Content="Pencereli / GUI Uygulama (Konsol Gizli)" Margin="0,0,0,4"/>

                            <Border Height="1" Background="{DynamicResource BorderBrush}" Margin="0,12,0,12"/>

                            <TextBlock x:Name="LblEngineSelection" Text="🚀 Derleme Motoru Seçimi" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                            <CheckBox x:Name="ChkEmbeddedEngine" Content="Dahili pwxe Motoru (Taşınabilir / Offline)" IsChecked="True" 
                                      ToolTip="pwxe motorunu dış klasörlere ihtiyaç duymadan doğrudan uygulama içerisindeki gömülü motordan çalıştırır. Uygulama masaüstüne veya başka bilgisayara taşındığında sorunsuz çalışmasını sağlar." Margin="0,0,0,4"/>
                        </StackPanel>
                    </Border>

                    <!-- Sağ Sütun: Derleme & Çalışma Bayrakları (2 Alt Sütunlu Tertipli Liste) -->
                    <Border Grid.Column="2" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16">
                        <StackPanel>
                            <TextBlock x:Name="LblBuildOptions" Text="🛠️ Derleme &amp; Çalışma Seçenekleri" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*" />
                                    <ColumnDefinition Width="10" />
                                    <ColumnDefinition Width="*" />
                                </Grid.ColumnDefinitions>

                                <StackPanel Grid.Column="0">
                                    <TextBlock x:Name="LblUacLevel" Text="🛡️ UAC Yetki Düzeyi:" FontSize="11" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,3"/>
                                    <ComboBox x:Name="CmbExecutionLevel" Height="32" Margin="0,0,0,6" ToolTip="Windows UAC çalıştırma ve bildirim yetki düzeyini belirler.">
                                        <ComboBoxItem x:Name="CmbItemAsInvoker" Content="asInvoker (Standart)" Tag="asInvoker" IsSelected="True" ToolTip="Uygulama çağıran kullanıcının standart yetkileriyle başlatılır. Ekstra yönetici onayı istemez."/>
                                        <ComboBoxItem x:Name="CmbItemRequireAdmin" Content="requireAdministrator (Yönetici)" Tag="requireAdministrator" ToolTip="Uygulama her açılışta Windows UAC yönetici onayı ister ve tam yönetici ayrıcalıklarıyla çalışır."/>
                                        <ComboBoxItem x:Name="CmbItemHighestAvailable" Content="highestAvailable (En Yüksek)" Tag="highestAvailable" ToolTip="Kullanıcı yöneticiyse yönetici onayı ister; standart kullanıcıysa ek onay istemeden çalışır."/>
                                    </ComboBox>
                                    <CheckBox x:Name="ChkAdmin" Content="Yönetici Yetkisi (UAC)" ToolTip="Windows UAC yönetici onayı ister." Margin="0,0,0,5"/>
                                    <CheckBox x:Name="ChkUtf8" Content="Konsol UTF-8" IsChecked="True" ToolTip="Türkçe karakterlerin doğru gösterilmesini sağlar."/>
                                    <CheckBox x:Name="ChkX64" Content="64-bit (x64)" IsChecked="True" ToolTip="64-bit mimari için derler."/>
                                    <CheckBox x:Name="ChkX86" Content="32-bit (x86)" ToolTip="32-bit mimari uyumluluğu sağlar."/>
                                    <CheckBox x:Name="ChkUnicode" Content="Unicode Konsol" ToolTip="Genişletilmiş karakter desteği sağlar."/>
                                </StackPanel>

                                <StackPanel Grid.Column="2">
                                    <CheckBox x:Name="ChkDpi" Content="DPI Farkındalığı" ToolTip="Yüksek çözünürlüklü ekranlarda net görünüm sağlar."/>
                                    <CheckBox x:Name="ChkConfig" Content="EXE.config Oluştur" ToolTip="DPI ve runtime ayarları için .config dosyası üretir."/>
                                    <CheckBox x:Name="ChkSupportOS" Content="Windows Sürüm Bilgisi" ToolTip="Modern Windows sürümleriyle uyumluluk bildirir."/>
                                    <CheckBox x:Name="ChkLongPaths" Content="Uzun Dosya Yolları" ToolTip="260 karakterden uzun dosya yollarına izin verir."/>
                                    <CheckBox x:Name="ChkNoOutput" Content="Çıktıyı Bastır" ToolTip="Standart konsol çıktısını bastırır."/>
                                    <CheckBox x:Name="ChkEncryptPayload" Content="Betiği Şifrele (AES-256)" ToolTip="Gömülü betiği AES-256-CBC ve HMAC-SHA256 ile şifreler, düz metin sızıntısını önler."/>
                                    <CheckBox x:Name="ChkBindToMachine" Content="Makineye Kilitle (DPAPI)" ToolTip="Şifreleme anahtarını Windows DPAPI ile bu makine ve kullanıcıya kilitler."/>
                                </StackPanel>
                            </Grid>
                        </StackPanel>
                    </Border>
                </Grid>

                                <!-- Kart: Authenticode Dijital Kod İmzalama (v1.8.0) -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBlock x:Name="LblCodeSigningTitle" Text="🔏 Authenticode Dijital Kod İmzalama (v1.8.0)" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                            <CheckBox x:Name="ChkSign" Grid.Column="1" Content="İmzalama Etkin" VerticalAlignment="Center" Margin="0" ToolTip="Üretilen EXE'yi Authenticode dijital sertifikası ile imzalar."/>
                        </Grid>
                        
                        <Grid x:Name="PnlSignSettings" Margin="0,4,0,0">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto" />
                                <RowDefinition Height="Auto" />
                            </Grid.RowDefinitions>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="14" />
                                <ColumnDefinition Width="*" />
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Row="0" Grid.Column="0">
                                <TextBlock x:Name="LblCertType" Text="Sertifika Kaynağı:" FontSize="12" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,4"/>
                                <ComboBox x:Name="CmbCertSource" Height="34" Margin="0,0,0,8" ToolTip="Authenticode dijital kod imzalama sertifikasının temin edileceği kaynağı seçin.">
                                    <ComboBoxItem x:Name="CmbItemThumbprint" Content="Parmak İzi (Thumbprint - Windows Deposu)" Tag="Thumbprint" IsSelected="True" ToolTip="Windows Sertifika Deposundaki (CurrentUser\My) yüklü kod imzalama sertifikasını kullanır."/>
                                    <ComboBoxItem x:Name="CmbItemFile" Content="PFX / P12 Dosyası" Tag="File" ToolTip="Diskte bulunan .pfx veya .p12 sertifika dosyasını kullanır."/>
                                </ComboBox>

                                <TextBlock x:Name="LblCertValue" Text="Sertifika Parmak İzi (Thumbprint):" FontSize="12" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,4"/>
                                <Grid Margin="0,0,0,8">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                    </Grid.ColumnDefinitions>
                                    <TextBox x:Name="TxtCertValue" Height="34" ToolTip="40 karakterlik HEX parmak izi veya PFX dosya yolu."/>
                                    <Button x:Name="BtnBrowseCert" Grid.Column="1" Content="Sertifika Seç..." Margin="8,0,0,0" Height="34" Width="110" Visibility="Visible" ToolTip="Windows Sertifika Deposundan (CurrentUser\My) kod imzalama sertifikası seçin."/>
                                </Grid>
                            </StackPanel>

                            <StackPanel Grid.Row="0" Grid.Column="2">
                                <TextBlock x:Name="LblCertPassword" Text="Sertifika Parolası (PFX için):" FontSize="12" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,4"/>
                                <PasswordBox x:Name="TxtCertPassword" Height="34" Margin="0,0,0,8" ToolTip="PFX sertifikanız şifreliyse giriniz."/>

                                <TextBlock x:Name="LblTimestampServer" Text="RFC 3161 Zaman Damgası Sunucusu:" FontSize="12" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,4"/>
                                <TextBox x:Name="TxtTimestampServer" Text="http://timestamp.digicert.com" Height="34" Margin="0,0,0,8" ToolTip="Varsayılan: http://timestamp.digicert.com"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Kart: Eylemler & İlerleme -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,4">
                    <StackPanel>
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="12" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <Button x:Name="BtnBuild" Grid.Column="0" Content="🚀 EXE OLUŞTUR" Style="{StaticResource PrimaryBtn}" Height="44" FontSize="15"/>
                            <Button x:Name="BtnOpenFolder" Grid.Column="2" Content="📂 Klasörü Aç" Height="44" Width="140" IsEnabled="False"/>
                        </Grid>

                        <ProgressBar x:Name="PbStatus" Height="6" Background="{DynamicResource TerminalBgBrush}" Foreground="{DynamicResource AccentBrush}" BorderThickness="0" Margin="0,4,0,8"/>
                        <TextBlock x:Name="TxtStatus" Text="Hazır. Kaynak betiği belirleyip 'EXE OLUŞTUR' butonuna basınız." FontSize="12" Foreground="{DynamicResource SubTextBrush}"/>
                    </StackPanel>
                </Border>

            </StackPanel>
        </ScrollViewer>

        <!-- 3. Terminal Log Kutusu -->
        <Border Grid.Row="2" Background="{DynamicResource TerminalBgBrush}" BorderBrush="{DynamicResource TerminalBorderBrush}" BorderThickness="1" CornerRadius="10" Padding="14">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="*" />
                </Grid.RowDefinitions>
                <Grid Grid.Row="0" Margin="0,0,0,8">
                    <TextBlock x:Name="LblConsoleTitle" Text="⚡ Canlı Konsol Günlüğü" FontSize="12" FontWeight="Bold" Foreground="#38BDF8"/>
                    <Button x:Name="BtnClearLog" Content="Temizle" HorizontalAlignment="Right" Padding="10,3" FontSize="11"/>
                </Grid>
                <TextBox x:Name="TxtConsole" Grid.Row="1" Background="{DynamicResource TerminalBgBrush}" Foreground="{DynamicResource TerminalTextBrush}" FontFamily="Cascadia Code, Consolas" FontSize="12" 
                         IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" BorderThickness="0" Padding="4"/>
            </Grid>
        </Border>

        <!-- 4. Footer (Sade ve Temiz) -->
        <TextBlock x:Name="LblFooter" Grid.Row="3" Text="PwX Studio v1.8.0 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
'@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
Set-WindowFitToWorkArea -Win $window -Center

# Logo ve ikon ata (Akıllı İkon Tespiti & Dahili İkon Desteği)
$pwxIconCandidate = $null
$iconPaths = @()


# ==================================================================
#  pwxe Derleme Motoru YÃ¶netimi (GÃ¼venli Arama ve Dahili GÃ¶mÃ¼lÃ¼ Motor)
# ==================================================================
$script:EmbeddedPwXEngineZipBase64 = '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'
$script:EmbeddedPwXEngineHash = '4afbdf2e45c8fc965b071b39f5c6f81f52b1907bef1093a8dec856131a107999'
function Deploy-EmbeddedIcon {
    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    try {
        $icoDest = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\ico\PwX-Studio.ico'
        if (Test-Path -LiteralPath $icoDest) { return $icoDest }
        $icoDir = Split-Path -Parent $icoDest
        if (-not (Test-Path -LiteralPath $icoDir)) { [System.IO.Directory]::CreateDirectory($icoDir) | Out-Null }

        $bytes = [System.Convert]::FromBase64String($script:EmbeddedPwXEngineZipBase64)
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
        $entry = $zip.GetEntry('ico/PwX-Studio.ico')
        if ($entry) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $icoDest, $true)
        }
        $zip.Dispose()
        $ms.Dispose()
        if (Test-Path -LiteralPath $icoDest) { return $icoDest }
    } catch {}
    return $null
}

# ============================================================
#  pwxe Motor Arama & Gomulu Zip Cikarma (v1.8.0 patch)
# ============================================================

function Deploy-EmbeddedPwXEngine {
    param([switch]$Force)
    try {
        $engineDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine'
        $scriptPath = Join-Path $engineDir 'scripts\PwX-Build.ps1'
        $hashFile = Join-Path $engineDir '.engine_hash'
        $existingHash = if (Test-Path -LiteralPath $hashFile) { (Get-Content -LiteralPath $hashFile -Raw -ErrorAction SilentlyContinue).Trim() } else { '' }

        if (-not $Force -and (Test-Path -LiteralPath $scriptPath) -and ($existingHash -eq $script:EmbeddedPwXEngineHash)) {
            return $scriptPath
        }

        if (-not (Test-Path -LiteralPath $engineDir)) {
            [System.IO.Directory]::CreateDirectory($engineDir) | Out-Null
        }

        $canonicalDir = [System.IO.Path]::GetFullPath($engineDir)
        if (-not $canonicalDir.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
            $canonicalDir += [System.IO.Path]::DirectorySeparatorChar
        }

        $bytes = [System.Convert]::FromBase64String($script:EmbeddedPwXEngineZipBase64)
        $ms = New-Object System.IO.MemoryStream (,$bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
        foreach ($entry in $zip.Entries) {
            if ([string]::IsNullOrEmpty($entry.Name)) { continue }
            $destPath = [System.IO.Path]::GetFullPath((Join-Path $engineDir $entry.FullName))
            if (-not $destPath.StartsWith($canonicalDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Warning "Zip Slip engellendi: $($entry.FullName)"
                continue
            }
            $parentDir = Split-Path -Parent $destPath
            if (-not (Test-Path -LiteralPath $parentDir)) {
                [System.IO.Directory]::CreateDirectory($parentDir) | Out-Null
            }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
        }
        $zip.Dispose()
        $ms.Dispose()

        [System.IO.File]::WriteAllText($hashFile, $script:EmbeddedPwXEngineHash, [System.Text.Encoding]::UTF8)

        if (Test-Path -LiteralPath $scriptPath) {
            $cfgDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio'
            if (-not (Test-Path -LiteralPath $cfgDir)) { [System.IO.Directory]::CreateDirectory($cfgDir) | Out-Null }
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'engine_path.txt'), $scriptPath, [System.Text.Encoding]::UTF8)
            return $scriptPath
        }
    } catch {
        Write-Warning "Dahili pwxe motoru cikarilamadi: $($_.Exception.Message)"
    }
    return $null
}

function Get-PwXEnginePath {
    param([switch]$ForceRedeploy)

    $cfgFile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine_path.txt'
    if (-not $ForceRedeploy -and (Test-Path -LiteralPath $cfgFile)) {
        try {
            $saved = (Get-Content -LiteralPath $cfgFile -Raw).Trim()
            if ($saved -and (Test-Path -LiteralPath $saved)) { return $saved }
        } catch {}
    }

    if ($PSScriptRoot) {
        $relCandidates = @(
            (Join-Path $PSScriptRoot 'pwxe\scripts\PwX-Build.ps1'),
            (Join-Path $PSScriptRoot '..\pwxe\scripts\PwX-Build.ps1')
        )
        foreach ($c in $relCandidates) {
            if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path }
        }
    }

    try {
        $pwxeMod = Get-Module -ListAvailable pwxe -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if ($pwxeMod) {
            $modCand = Join-Path $pwxeMod.ModuleBase 'scripts\PwX-Build.ps1'
            if (Test-Path -LiteralPath $modCand) { return $modCand }
        }
    } catch {}

    $appDataScript = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\scripts\PwX-Build.ps1'
    $hashFile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\.engine_hash'
    $hashMatches = if (Test-Path -LiteralPath $hashFile) { (Get-Content -LiteralPath $hashFile -Raw -ErrorAction SilentlyContinue).Trim() -eq $script:EmbeddedPwXEngineHash } else { $false }
    if (-not $ForceRedeploy -and $hashMatches -and (Test-Path -LiteralPath $appDataScript)) {
        return $appDataScript
    }

    return Deploy-EmbeddedPwXEngine -Force:$ForceRedeploy
}
if ($PSScriptRoot) { $iconPaths += (Join-Path $PSScriptRoot 'ico\PwX-Studio.ico') }
$iconPaths += '.\ico\PwX-Studio.ico'
$iconPaths += (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Github\PwX-Studio\ico\PwX-Studio.ico')
$iconPaths += (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Documents\Github\PwX-Studio\ico\PwX-Studio.ico')
$iconPaths += (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\ico\PwX-Studio.ico')
$iconPaths += (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\ico\PwX-Studio.ico')

foreach ($ip in $iconPaths) {
    if ($ip -and (Test-Path -LiteralPath $ip)) { $pwxIconCandidate = $ip; break }
}
if (-not $pwxIconCandidate) {
    $pwxIconCandidate = Deploy-EmbeddedIcon
}
if ($pwxIconCandidate -and (Test-Path -LiteralPath $pwxIconCandidate)) {
    try {
        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new((Resolve-Path $pwxIconCandidate).Path))
    } catch {}
}

# Element Haritası
$btnThemeToggle = $window.FindName('BtnThemeToggle')
$btnLangToggle       = $window.FindName('BtnLangToggle')
$lblSubtitle         = $window.FindName('LblSubtitle')
$lblFileConfigTitle  = $window.FindName('LblFileConfigTitle')
$lblSourcePs1        = $window.FindName('LblSourcePs1')
$lblTargetExe        = $window.FindName('LblTargetExe')
$lblAppIcon          = $window.FindName('LblAppIcon')
$lblIconFile         = $window.FindName('LblIconFile')
$lblIconHint         = $window.FindName('LblIconHint')
$lblPreview          = $window.FindName('LblPreview')
$lblAppInfo          = $window.FindName('LblAppInfo')
$lblAppTitle         = $window.FindName('LblAppTitle')
$lblVersion          = $window.FindName('LblVersion')
$lblCompany          = $window.FindName('LblCompany')
$lblTargetRuntime    = $window.FindName('LblTargetRuntime')
$lblAppType          = $window.FindName('LblAppType')
$lblEngineSelection  = $window.FindName('LblEngineSelection')
$lblBuildOptions     = $window.FindName('LblBuildOptions')
$lblConsoleTitle     = $window.FindName('LblConsoleTitle')
$btnClearLog         = $window.FindName('BtnClearLog')
$btnBuild            = $window.FindName('BtnBuild')
$btnOpenFolder       = $window.FindName('BtnOpenFolder')
$txtStatus           = $window.FindName('TxtStatus')
$txtPs1         = $window.FindName('TxtPs1')
$btnPs1Browse   = $window.FindName('BtnPs1Browse')
$txtOut         = $window.FindName('TxtOut')
$btnOutBrowse   = $window.FindName('BtnOutBrowse')
$txtLogo        = $window.FindName('TxtLogo')
$btnLogoBrowse  = $window.FindName('BtnLogoBrowse')
$btnWebSearch   = $window.FindName('BtnWebSearch')
$imgPreview     = $window.FindName('ImgPreview')
$txtNoIcon      = $window.FindName('TxtNoIcon')
$txtTitle       = $window.FindName('TxtTitle')
$txtVer         = $window.FindName('TxtVer')
$txtCompany     = $window.FindName('TxtCompany')

$rbTargetPS51   = $window.FindName('RbTargetPS51')
$rbTargetPS7    = $window.FindName('RbTargetPS7')
$chkSingleFile  = $window.FindName('ChkSingleFile')
$chkSmallSize   = $window.FindName('ChkSmallSize')
$chkEmbeddedEngine = $window.FindName('ChkEmbeddedEngine')
if ($chkEmbeddedEngine) {
    $chkEmbeddedEngine.Add_Checked({ Add-Log "Dahili pwxe motoru aktif (Taşınabilir / Offline mod)." })
    $chkEmbeddedEngine.Add_Unchecked({ Add-Log "Harici / Sistem pwxe motoru arama modu aktif." })
}

$rbConsole      = $window.FindName('RbConsole')
$lblFooter      = $window.FindName('LblFooter')
$rbGui          = $window.FindName('RbGui')

$chkAdmin       = $window.FindName('ChkAdmin')
$cmbExecutionLevel = $window.FindName('CmbExecutionLevel')
$cmbItemAsInvoker        = $window.FindName('CmbItemAsInvoker')
$cmbItemRequireAdmin     = $window.FindName('CmbItemRequireAdmin')
$cmbItemHighestAvailable = $window.FindName('CmbItemHighestAvailable')
$cmbItemThumbprint       = $window.FindName('CmbItemThumbprint')
$cmbItemFile             = $window.FindName('CmbItemFile')
$lblUacLevel       = $window.FindName('LblUacLevel')
$lblCodeSigningTitle = $window.FindName('LblCodeSigningTitle')
$chkSign           = $window.FindName('ChkSign')
$pnlSignSettings   = $window.FindName('PnlSignSettings')
$cmbCertSource     = $window.FindName('CmbCertSource')
$lblCertType       = $window.FindName('LblCertType')
$lblCertValue      = $window.FindName('LblCertValue')
$txtCertValue      = $window.FindName('TxtCertValue')
$btnBrowseCert     = $window.FindName('BtnBrowseCert')
$lblCertPassword   = $window.FindName('LblCertPassword')
$txtCertPassword   = $window.FindName('TxtCertPassword')
$lblTimestampServer = $window.FindName('LblTimestampServer')
$txtTimestampServer = $window.FindName('TxtTimestampServer')
$chkUtf8        = $window.FindName('ChkUtf8')
$chkX64         = $window.FindName('ChkX64')
$chkX86         = $window.FindName('ChkX86')
$chkUnicode     = $window.FindName('ChkUnicode')
$chkDpi         = $window.FindName('ChkDpi')
$chkConfig      = $window.FindName('ChkConfig')
$chkSupportOS   = $window.FindName('ChkSupportOS')
$chkLongPaths   = $window.FindName('ChkLongPaths')
$chkNoOutput    = $window.FindName('ChkNoOutput')
$chkEncryptPayload = $window.FindName('ChkEncryptPayload')
$chkBindToMachine  = $window.FindName('ChkBindToMachine')

$chkX64.Add_Checked({ if ($chkX86) { $chkX86.IsChecked = $false } })
$chkX86.Add_Checked({ if ($chkX64) { $chkX64.IsChecked = $false } })

$btnBuild       = $window.FindName('BtnBuild')
$btnOpenFolder  = $window.FindName('BtnOpenFolder')
$pbStatus       = $window.FindName('PbStatus')
$txtStatus      = $window.FindName('TxtStatus')
$txtConsole     = $window.FindName('TxtConsole')
$btnClearLog    = $window.FindName('BtnClearLog')

$script:LastGeneratedExe = ""
$script:currentTheme = 'Koyu'

# Tema Değiştirme Fonksiyonu
function Set-AppTheme([string]$theme) {
    $script:currentTheme = $theme
    $isDark = ($theme -eq 'Koyu')

    if ($isDark) {
        $window.Resources['BgBrush']             = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#202020")
        $window.Resources['CardBrush']           = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#262626")
        $window.Resources['BorderBrush']         = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#333333")
        $window.Resources['TextBrush']           = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
        $window.Resources['SubTextBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A0A0A0")
        $window.Resources['InputBgBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C1C")
        $window.Resources['InputBorderBrush']    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#383838")
        $window.Resources['BtnBgBrush']          = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#333333")
        $window.Resources['BtnBorderBrush']      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3D3D3D")
        $window.Resources['BtnTextBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
        $window.Resources['TerminalBgBrush']     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#141414")
        $window.Resources['TerminalBorderBrush'] = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#282828")
        $window.Resources['TerminalTextBrush']   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E0E0E0")
        if ($btnThemeToggle -and $btnThemeToggle.IsChecked) { $btnThemeToggle.IsChecked = $false }
    } else {
        $window.Resources['BgBrush']             = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F4F4F6")
        $window.Resources['CardBrush']           = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
        $window.Resources['BorderBrush']         = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E5E9")
        $window.Resources['TextBrush']           = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A1D20")
        $window.Resources['SubTextBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#606873")
        $window.Resources['InputBgBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8F9FA")
        $window.Resources['InputBorderBrush']    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D0D5DD")
        $window.Resources['BtnBgBrush']          = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F2F4F7")
        $window.Resources['BtnBorderBrush']      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D0D5DD")
        $window.Resources['BtnTextBrush']        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A1D20")
        $window.Resources['TerminalBgBrush']     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
        $window.Resources['TerminalBorderBrush'] = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D0D5DD")
        $window.Resources['TerminalTextBrush']   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A1D20")
        if ($btnThemeToggle -and -not $btnThemeToggle.IsChecked) { $btnThemeToggle.IsChecked = $true }
    }
}

$btnThemeToggle.Add_Click({
    if ($btnThemeToggle.IsChecked) {
        Set-AppTheme 'Açık'
    } else {
        Set-AppTheme 'Koyu'
    }
})

$script:currentLanguage = 'TR'

function Set-AppLanguage([string]$lang) {
    $script:currentLanguage = $lang
    if ($lang -eq 'EN') {
        if ($btnLangToggle) {
            $btnLangToggle.Content = [char]::ConvertFromUtf32(0x1F310) + " EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to TÃ¼rkÃ§e)"
        }
        if ($window) { $window.Title = "PwX Studio v1.8.0 - PowerShell Executable Builder" }
        if ($lblSubtitle) { $lblSubtitle.Text = "Convert PowerShell scripts (.ps1) into native Windows standalone executables (.exe) with zero dependencies." }
        if ($lblFileConfigTitle) { $lblFileConfigTitle.Text = "📁 File Configuration" }
        if ($lblSourcePs1) { $lblSourcePs1.Text = "Source PowerShell Script (.ps1):" }
        if ($txtPs1) { $txtPs1.ToolTip = "Select .ps1 script to convert or drag and drop file here." }
        if ($btnPs1Browse) { $btnPs1Browse.Content = "📁 Browse..." }
        if ($lblTargetExe) { $lblTargetExe.Text = "Target Executable (.exe):" }
        if ($txtOut) { $txtOut.ToolTip = "Specify output location for the generated .exe file." }
        if ($btnOutBrowse) { $btnOutBrowse.Content = "💾 Save As..." }
        if ($lblAppIcon) { $lblAppIcon.Text = "🎨 Application Logo & Icon" }
        if ($lblIconFile) { $lblIconFile.Text = "Image File (PNG, JPG, BMP, ICO):" }
        if ($txtLogo) { $txtLogo.ToolTip = "Select image to embed as application icon." }
        if ($btnLogoBrowse) { $btnLogoBrowse.Content = "🖼️ Browse File" }
        if ($btnWebSearch) { $btnWebSearch.Content = "🌐 Search Web Icon" }
        if ($lblIconHint) { $lblIconHint.Text = "Selected PNG/JPG images are automatically converted to 256x256 ICO format during build." }
        if ($txtNoIcon) { $txtNoIcon.Text = "NO ICON" }
        if ($lblPreview) { $lblPreview.Text = "Preview" }
        if ($lblAppInfo) { $lblAppInfo.Text = "ℹ️ Application Info & Metadata" }
        if ($lblAppTitle) { $lblAppTitle.Text = "Application Name / Title:" }
        if ($lblVersion) { $lblVersion.Text = "Version (x.x.x.x):" }
        if ($lblCompany) { $lblCompany.Text = "Company / Publisher:" }
        if ($lblTargetRuntime) { $lblTargetRuntime.Text = "⚙️ Target Runtime" }
        if ($rbTargetPS51) { 
            $rbTargetPS51.Content = "PowerShell 5.1 (Built-in csc.exe)" 
            $rbTargetPS51.ToolTip = "Uses built-in Windows csc.exe compiler without external dependencies."
        }
        if ($rbTargetPS7) { 
            $rbTargetPS7.Content = "PowerShell 7.4+ (.NET 8 SDK)" 
            $rbTargetPS7.ToolTip = "Uses modern PowerShell 7 core engine with .NET 8 SDK."
        }
        if ($chkSingleFile) { $chkSingleFile.Content = "Single-File (.exe)" }
        if ($chkSmallSize) { 
            $chkSmallSize.Content = "Small size (requires .NET 8 Runtime on target)" 
            $chkSmallSize.ToolTip = "FrameworkDependent: .NET runtime is not embedded into EXE. Requires .NET 8 Runtime installed on target machine."
        }
        if ($lblAppType) { $lblAppType.Text = "🖥️ Application Type" }
        if ($rbConsole) { $rbConsole.Content = "Console Application (CLI)" }
        if ($rbGui) { $rbGui.Content = "Windowed / GUI Application (Hidden Console)" }
        if ($lblEngineSelection) { $lblEngineSelection.Text = "🚀 Build Engine Selection" }
        if ($chkEmbeddedEngine) { 
            $chkEmbeddedEngine.Content = "Embedded pwxe Engine (Portable / Offline)" 
            $chkEmbeddedEngine.ToolTip = "Runs the build engine directly from the embedded package without external dependencies."
        }
        if ($lblBuildOptions) { $lblBuildOptions.Text = "🛠️ Build & Runtime Options" }
                if ($lblUacLevel) { 
            $lblUacLevel.Text = "🛡️ UAC Execution Level:" 
            $lblUacLevel.ToolTip = "Sets the Windows UAC elevation and manifest permission level."
        }
        if ($cmbExecutionLevel) {
            $cmbExecutionLevel.ToolTip = "Sets the Windows UAC elevation and manifest permission level."
        }
        if ($cmbItemAsInvoker) {
            $cmbItemAsInvoker.Content = "asInvoker (Standard User)"
            $cmbItemAsInvoker.ToolTip = "Application launches with caller's standard permissions without prompting for elevation."
        }
        if ($cmbItemRequireAdmin) {
            $cmbItemRequireAdmin.Content = "requireAdministrator (Administrator)"
            $cmbItemRequireAdmin.ToolTip = "Application always requests Windows UAC elevation and runs with full administrative rights."
        }
        if ($cmbItemHighestAvailable) {
            $cmbItemHighestAvailable.Content = "highestAvailable (Highest Available)"
            $cmbItemHighestAvailable.ToolTip = "Runs with elevated rights if the user is an admin, or standard rights otherwise."
        }
        if ($cmbItemThumbprint) {
            $cmbItemThumbprint.Content = "Thumbprint (Windows Certificate Store)"
            $cmbItemThumbprint.ToolTip = "Uses installed code signing certificate from Windows Certificate Store (CurrentUser\My)."
        }
        if ($cmbItemFile) {
            $cmbItemFile.Content = "PFX / P12 File"
            $cmbItemFile.ToolTip = "Uses .pfx or .p12 certificate file located on disk."
        }
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v1.8.0)" }
        if ($chkSign) { $chkSign.Content = "Signing Enabled" }
        if ($lblCertType) { $lblCertType.Text = "Certificate Source:" }
        if ($lblCertPassword) { $lblCertPassword.Text = "Certificate Password (for PFX):" }
        if ($lblTimestampServer) { $lblTimestampServer.Text = "RFC 3161 Timestamp Server:" }
        if ($chkAdmin) { 
            $chkAdmin.Content = "Administrator Rights (UAC)" 
            $chkAdmin.ToolTip = "Requests Windows UAC elevation prompt upon launch."
        }
        if ($chkUtf8) { 
            $chkUtf8.Content = "Console UTF-8" 
            $chkUtf8.ToolTip = "Forces console output encoding to UTF-8 for international characters."
        }
        if ($chkX64) { 
            $chkX64.Content = "64-bit (x64)" 
            $chkX64.ToolTip = "Target 64-bit processor architecture."
        }
        if ($chkX86) { 
            $chkX86.Content = "32-bit (x86)" 
            $chkX86.ToolTip = "Target 32-bit (x86) legacy architecture."
        }
        if ($chkUnicode) { 
            $chkUnicode.Content = "Unicode Console" 
            $chkUnicode.ToolTip = "Provides extended wide-character unicode support."
        }
        if ($chkDpi) { 
            $chkDpi.Content = "DPI Awareness" 
            $chkDpi.ToolTip = "Ensures crisp rendering on High-DPI displays."
        }
        if ($chkConfig) { 
            $chkConfig.Content = "Generate EXE.config" 
            $chkConfig.ToolTip = "Generates companion .exe.config for DPI and runtime policies."
        }
        if ($chkSupportOS) { 
            $chkSupportOS.Content = "Windows OS Support" 
            $chkSupportOS.ToolTip = "Embeds compatibility manifest for Windows 10/11."
        }
        if ($chkLongPaths) { 
            $chkLongPaths.Content = "Long Paths Support" 
            $chkLongPaths.ToolTip = "Allows file paths longer than 260 characters (MAX_PATH)."
        }
        if ($chkNoOutput) { 
            $chkNoOutput.Content = "Suppress Console Output" 
            $chkNoOutput.ToolTip = "Silences standard console output."
        }
        if ($chkEncryptPayload) {
            $chkEncryptPayload.Content = "Encrypt Payload (AES-256)"
            $chkEncryptPayload.ToolTip = "Encrypts embedded script using AES-256-CBC and HMAC-SHA256, eliminating plaintext exposure."
        }
        if ($chkBindToMachine) {
            $chkBindToMachine.Content = "Bind to Machine (DPAPI)"
            $chkBindToMachine.ToolTip = "Locks encryption key to the current machine and user context via Windows DPAPI."
        }
        if ($btnBuild) { $btnBuild.Content = "🚀 BUILD EXE" }
        if ($btnOpenFolder) { $btnOpenFolder.Content = "📂 Open Folder" }
        if ($txtStatus) { 
            if ($txtStatus.Text -eq "Hazır. Kaynak betiği belirleyip 'EXE OLUŞTUR' butonuna basınız.") {
                $txtStatus.Text = "Ready. Select source script and click 'BUILD EXE'."
            }
        }
        if ($lblConsoleTitle) { $lblConsoleTitle.Text = "⚡ Live Console Log" }
        if ($btnClearLog) { $btnClearLog.Content = "Clear" }
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.8.0 • PowerShell Executable Builder" }
    } else {
        if ($btnLangToggle) {
            $btnLangToggle.Content = [char]::ConvertFromUtf32(0x1F310) + " EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to TÃ¼rkÃ§e)"
        }
        if ($window) { $window.Title = "PwX Studio v1.8.0 - PowerShell Executable Builder" }
        if ($lblSubtitle) { $lblSubtitle.Text = "PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." }
        if ($lblFileConfigTitle) { $lblFileConfigTitle.Text = "📁 Dosya Yapılandırması" }
        if ($lblSourcePs1) { $lblSourcePs1.Text = "Kaynak PowerShell Betiği (.ps1):" }
        if ($txtPs1) { $txtPs1.ToolTip = "Dönüştürülecek .ps1 betiğini seçin veya dosyayı buraya sürükleyin." }
        if ($btnPs1Browse) { $btnPs1Browse.Content = "📁 Gözat..." }
        if ($lblTargetExe) { $lblTargetExe.Text = "Hedef Yürütülebilir Dosya (.exe):" }
        if ($txtOut) { $txtOut.ToolTip = "Oluşturulacak .exe dosyasının kaydedileceği konumu belirleyin." }
        if ($btnOutBrowse) { $btnOutBrowse.Content = "💾 Farklı Kaydet..." }
        if ($lblAppIcon) { $lblAppIcon.Text = "🎨 Uygulama Logosu &amp; Simgesi" }
        if ($lblIconFile) { $lblIconFile.Text = "Görsel Dosyası (PNG, JPG, BMP, ICO):" }
        if ($txtLogo) { $txtLogo.ToolTip = "Uygulama simgesi olarak gömülecek görseli seçin." }
        if ($btnLogoBrowse) { $btnLogoBrowse.Content = "🖼️ Dosyadan Seç" }
        if ($btnWebSearch) { $btnWebSearch.Content = "🌐 Web'den İkon Ara" }
        if ($lblIconHint) { $lblIconHint.Text = "Seçilen PNG/JPG görseller derleme anında otomatik olarak 256x256 ICO formatına dönüştürülür." }
        if ($txtNoIcon) { $txtNoIcon.Text = "SİMGE YOK" }
        if ($lblPreview) { $lblPreview.Text = "Önizleme" }
        if ($lblAppInfo) { $lblAppInfo.Text = "ℹ️ Uygulama Bilgileri &amp; Meta Veriler" }
        if ($lblAppTitle) { $lblAppTitle.Text = "Uygulama Adı / Başlık:" }
        if ($lblVersion) { $lblVersion.Text = "Sürüm (x.x.x.x):" }
        if ($lblCompany) { $lblCompany.Text = "Şirket / Yayıncı:" }
        if ($lblTargetRuntime) { $lblTargetRuntime.Text = "⚙️ Hedef Çalışma Zamanı" }
        if ($rbTargetPS51) { 
            $rbTargetPS51.Content = "PowerShell 5.1 (Dahili csc.exe)" 
            $rbTargetPS51.ToolTip = "Windows ile dahili gelen csc.exe derleyicisini kullanır."
        }
        if ($rbTargetPS7) { 
            $rbTargetPS7.Content = "PowerShell 7.4+ (.NET 8 SDK)" 
            $rbTargetPS7.ToolTip = "Modern PowerShell 7 ve .NET 8 SDK altyapısını kullanır."
        }
        if ($chkSingleFile) { $chkSingleFile.Content = "Tek Dosya (Single-File)" }
        if ($chkSmallSize) { 
            $chkSmallSize.Content = "Küçük boyut (hedefte .NET 8 Runtime gerekir)" 
            $chkSmallSize.ToolTip = "FrameworkDependent: .NET çalışma zamanı EXE'ye eklenmez, çıktı çok daha küçük olur. Çalıştıracak bilgisayarda .NET 8 Runtime (GUI için Windows Desktop Runtime 8) kurulu olmalıdır. pwsh gerekmez."
        }
        if ($lblAppType) { $lblAppType.Text = "🖥️ Uygulama Türü" }
        if ($rbConsole) { $rbConsole.Content = "Konsol Uygulaması (CLI)" }
        if ($rbGui) { $rbGui.Content = "Pencereli / GUI Uygulama (Konsol Gizli)" }
        if ($lblEngineSelection) { $lblEngineSelection.Text = "🚀 Derleme Motoru Seçimi" }
        if ($chkEmbeddedEngine) { 
            $chkEmbeddedEngine.Content = "Dahili pwxe Motoru (Taşınabilir / Offline)" 
            $chkEmbeddedEngine.ToolTip = "pwxe motorunu dış klasörlere ihtiyaç duymadan doğrudan uygulama içerisindeki gömülü motordan çalıştırır. Uygulama masaüstüne veya başka bilgisayara taşındığında sorunsuz çalışmasını sağlar."
        }
        if ($lblBuildOptions) { $lblBuildOptions.Text = "🛠️ Derleme &amp; Çalışma Seçenekleri" }
                if ($lblUacLevel) { $lblUacLevel.Text = "🛡️ UAC Execution Level:" }
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v1.8.0)" }
        if ($chkSign) { $chkSign.Content = "Signing Enabled" }
        if ($lblCertType) { $lblCertType.Text = "Certificate Source:" }
        if ($lblCertPassword) { $lblCertPassword.Text = "Certificate Password (for PFX):" }
        if ($lblTimestampServer) { $lblTimestampServer.Text = "RFC 3161 Timestamp Server:" }
                if ($lblUacLevel) { 
            $lblUacLevel.Text = "🛡️ UAC Yetki Düzeyi:" 
            $lblUacLevel.ToolTip = "Windows UAC (Kullanıcı Hesabı Denetimi) çalıştırma ve bildirim düzeyini ayarlar."
        }
        if ($cmbExecutionLevel) {
            $cmbExecutionLevel.ToolTip = "Windows UAC (Kullanıcı Hesabı Denetimi) çalıştırma ve bildirim düzeyini ayarlar."
        }
        if ($cmbItemAsInvoker) {
            $cmbItemAsInvoker.Content = "asInvoker (Standart)"
            $cmbItemAsInvoker.ToolTip = "Uygulama çağıran kullanıcının standart yetkileriyle başlatılır. Ekstra yönetici onayı istemez."
        }
        if ($cmbItemRequireAdmin) {
            $cmbItemRequireAdmin.Content = "requireAdministrator (Yönetici)"
            $cmbItemRequireAdmin.ToolTip = "Uygulama her açılışta Windows UAC yönetici onayı ister ve tam yönetici ayrıcalıklarıyla çalışır."
        }
        if ($cmbItemHighestAvailable) {
            $cmbItemHighestAvailable.Content = "highestAvailable (En Yüksek)"
            $cmbItemHighestAvailable.ToolTip = "Kullanıcı yöneticiyse yönetici onayı ister; standart kullanıcıysa ek onay istemeden çalışır."
        }
        if ($cmbItemThumbprint) {
            $cmbItemThumbprint.Content = "Parmak İzi (Thumbprint - Windows Deposu)"
            $cmbItemThumbprint.ToolTip = "Windows Sertifika Deposundaki (CurrentUser\My) yüklü kod imzalama sertifikasını kullanır."
        }
        if ($cmbItemFile) {
            $cmbItemFile.Content = "PFX / P12 Dosyası"
            $cmbItemFile.ToolTip = "Diskte bulunan .pfx veya .p12 sertifika dosyasını kullanır."
        }
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Dijital Kod İmzalama (v1.8.0)" }
        if ($chkSign) { $chkSign.Content = "İmzalama Etkin" }
        if ($lblCertType) { $lblCertType.Text = "Sertifika Kaynağı:" }
        if ($lblCertPassword) { $lblCertPassword.Text = "Sertifika Parolası (PFX için):" }
        if ($lblTimestampServer) { $lblTimestampServer.Text = "RFC 3161 Zaman Damgası Sunucusu:" }
        if ($chkAdmin) { 
            $chkAdmin.Content = "Yönetici Yetkisi (UAC)" 
            $chkAdmin.ToolTip = "Windows UAC yönetici onayı ister."
        }
        if ($chkUtf8) { 
            $chkUtf8.Content = "Konsol UTF-8" 
            $chkUtf8.ToolTip = "Türkçe karakterlerin doğru gösterilmesini sağlar."
        }
        if ($chkX64) { 
            $chkX64.Content = "64-bit (x64)" 
            $chkX64.ToolTip = "64-bit mimari için derler."
        }
        if ($chkX86) { 
            $chkX86.Content = "32-bit (x86)" 
            $chkX86.ToolTip = "32-bit mimari uyumluluğu sağlar."
        }
        if ($chkUnicode) { 
            $chkUnicode.Content = "Unicode Konsol" 
            $chkUnicode.ToolTip = "Genişletilmiş karakter desteği sağlar."
        }
        if ($chkDpi) { 
            $chkDpi.Content = "DPI Farkındalığı" 
            $chkDpi.ToolTip = "Yüksek çözünürlüklü ekranlarda net görünüm sağlar."
        }
        if ($chkConfig) { 
            $chkConfig.Content = "EXE.config Oluştur" 
            $chkConfig.ToolTip = "DPI ve runtime ayarları için .config dosyası üretir."
        }
        if ($chkSupportOS) { 
            $chkSupportOS.Content = "Windows Sürüm Bilgisi" 
            $chkSupportOS.ToolTip = "Modern Windows sürümleriyle uyumluluk bildirir."
        }
        if ($chkLongPaths) { 
            $chkLongPaths.Content = "Uzun Dosya Yolları" 
            $chkLongPaths.ToolTip = "260 karakterden uzun dosya yollarına izin verir."
        }
        if ($chkNoOutput) { 
            $chkNoOutput.Content = "Çıktıyı Bastır" 
            $chkNoOutput.ToolTip = "Standart konsol çıktısını bastırır."
        }
        if ($chkEncryptPayload) {
            $chkEncryptPayload.Content = "Betiği Şifrele (AES-256)"
            $chkEncryptPayload.ToolTip = "Gömülü betiği AES-256-CBC ve HMAC-SHA256 ile şifreler, düz metin sızıntısını önler."
        }
        if ($chkBindToMachine) {
            $chkBindToMachine.Content = "Makineye Kilitle (DPAPI)"
            $chkBindToMachine.ToolTip = "Şifreleme anahtarını Windows DPAPI ile bu makine ve kullanıcıya kilitler."
        }
        if ($btnBuild) { $btnBuild.Content = "🚀 EXE OLUŞTUR" }
        if ($btnOpenFolder) { $btnOpenFolder.Content = "📂 Klasörü Aç" }
        if ($txtStatus) { 
            if ($txtStatus.Text -eq "Ready. Select source script and click 'BUILD EXE'.") {
                $txtStatus.Text = "Hazır. Kaynak betiği belirleyip 'EXE OLUŞTUR' butonuna basınız."
            }
        }
        if ($lblConsoleTitle) { $lblConsoleTitle.Text = "⚡ Canlı Konsol Günlüğü" }
        if ($btnClearLog) { $btnClearLog.Content = "Temizle" }
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.8.0 • PowerShell Executable Builder" }
    }
    try { Update-SignUI } catch { }
}

if ($btnLangToggle) {
    $btnLangToggle.Add_Click({
        if ($script:currentLanguage -eq 'TR') {
            Set-AppLanguage 'EN'
            Add-Log "Language switched to English (🇬🇧 EN)."
        } else {
            Set-AppLanguage 'TR'
            Add-Log "Dil Türkçe olarak ayarlandı (🇹🇷 TR)."
        }
    })
}

function Add-Log([string]$msg, [string]$level = 'Info') {
    $time = (Get-Date).ToString("HH:mm:ss")
    $prefix = switch ($level) {
        'Error'   { "[$time] [HATA] " }
        'Success' { "[$time] [BAŞARILI] " }
        'Warning' { "[$time] [UYARI] " }
        default   { "[$time] " }
    }
    if ($window.Dispatcher.CheckAccess()) {
        $txtConsole.AppendText("$prefix$msg`r`n")
        $txtConsole.ScrollToEnd()
    } else {
        $window.Dispatcher.Invoke([Action]{
            $txtConsole.AppendText("$prefix$msg`r`n")
            $txtConsole.ScrollToEnd()
        })
    }
}
Set-Alias Append-Log Add-Log -Scope Script



function Update-PreviewImage([string]$path) {
    if ($path -and (Test-Path -LiteralPath $path)) {
        $bmp = Get-PreviewBitmapImage $path
        if ($bmp) {
            $imgPreview.Source = $bmp
            $txtNoIcon.Visibility = [System.Windows.Visibility]::Collapsed
            return
        }
    }
    $imgPreview.Source = $null
    $txtNoIcon.Visibility = [System.Windows.Visibility]::Visible
}

$script:outExeManuallyChanged = $false

function Set-Ps1File([string]$path) {
    $txtPs1.Text = $path
    $base = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $dir = [System.IO.Path]::GetDirectoryName($path)
    if (-not $dir) { $dir = (Get-Location).Path }

    # Yeni dosya seçildiğinde / değiştirildiğinde Uygulama Adı başlığını otomatik güncelle
    $txtTitle.Text = $base

    # Hedef EXE adını Uygulama Adı'na göre eşitle
    $safeTitle = $base -replace '[\/\\:\*\?"<>\|]', '_'
    $txtOut.Text = Join-Path $dir ($safeTitle + '.exe')
    $script:outExeManuallyChanged = $false

    Add-Log "Kaynak betik yüklendi: $path"
}

# Uygulama Adı / Başlık alanına yazıldığında hedef EXE adını eşzamanlı olarak güncelle
$txtTitle.Add_TextChanged({
    $title = $txtTitle.Text.Trim()
    if ($title -and -not $script:outExeManuallyChanged) {
        $safeTitle = $title -replace '[\/\\:\*\?"<>\|]', '_'
        $currentOut = $txtOut.Text.Trim()
        $targetDir = $null
        if ($currentOut) {
            try { $targetDir = [System.IO.Path]::GetDirectoryName($currentOut) } catch {}
        }
        if (-not $targetDir -and $txtPs1.Text.Trim()) {
            try { $targetDir = [System.IO.Path]::GetDirectoryName($txtPs1.Text.Trim()) } catch {}
        }
        if (-not $targetDir) {
            $targetDir = (Get-Location).Path
        }
        $txtOut.Text = Join-Path $targetDir ($safeTitle + '.exe')
    }
})

# PS7 seçildiğinde Tek Dosya onay kutusunu etkinleştir
$rbTargetPS7.Add_Checked({
    $chkSingleFile.IsEnabled = $true
    $chkSmallSize.IsEnabled = $true
})
$rbTargetPS51.Add_Checked({
    $chkSingleFile.IsEnabled = $false
    $chkSingleFile.IsChecked = $false
    $chkSmallSize.IsEnabled = $false
    $chkSmallSize.IsChecked = $false
})

# Günlük Temizleme
$btnClearLog.Add_Click({
    $txtConsole.Text = ""
})

# PS1 Gözat
$btnPs1Browse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PowerShell Scriptleri (*.ps1)|*.ps1|Tüm Dosyalar (*.*)|*.*"
    $ofd.Title = "Kaynak PowerShell Betiğini Seçin"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-Ps1File $ofd.FileName
    }
})

# Çıktı EXE Farklı Kaydet
$btnOutBrowse.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Yürütülebilir Uygulama (*.exe)|*.exe|Tüm Dosyalar (*.*)|*.*"
    $sfd.Title = "Hedef EXE Dosyasının Kaydedileceği Konumu Belirleyin"
    if ($txtOut.Text.Trim()) {
        $sfd.FileName = [System.IO.Path]::GetFileName($txtOut.Text.Trim())
        $parent = [System.IO.Path]::GetDirectoryName($txtOut.Text.Trim())
        if ($parent -and (Test-Path -LiteralPath $parent)) { $sfd.InitialDirectory = $parent }
    }
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOut.Text = $sfd.FileName
        $script:outExeManuallyChanged = $true
    }
})

# Logo Gözat
$btnLogoBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Görsel Dosyaları (*.png;*.jpg;*.jpeg;*.bmp;*.ico)|*.png;*.jpg;*.jpeg;*.bmp;*.ico|Tüm Dosyalar (*.*)|*.*"
    $ofd.Title = "Uygulama İkonunu veya Görselini Seçin"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtLogo.Text = $ofd.FileName
        Update-PreviewImage $ofd.FileName
    }
})

$txtLogo.Add_TextChanged({
    Update-PreviewImage $txtLogo.Text.Trim()
})

# Sürükle ve Bırak Desteği
$dragHandler = {
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $e.Effects = [System.Windows.DragDropEffects]::Copy
        $e.Handled = $true
    }
}
$dropHandler = {
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        if ($files -and $files.Count -gt 0) {
            $file = $files[0]
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($ext -eq '.ps1') {
                Set-Ps1File $file
            } elseif ($ext -in @('.png','.jpg','.jpeg','.bmp','.ico')) {
                $txtLogo.Text = $file
                Update-PreviewImage $file
                Append-Log "Görsel bırakıldı ve simge olarak atandı: $file"
            }
        }
    }
}
$window.Add_PreviewDragOver($dragHandler)
$window.Add_Drop($dropHandler)
$txtPs1.Add_PreviewDragOver($dragHandler)
$txtPs1.Add_Drop($dropHandler)

# Klasörü Aç Butonu
$btnOpenFolder.Add_Click({
    if ($script:LastGeneratedExe -and (Test-Path -LiteralPath $script:LastGeneratedExe)) {
        [System.Diagnostics.Process]::Start('explorer.exe', "/select,`"$script:LastGeneratedExe`"") | Out-Null
    } elseif ($txtOut.Text.Trim()) {
        $dir = [System.IO.Path]::GetDirectoryName($txtOut.Text.Trim())
        if ($dir -and (Test-Path -LiteralPath $dir)) {
            [System.Diagnostics.Process]::Start('explorer.exe', $dir) | Out-Null
        }
    }
})

# ------------------------------------------------------------------
#  UAC & Authenticode Kod İmzalama Olay Yöneticileri (v1.8.0)
# ------------------------------------------------------------------

function Update-SignUI {
    $isThumb = $true
    if ($cmbCertSource -and $cmbCertSource.SelectedItem) {
        if ([string]$cmbCertSource.SelectedItem.Tag -eq 'File') { $isThumb = $false }
    }

    $isEn = ($btnLangToggle -and $btnLangToggle.Content -match 'TR')

    if ($isThumb) {
        if ($lblCertValue) {
            $lblCertValue.Text = if ($isEn) { "Certificate Thumbprint:" } else { "Sertifika Parmak İzi (Thumbprint):" }
        }
        if ($btnBrowseCert) {
            $btnBrowseCert.Visibility = [System.Windows.Visibility]::Visible
            $btnBrowseCert.Content = if ($isEn) { "Select Cert..." } else { "Sertifika Seç..." }
            $btnBrowseCert.ToolTip = if ($isEn) { "Browse and select certificate from Windows Certificate Store" } else { "Windows Sertifika Deposundan (CurrentUser\My) kod imzalama sertifikası seçin." }
        }
        if ($txtCertPassword) {
            $txtCertPassword.IsEnabled = $false
            $txtCertPassword.ToolTip = if ($isEn) { "Password not needed for Windows Store certificate" } else { "Windows sertifika deposundaki sertifikalar için parola gerekmez." }
        }
        if ($lblCertPassword) {
            $lblCertPassword.Opacity = 0.5
        }
    } else {
        if ($lblCertValue) {
            $lblCertValue.Text = if ($isEn) { "PFX / P12 File Path:" } else { "PFX / P12 Dosya Yolu:" }
        }
        if ($btnBrowseCert) {
            $btnBrowseCert.Visibility = [System.Windows.Visibility]::Visible
            $btnBrowseCert.Content = if ($isEn) { "Browse..." } else { "Gözat..." }
            $btnBrowseCert.ToolTip = if ($isEn) { "Browse disk for .pfx or .p12 certificate file" } else { "Diskten .pfx veya .p12 sertifika dosyası seçin." }
        }
        if ($txtCertPassword) {
            $txtCertPassword.IsEnabled = $true
            $txtCertPassword.ToolTip = if ($isEn) { "Enter PFX password if protected" } else { "PFX sertifikanız şifreliyse giriniz." }
        }
        if ($lblCertPassword) {
            $lblCertPassword.Opacity = 1.0
        }
    }

    if ($pnlSignSettings) {
        if ($chkSign -and -not $chkSign.IsChecked) {
            $pnlSignSettings.Opacity = 0.65
        } else {
            $pnlSignSettings.Opacity = 1.0
        }
    }
}

if ($chkSign) {
    $chkSign.Add_Checked({ Update-SignUI })
    $chkSign.Add_Unchecked({ Update-SignUI })
}

if ($cmbCertSource) {
    $cmbCertSource.Add_SelectionChanged({ Update-SignUI })
}

if ($txtCertValue) {
    $txtCertValue.Add_TextChanged({
        if ($txtCertValue.Text.Trim() -and $chkSign -and -not $chkSign.IsChecked) {
            $chkSign.IsChecked = $true
            Update-SignUI
        }
    })
}

if ($btnBrowseCert) {
    $btnBrowseCert.Add_Click({
        if ($chkSign -and -not $chkSign.IsChecked) {
            $chkSign.IsChecked = $true
            Update-SignUI
        }

        $isThumb = $true
        if ($cmbCertSource -and $cmbCertSource.SelectedItem) {
            if ([string]$cmbCertSource.SelectedItem.Tag -eq 'File') { $isThumb = $false }
        }

        if ($isThumb) {
            try {
                Add-Type -AssemblyName System.Security
                $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::My, [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
                $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
                $certs = $store.Certificates
                if ($certs.Count -eq 0) {
                    $lmStore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::My, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
                    $lmStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
                    $certs = $lmStore.Certificates
                    $lmStore.Close()
                }

                if ($certs -and $certs.Count -gt 0) {
                    $title = if ($btnLangToggle -and $btnLangToggle.Content -match 'TR') { "Select Code Signing Certificate" } else { "Kod İmzalama Sertifikası Seçin" }
                    $msg = if ($btnLangToggle -and $btnLangToggle.Content -match 'TR') { "Select the certificate to use for signing:" } else { "İmzalama için kullanılacak dijital sertifikayı seçiniz:" }
                    $selected = [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::SelectFromCollection(
                        $certs,
                        $title,
                        $msg,
                        [System.Security.Cryptography.X509Certificates.X509SelectionFlag]::SingleSelection,
                        (New-Object System.IntPtr -ArgumentList 0)
                    )
                    if ($selected -and $selected.Count -gt 0) {
                        $txtCertValue.Text = $selected[0].Thumbprint
                        Add-Log "Sertifika seçildi: $($selected[0].Subject) (Thumbprint: $($selected[0].Thumbprint))"
                    }
                } else {
                    $noCertMsg = if ($btnLangToggle -and $btnLangToggle.Content -match 'TR') {
                        "No certificates found in Windows Certificate Store (CurrentUser\My).`nYou can also use 'PFX / P12 File' option to select a certificate file from disk."
                    } else {
                        "Windows Sertifika Deposunda (CurrentUser\My) yüklü sertifika bulunamadı.`nAlternatif olarak 'PFX / P12 Dosyası' seçeneği ile diskten sertifika yükleyebilirsiniz."
                    }
                    $noCertTitle = if ($btnLangToggle -and $btnLangToggle.Content -match 'TR') { "Certificate Not Found" } else { "Sertifika Bulunamadı" }
                    [System.Windows.MessageBox]::Show($noCertMsg, $noCertTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
                $store.Close()
            } catch {
                Add-Log "[UYARI] Sertifika deposu açılamadı: $($_.Exception.Message)"
            }
        } else {
            $ofd = New-Object Microsoft.Win32.OpenFileDialog
            $ofd.Title = if ($btnLangToggle -and $btnLangToggle.Content -match 'TR') { "Select PFX / P12 Certificate File" } else { "PFX / P12 Sertifika Dosyası Seçin" }
            $ofd.Filter = "Sertifika Dosyaları (*.pfx;*.p12)|*.pfx;*.p12|Tüm Dosyalar (*.*)|*.*"
            if ($txtCertValue.Text -and (Test-Path -LiteralPath $txtCertValue.Text)) {
                $ofd.InitialDirectory = [System.IO.Path]::GetDirectoryName($txtCertValue.Text)
            }
            if ($ofd.ShowDialog($window) -eq $true) {
                $txtCertValue.Text = $ofd.FileName
                Add-Log "PFX sertifika dosyası seçildi: $($ofd.FileName)"
            }
        }
    })
}

# UAC Checkbox ve ExecutionLevel ComboBox senkronizasyonu
if ($chkAdmin -and $cmbExecutionLevel) {
    $chkAdmin.Add_Checked({
        if ($cmbExecutionLevel.SelectedIndex -eq 0) {
            $cmbExecutionLevel.SelectedIndex = 1
        }
    })
    $chkAdmin.Add_Unchecked({
        if ($cmbExecutionLevel.SelectedIndex -eq 1) {
            $cmbExecutionLevel.SelectedIndex = 0
        }
    })
    $cmbExecutionLevel.Add_SelectionChanged({
        if ($cmbExecutionLevel.SelectedItem) {
            $tag = [string]$cmbExecutionLevel.SelectedItem.Tag
            if ($tag -eq 'requireAdministrator') {
                $chkAdmin.IsChecked = $true
            } elseif ($tag -eq 'asInvoker') {
                $chkAdmin.IsChecked = $false
            }
        }
    })
}

# Başlangıç durumu
Update-SignUI

# ------------------------------------------------------------------
#  Web İkon Arama Modülü (WPF Modal Dialog & Renk Kartelası)
# ------------------------------------------------------------------

function Open-FluentIconDialog {
    $isDark = ($script:currentTheme -eq 'Koyu')
    $dlgBg = if ($isDark) { "#202020" } else { "#F4F4F6" }
    $dlgCard = if ($isDark) { "#262626" } else { "#FFFFFF" }
    $dlgBorder = if ($isDark) { "#333333" } else { "#E2E5E9" }
    $dlgText = if ($isDark) { "#FFFFFF" } else { "#1A1D20" }
    $dlgSubText = if ($isDark) { "#CCCCCC" } else { "#606873" }
    $dlgInputBg = if ($isDark) { "#1C1C1C" } else { "#F8F9FA" }
    $dlgInputBorder = if ($isDark) { "#383838" } else { "#D0D5DD" }
    $dlgBtnBg = if ($isDark) { "#333333" } else { "#F2F4F7" }
    $dlgBtnBorder = if ($isDark) { "#3D3D3D" } else { "#D0D5DD" }
    $dlgBtnText = if ($isDark) { "#FFFFFF" } else { "#1A1D20" }
    $dlgStatusBg = if ($isDark) { "#1A1A1A" } else { "#EBF5FB" }
    $dlgStatusText = if ($isDark) { "#38BDF8" } else { "#0078D4" }

    [xml]$dlgXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Web'den İkon Ara - PwX Studio"
        Height="720" Width="960" MinHeight="620" MinWidth="860"
        WindowStartupLocation="CenterOwner"
        Background="$dlgBg" Foreground="$dlgText" FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="$dlgBtnBg" />
            <Setter Property="Foreground" Value="$dlgBtnText" />
            <Setter Property="Padding" Value="14,8" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="BorderBrush" Value="$dlgBtnBorder" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#0078D4"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#0078D4" />
            <Setter Property="BorderBrush" Value="#005A9E" />
            <Setter Property="Foreground" Value="#FFFFFF" />
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="$dlgInputBg" />
            <Setter Property="Foreground" Value="$dlgText" />
            <Setter Property="BorderBrush" Value="$dlgInputBorder" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="10,6" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="CaretBrush" Value="#0078D4" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
        </Style>

        <ControlTemplate x:Key="ComboBoxToggleButton" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition />
                    <ColumnDefinition Width="28" />
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" CornerRadius="6" Background="$dlgInputBg" BorderBrush="$dlgInputBorder" BorderThickness="1" />
                <Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" Data="M 0 0 L 4 4 L 8 0 Z" Fill="$dlgText" />
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="BorderBrush" Value="#0078D4"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="$dlgText"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="ItemBorder" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}" Margin="2,1">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="#0078D4"/>
                                <Setter Property="TextElement.Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="#005A9E"/>
                                <Setter Property="TextElement.Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="$dlgText"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton" 
                                          Template="{StaticResource ComboBoxToggleButton}" 
                                          Grid.Column="2" 
                                          Focusable="false"
                                          IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}"
                                          ClickMode="Press">
                            </ToggleButton>
                            <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="10,3,28,3"
                                              VerticalAlignment="Center"
                                              HorizontalAlignment="Left" />
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True" 
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Grid Name="DropDown"
                                      SnapsToDevicePixels="True"
                                      MinWidth="{TemplateBinding ActualWidth}"
                                      MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border x:Name="DropDownBorder"
                                            Background="$dlgCard"
                                            BorderThickness="1"
                                            BorderBrush="$dlgBorder"
                                            CornerRadius="6"
                                            Margin="0,2,0,0"
                                            Padding="3">
                                        <ScrollViewer SnapsToDevicePixels="True">
                                            <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained" />
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    
        <!-- PasswordBox Stili -->
        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="{DynamicResource InputBgBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource InputBorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="10,7" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="CaretBrush" Value="{DynamicResource AccentBrush}" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="PasswordBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden" Padding="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- Üst Başlık & Arama Çubuğu -->
        <Border Grid.Row="0" Background="$dlgCard" BorderBrush="$dlgBorder" BorderThickness="1" CornerRadius="10" Padding="14" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Arama Girişi & Sağlayıcı Seçimi -->
                <Grid Grid.Row="0" Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="10" />
                        <ColumnDefinition Width="240" />
                        <ColumnDefinition Width="10" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    
                    <TextBox x:Name="TxtQ" Grid.Column="0" Height="38" ToolTip="Aranacak ikon adını yazın (Türkçe veya İngilizce, örn: kilit, lock, roket, roketler, ara, klasör)"/>
                    <ComboBox x:Name="CmbSet" Grid.Column="2" Height="38" VerticalContentAlignment="Center" MaxDropDownHeight="280" />
                    <Button x:Name="BtnSearch" Grid.Column="4" Content="🔍 Ara" Style="{StaticResource PrimaryBtn}" Width="90" Height="38"/>
                </Grid>

                <!-- Renk Kartelası Çubuğu (Tıklanabilir Renk Butonu + Hızlı Kartela) -->
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="10" />
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="16" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>

                    <CheckBox x:Name="ChkColor" Grid.Column="0" Content="Renk Uygula:" IsChecked="True" VerticalAlignment="Center" Foreground="$dlgSubText"/>
                    
                    <!-- Özel Renk Seçici Kutusu (ColorDialog Açar) -->
                    <Button x:Name="BtnColorPicker" Grid.Column="2" Height="30" Width="105" Padding="4,2" ToolTip="Tıklayarak özel renk paletinden dilediğiniz rengi seçin">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="BrdCurrentColor" Background="#0078D4" Width="18" Height="18" CornerRadius="3" BorderThickness="1" BorderBrush="#555555" Margin="0,0,6,0"/>
                            <TextBlock x:Name="TxtColorHexLabel" Text="Özel Renk" FontSize="11" VerticalAlignment="Center" Foreground="$dlgBtnText"/>
                        </StackPanel>
                    </Button>

                    <!-- Hızlı Renk Kartelası -->
                    <StackPanel Grid.Column="4" Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="Kartela:" VerticalAlignment="Center" FontSize="11" Foreground="$dlgSubText" Margin="0,0,6,0"/>
                        <Border x:Name="PalBlue" Background="#0078D4" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Mavi"/>
                        <Border x:Name="PalCyan" Background="#00B7C3" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Camgöbeği"/>
                        <Border x:Name="PalGreen" Background="#107C41" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Yeşil"/>
                        <Border x:Name="PalOrange" Background="#FF8C00" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Turuncu"/>
                        <Border x:Name="PalRed" Background="#E81123" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Kırmızı"/>
                        <Border x:Name="PalPurple" Background="#8764B8" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Mor"/>
                        <Border x:Name="PalWhite" Background="#FFFFFF" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Beyaz"/>
                        <Border x:Name="PalGray" Background="#8A8886" Width="20" Height="20" CornerRadius="4" Margin="3,0" Cursor="Hand" ToolTip="Gri"/>
                    </StackPanel>
                </Grid>
            </Grid>
        </Border>

        <!-- Durum Bildirimi -->
        <Border Grid.Row="1" Background="$dlgStatusBg" BorderBrush="$dlgBorder" BorderThickness="1" CornerRadius="6" Padding="10,6" Margin="0,0,0,10">
            <TextBlock x:Name="TxtDlgStatus" Text="Aramak istediğiniz anahtar kelimeyi (Türkçe veya İngilizce) yazıp 'Ara' butonuna basınız." FontSize="12" Foreground="$dlgStatusText"/>
        </Border>

        <!-- İkon Sonuç Izgarası -->
        <Border Grid.Row="2" Background="#FFFFFF" BorderBrush="#D0D5DD" BorderThickness="1" CornerRadius="10" Padding="2" ClipToBounds="True">
            <ScrollViewer x:Name="SvIcons" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="8">
                <WrapPanel x:Name="WpIcons" Margin="2"/>
            </ScrollViewer>
        </Border>

        <!-- Sayfalama Çubuğu (Pagination) -->
        <Border Grid.Row="3" Background="$dlgCard" BorderBrush="$dlgBorder" BorderThickness="1" CornerRadius="8" Padding="12,6" Margin="0,8,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>
                <Button x:Name="BtnPrevPage" Grid.Column="0" Content="◀ Önceki Sayfa" Width="110" Height="30" FontSize="11" IsEnabled="False"/>
                <TextBlock x:Name="TxtPageInfo" Grid.Column="1" Text="Sayfa 1 / 1 (0 İkon)" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="12" FontWeight="SemiBold" Foreground="$dlgText"/>
                <Button x:Name="BtnNextPage" Grid.Column="2" Content="Sonraki Sayfa ▶" Width="110" Height="30" FontSize="11" IsEnabled="False"/>
            </Grid>
        </Border>

        <!-- Alt Kontrol Çubuğu -->
        <Border Grid.Row="4" Background="$dlgCard" BorderBrush="$dlgBorder" BorderThickness="1" CornerRadius="10" Padding="14,10" Margin="0,8,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="10" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="TxtSelectedIcon" Grid.Column="0" Text="Seçili ikon: -" VerticalAlignment="Center" FontSize="13" Foreground="$dlgText" TextTrimming="CharacterEllipsis"/>
                <Button x:Name="BtnApply" Grid.Column="1" Content="✨ Seç ve İndir" Style="{StaticResource PrimaryBtn}" Height="36" Width="130" IsEnabled="False"/>
                <Button x:Name="BtnCancel" Grid.Column="3" Content="İptal" Height="36" Width="80"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $dlgReader = (New-Object System.Xml.XmlNodeReader $dlgXaml)
    $dlgWindow = [System.Windows.Markup.XamlReader]::Load($dlgReader)
    Set-WindowFitToWorkArea -Win $dlgWindow
    $dlgWindow.Owner = $window

    $txtQ         = $dlgWindow.FindName('TxtQ')
    $cmbSet       = $dlgWindow.FindName('CmbSet')
    $btnSearch    = $dlgWindow.FindName('BtnSearch')
    $chkColor     = $dlgWindow.FindName('ChkColor')
    $btnColorPicker = $dlgWindow.FindName('BtnColorPicker')
    $brdCurrentColor = $dlgWindow.FindName('BrdCurrentColor')
    $txtColorHexLabel = $dlgWindow.FindName('TxtColorHexLabel')
    $txtDlgStatus = $dlgWindow.FindName('TxtDlgStatus')
    $svIcons      = $dlgWindow.FindName('SvIcons')
    $wpIcons      = $dlgWindow.FindName('WpIcons')
    $btnPrevPage  = $dlgWindow.FindName('BtnPrevPage')
    $txtPageInfo  = $dlgWindow.FindName('TxtPageInfo')
    $btnNextPage  = $dlgWindow.FindName('BtnNextPage')
    $txtSelectedIcon = $dlgWindow.FindName('TxtSelectedIcon')
    $btnApply     = $dlgWindow.FindName('BtnApply')
    $btnCancel    = $dlgWindow.FindName('BtnCancel')

    # Sayfalama Değişkenleri (10 sütun x 5 satır = 50 ikon)
    $script:allFoundIcons = New-Object System.Collections.Generic.List[object]
    $script:currentPage = 1
    $script:pageSize = 50
    $script:totalPages = 1

    # Kartela renk kutucukları
    $script:selectedColorHex = "0078D4"
    $script:dlgPickedIconPath = $null
    $script:dlgPickedIconName = $null

    # İkon Izgarasındaki Tüm Görselleri Anında Yeni Renkle Güncelle (Live Vector Update)
    function script:Update-LiveIconsColor {
        $hex = if ($chkColor.IsChecked) { $script:selectedColorHex } else { '' }
        foreach ($b in $wpIcons.Children) {
            if ($b.Tag -and $b.Tag.Svg -and $b.Tag.Image) {
                try {
                    $dg = Convert-SvgToDrawingGroup $b.Tag.Svg $hex
                    if ($dg) {
                        $b.Tag.Image.Source = New-Object System.Windows.Media.DrawingImage $dg
                    }
                } catch {}
            }
        }
    }

    $palettes = [ordered]@{
        'PalBlue'   = '0078D4'
        'PalCyan'   = '00B7C3'
        'PalGreen'  = '107C41'
        'PalOrange' = 'FF8C00'
        'PalRed'    = 'E81123'
        'PalPurple' = '8764B8'
        'PalWhite'  = 'FFFFFF'
        'PalGray'   = '8A8886'
    }

    function script:Set-DialogSelectedColor([string]$hex, [string]$label = '') {
        $cleanHex = $hex -replace '^#',''
        $script:selectedColorHex = $cleanHex
        $chkColor.IsChecked = $true
        try {
            $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#" + $cleanHex)
            $brdCurrentColor.Background = $brush
        } catch {}
        if (-not $label) { $label = "#" + $cleanHex }
        $txtColorHexLabel.Text = $label

        # Kartela kutucuklarında seçili olanı vurgula
        foreach ($pName in $palettes.Keys) {
            $pCtrl = $dlgWindow.FindName($pName)
            if ($pCtrl) {
                if ($palettes[$pName] -eq $cleanHex) {
                    $pCtrl.BorderThickness = [System.Windows.Thickness]::new(2)
                    $pCtrl.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0078D4")
                } else {
                    $pCtrl.BorderThickness = [System.Windows.Thickness]::new(1)
                    $defaultBorderColor = if ($palettes[$pName] -eq 'FFFFFF') { '#888888' } else { 'Transparent' }
                    $pCtrl.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($defaultBorderColor)
                }
            }
        }

        # İkonları canlı güncelle
        Update-LiveIconsColor
    }

    # Renk onayı değiştiğinde ikon renklerini de canlı güncelle
    $chkColor.Add_Checked({ Update-LiveIconsColor })
    $chkColor.Add_Unchecked({ Update-LiveIconsColor })

    # Hızlı Kartela Olayları (Her kutucuğun Tag özelliğinden rengi oku)
    foreach ($pName in $palettes.Keys) {
        $pCtrl = $dlgWindow.FindName($pName)
        if ($pCtrl) {
            $pCtrl.Tag = $palettes[$pName]
            $pCtrl.Add_MouseDown({
                param($s, $e)
                Set-DialogSelectedColor $s.Tag
            })
        }
    }

    # Özel Renk Seçici Butonu (Windows ColorDialog)
    $btnColorPicker.Add_Click({
        $cd = New-Object System.Windows.Forms.ColorDialog
        $cd.FullOpen = $true
        try {
            $r = [Convert]::ToInt32($script:selectedColorHex.Substring(0,2), 16)
            $g = [Convert]::ToInt32($script:selectedColorHex.Substring(2,2), 16)
            $b = [Convert]::ToInt32($script:selectedColorHex.Substring(4,2), 16)
            $cd.Color = [System.Drawing.Color]::FromArgb($r, $g, $b)
        } catch {}

        if ($cd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $hexStr = ('{0:X2}{1:X2}{2:X2}' -f $cd.Color.R, $cd.Color.G, $cd.Color.B)
            Set-DialogSelectedColor $hexStr
        }
    })

    # Kaynak listesi (Popüler & Ücretsiz Açık Kaynak Veritabanları)
    $sets = @(
        'Tüm Kaynaklar',
        'Google Material Symbols',
        'Font Awesome',
        'Lucide & Feather',
        'Tabler Icons',
        'Remix Icon',
        'Bootstrap Icons',
        'Microsoft Fluent UI',
        'Boxicons',
        'Carbon Icons (IBM)',
        'Phosphor Icons',
        'Renkli İkonlar (Flat & Emoji)',
        'Flaticon',
        'Magnific Icons'
    )
    foreach ($s in $sets) { [void]$cmbSet.Items.Add($s) }
    $cmbSet.SelectedIndex = 0

    $script:dlgSelectedItem = $null
    $script:dlgSelectedBorder = $null

    $btnCancel.Add_Click({ $dlgWindow.Close() })

    function script:Select-DlgIconItem($item, $borderCtrl) {
        if ($null -ne $script:dlgSelectedBorder) {
            $script:dlgSelectedBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D0D5DD")
            $script:dlgSelectedBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8F9FA")
        }
        $script:dlgSelectedItem = $item
        $script:dlgSelectedBorder = $borderCtrl
        $borderCtrl.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0078D4")
        $borderCtrl.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E1F0FA")
        $txtSelectedIcon.Text = "Seçili ikon: $($item.Name) [$($item.Provider)]"
        $btnApply.IsEnabled = $true
    }

    function script:Save-And-Use-Icon {
        if (-not $script:dlgSelectedItem) { return }
        $item = $script:dlgSelectedItem
        $btnApply.IsEnabled = $false
        $txtDlgStatus.Text = "İkon indiriliyor ve işleniyor..."

        try {
            $dir = Join-Path $env:TEMP 'pwx_icons'
            if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
            $safeName = ([string]$item.Name -replace '[^\w\-]', '_')
            $uid = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + (Get-Random -Minimum 100 -Maximum 999)
            $file = Join-Path $dir ("icon_${safeName}_${uid}.png")
            $rawFile = Join-Path $dir ("icon_${safeName}_${uid}.download")

            $hex = if ($chkColor.IsChecked) { $script:selectedColorHex } else { '' }
            $downloadSuccess = $false

            # 1. Öncelikle seçili öğenin hafızadaki vektörünü kullanarak doğrudan dönüştür
            if ($script:dlgSelectedBorder -and $script:dlgSelectedBorder.Tag -and $script:dlgSelectedBorder.Tag.Svg) {
                $convOk = Convert-SvgToPngFile $script:dlgSelectedBorder.Tag.Svg $file $hex 256
                if ($convOk -and (Test-Path -LiteralPath $file)) {
                    $downloadSuccess = $true
                }
            }

            # 2. Hafızada yoksa Iconify SVG vektörünü indir ve dönüştür
            if (-not $downloadSuccess -and $item.Provider -eq 'Iconify') {
                $parts = ([string]$item.Name).Split(':', 2)
                if ($parts.Count -eq 2) {
                    $prefix = $parts[0]; $iconName = $parts[1]
                    $svgUrls = @(
                        "https://api.iconify.design/$prefix/$iconName.svg",
                        "https://api.simplesvg.com/$prefix/$iconName.svg",
                        "https://api.unisvg.com/$prefix/$iconName.svg"
                    )
                    $wcSvg = New-Object System.Net.WebClient
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/1.8.0'
                    $wcSvg.Encoding = [System.Text.Encoding]::UTF8

                    foreach ($sUrl in $svgUrls) {
                        try {
                            $svgContent = $wcSvg.DownloadString($sUrl)
                            if ($svgContent -and $svgContent.Contains('<svg')) {
                                $convOk = Convert-SvgToPngFile $svgContent $file $hex 256
                                if ($convOk -and (Test-Path -LiteralPath $file)) {
                                    $downloadSuccess = $true
                                    break
                                }
                            }
                        } catch {}
                    }
                }
            }

            # 2. Eğer SVG dönüştürülemediyse aday PNG URL'lerini dene
            if (-not $downloadSuccess) {
                $candidates = @(Get-IconPngCandidates $item 256 $hex)
                $wc = New-Object System.Net.WebClient
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.8.0'

                foreach ($u in $candidates) {
                    try {
                        if (Test-Path -LiteralPath $rawFile) { Remove-Item -LiteralPath $rawFile -Force -ErrorAction SilentlyContinue }
                        $wc.DownloadFile([uri]$u, $rawFile)
                        if (Test-ImageFile $rawFile) {
                            Save-NormalizedPng $rawFile $file
                            $downloadSuccess = $true
                            break
                        }
                    } catch { }
                }
            }

            if (-not $downloadSuccess -or -not (Test-Path -LiteralPath $file)) {
                throw "İkon indirilemedi. İnternet bağlantınızı veya ikon kaynağını kontrol edin."
            }

            Remove-Item -LiteralPath $rawFile -Force -ErrorAction SilentlyContinue

            # İndirilen ikonu aktarım değişkenine kaydet ve modal pencereyi kapat
            $script:dlgPickedIconPath = $file
            $script:dlgPickedIconName = $item.Name
            $dlgWindow.Close()
        }
        catch {
            $errMsg = $_.Exception.Message
            $txtDlgStatus.Text = "Hata: $errMsg"
            $btnApply.IsEnabled = $true
            try {
                [System.Windows.MessageBox]::Show($dlgWindow, $errMsg, "İndirme Hatası", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            } catch {}
        }
    }

    function script:Render-CurrentPage {
        $wpIcons.Children.Clear()
        $script:dlgSelectedItem = $null
        $script:dlgSelectedBorder = $null
        $btnApply.IsEnabled = $false
        $txtSelectedIcon.Text = "Seçili ikon: -"

        if ($script:allFoundIcons.Count -eq 0) {
            $txtPageInfo.Text = "Hiç ikon bulunamadı"
            $btnPrevPage.IsEnabled = $false
            $btnNextPage.IsEnabled = $false
            return
        }

        $script:totalPages = [Math]::Max(1, [int][Math]::Ceiling($script:allFoundIcons.Count / $script:pageSize))
        if ($script:currentPage -gt $script:totalPages) { $script:currentPage = $script:totalPages }
        if ($script:currentPage -lt 1) { $script:currentPage = 1 }

        $skipCount = ($script:currentPage - 1) * $script:pageSize
        $pageIcons = @($script:allFoundIcons | Select-Object -Skip $skipCount -First $script:pageSize)

        $btnPrevPage.IsEnabled = ($script:currentPage -gt 1)
        $btnNextPage.IsEnabled = ($script:currentPage -lt $script:totalPages)
        $txtPageInfo.Text = "Sayfa $($script:currentPage) / $($script:totalPages) (Toplam $($script:allFoundIcons.Count) İkon)"
        $txtDlgStatus.Text = "$($script:allFoundIcons.Count) adet ikon bulundu. Sayfa $($script:currentPage) / $($script:totalPages) yükleniyor..."

        $svgMap = Get-IconBatchSvgs $pageIcons
        $txtDlgStatus.Text = "$($script:allFoundIcons.Count) adet ikon hazır. Sayfa: $($script:currentPage) / $($script:totalPages). İstediğiniz ikona tıklayın."

        $hex = if ($chkColor.IsChecked) { $script:selectedColorHex } else { '' }

        foreach ($iconItem in $pageIcons) {
            $b = New-Object System.Windows.Controls.Border
            $b.Width = 72; $b.Height = 72
            $b.Margin = [System.Windows.Thickness]::new(3)
            $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8F9FA")
            $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D0D5DD")
            $b.BorderThickness = [System.Windows.Thickness]::new(1)
            $b.CornerRadius = [System.Windows.CornerRadius]::new(6)
            $b.Cursor = [System.Windows.Input.Cursors]::Hand
            $b.ToolTip = "$($iconItem.Name)`nSağlayıcı: $($iconItem.Provider)`nLisans: $($iconItem.License)"

            $sp = New-Object System.Windows.Controls.StackPanel
            $sp.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $sp.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

            $img = New-Object System.Windows.Controls.Image
            $img.Width = 36; $img.Height = 36
            $img.Stretch = [System.Windows.Media.Stretch]::Uniform
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::HighQuality)

            $caption = New-Object System.Windows.Controls.TextBlock
            $shortCaption = ([string]$iconItem.Name -split ':')[-1]
            if ($shortCaption.Length -gt 9) { $shortCaption = $shortCaption.Substring(0, 7) + '..' }
            $caption.Text = $shortCaption
            $caption.FontSize = 9
            $caption.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3748")
            $caption.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $caption.Margin = [System.Windows.Thickness]::new(0,2,0,0)

            [void]$sp.Children.Add($img)
            [void]$sp.Children.Add($caption)
            $b.Child = $sp

            # İkon SVG verisini al ve vektör olarak çiz
            $svgStr = if ($svgMap.ContainsKey($iconItem.Name)) { $svgMap[$iconItem.Name] } else { $null }

            # Tag içerisinde Item, Image, Border ve Svg referanslarını sakla (Canlı renk güncellemesi için)
            $b.Tag = [pscustomobject]@{ Item = $iconItem; Image = $img; Border = $b; Svg = $svgStr }

            if ($svgStr) {
                try {
                    $dg = Convert-SvgToDrawingGroup $svgStr $hex
                    if ($dg) {
                        $img.Source = New-Object System.Windows.Media.DrawingImage $dg
                    }
                } catch {}
            }

            $b.Add_MouseDown({
                param($src, $ev)
                $t = $src
                while ($t -and -not ($t.Tag -and $t.Tag.Item)) {
                    $t = [System.Windows.Media.VisualTreeHelper]::GetParent($t)
                }
                if ($t -and $t.Tag -and $t.Tag.Item) {
                    Select-DlgIconItem $t.Tag.Item $t.Tag.Border
                    if ($ev.ClickCount -ge 2) {
                        Save-And-Use-Icon
                    }
                }
            })

            [void]$wpIcons.Children.Add($b)
        }

        try { $svIcons.ScrollToTop() } catch {}
    }

    $btnPrevPage.Add_Click({
        if ($script:currentPage -gt 1) {
            $script:currentPage--
            Render-CurrentPage
        }
    })

    $btnNextPage.Add_Click({
        if ($script:currentPage -lt $script:totalPages) {
            $script:currentPage++
            Render-CurrentPage
        }
    })

    $btnApply.Add_Click({ Save-And-Use-Icon })

    $btnSearch.Add_Click({
        $q = $txtQ.Text.Trim()
        if (-not $q) {
            $txtDlgStatus.Text = "Lütfen aranacak bir kelime girin."
            return
        }

        $wpIcons.Children.Clear()
        $btnApply.IsEnabled = $false
        $script:dlgSelectedItem = $null
        $txtSelectedIcon.Text = "Seçili ikon: -"
        $txtDlgStatus.Text = "'$q' için ikonlar aranıyor..."
        $btnSearch.IsEnabled = $false

        try {
            $r = Search-Icons $q $cmbSet.SelectedIndex
            $script:allFoundIcons = $r.Icons
            $script:currentPage = 1

            if ($r.Icons.Count -eq 0) {
                $txtDlgStatus.Text = "Hiç ikon bulunamadı ('$($r.Query)'). Farklı bir kelime deneyin."
                $txtPageInfo.Text = "0 İkon"
                $btnPrevPage.IsEnabled = $false
                $btnNextPage.IsEnabled = $false
            } else {
                Render-CurrentPage
            }
        }
        catch {
            $txtDlgStatus.Text = "Hata oluştu: $($_.Exception.Message)"
        }
        finally {
            $btnSearch.IsEnabled = $true
        }
    })

    [void]$dlgWindow.ShowDialog()
}

$btnWebSearch.Add_Click({
    $script:dlgPickedIconPath = $null
    $script:dlgPickedIconName = $null
    Open-FluentIconDialog
    if ($script:dlgPickedIconPath -and (Test-Path -LiteralPath $script:dlgPickedIconPath)) {
        try {
            $txtLogo.Text = $script:dlgPickedIconPath
            Update-PreviewImage $script:dlgPickedIconPath
            Add-Log "Web ikon indirildi ve atandı: $script:dlgPickedIconName" 'Success'
        } catch {
            Add-Log "İkon atanırken hata oluştu: $($_.Exception.Message)" 'Error'
        }
    }
})

# ------------------------------------------------------------------
#  Derleme Motoru Tetikleyicisi (Invoke-Build)
# ------------------------------------------------------------------

$btnBuild.Add_Click({
    $btnBuild.IsEnabled = $false
    $txtConsole.Text = ""
    $pbStatus.IsIndeterminate = $true
    $txtStatus.Text = "Derleme başlatılıyor..."
    $script:LastGeneratedExe = ""
    $btnOpenFolder.IsEnabled = $false

    $ps1 = $txtPs1.Text.Trim()
    $outExe = $txtOut.Text.Trim()
    $logoPath = $txtLogo.Text.Trim()

    # Kullanıcının Uygulama Adı alanına yazdığı ismi esas al
    $appTitle = $txtTitle.Text.Trim()
    if ($appTitle -and -not $script:outExeManuallyChanged) {
        $safeTitle = $appTitle -replace '[\/\\:\*\?"<>\|]', '_'
        $outDir = $null
        if ($outExe) {
            try { $outDir = [System.IO.Path]::GetDirectoryName($outExe) } catch {}
        }
        if (-not $outDir -and $ps1) {
            try { $outDir = [System.IO.Path]::GetDirectoryName($ps1) } catch {}
        }
        if (-not $outDir) {
            $outDir = (Get-Location).Path
        }
        $outExe = Join-Path $outDir ($safeTitle + '.exe')
        $txtOut.Text = $outExe
    }

    try {
        if (-not $ps1 -or -not (Test-Path -LiteralPath $ps1 -PathType Leaf)) {
            throw 'Lütfen geçerli bir kaynak PowerShell (.ps1) dosyası seçin.'
        }
        if ([System.IO.Path]::GetExtension($ps1).ToLower() -ne '.ps1') {
            throw 'Kaynak dosya uzantısı .ps1 olmalıdır.'
        }
        if (-not $outExe) {
            throw 'Lütfen oluşturulacak hedef EXE dosya yolunu belirtin.'
        }
        if ([System.IO.Path]::GetExtension($outExe).ToLower() -ne '.exe') {
            throw 'Çıktı dosya uzantısı .exe olmalıdır.'
        }
        if ($chkX86.IsChecked -and $chkX64.IsChecked) {
            throw 'x86 ve x64 mimarileri aynı anda seçilemez. Yalnızca birini seçin.'
        }
        if ($logoPath -and -not (Test-Path -LiteralPath $logoPath -PathType Leaf)) {
            throw 'Seçilen simge/logo dosyası mevcut değil.'
        }
    }
    catch {
        Add-Log $_.Exception.Message 'Error'
        $txtStatus.Text = "Hata: $($_.Exception.Message)"
        $pbStatus.IsIndeterminate = $false
        $btnBuild.IsEnabled = $true
        [System.Windows.MessageBox]::Show($_.Exception.Message, "Doğrulama Uyarısı", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $buildParams = @{
        Ps1             = $ps1
        OutExe          = $outExe
        LogoPath        = $logoPath
        Target          = if ($rbTargetPS7.IsChecked) { 'PS7' } else { 'PS51' }
        Mode            = if ($rbGui.IsChecked) { 'Gui' } else { 'Console' }
        Title           = if ($txtTitle.Text.Trim()) { $txtTitle.Text.Trim() } else { [System.IO.Path]::GetFileNameWithoutExtension($ps1) }
        Ver             = if ($txtVer.Text.Trim() -match '^\d+(\.\d+){1,3}$') { $txtVer.Text.Trim() } else { '1.0.0.0' }
        Company         = $txtCompany.Text.Trim()
        SingleFile      = [bool]$chkSingleFile.IsChecked
        SmallSize       = [bool]$chkSmallSize.IsChecked
        IsX86           = [bool]$chkX86.IsChecked
        IsAdmin         = [bool]$chkAdmin.IsChecked
        ExecutionLevel  = if ($cmbExecutionLevel -and $cmbExecutionLevel.SelectedItem) { $cmbExecutionLevel.SelectedItem.Tag } else { 'asInvoker' }
        IsSign          = [bool]($chkSign -and $chkSign.IsChecked)
        CertSource      = if ($cmbCertSource -and $cmbCertSource.SelectedItem) { $cmbCertSource.SelectedItem.Tag } else { 'Thumbprint' }
        CertVal         = if ($txtCertValue) { $txtCertValue.Text.Trim() } else { '' }
        CertPass        = if ($txtCertPassword) { $txtCertPassword.Password } else { '' }
        TimestampServer = if ($txtTimestampServer -and $txtTimestampServer.Text) { $txtTimestampServer.Text.Trim() } else { 'http://timestamp.digicert.com' }
        IsUtf8          = [bool]$chkUtf8.IsChecked
        IsUnicode       = [bool]$chkUnicode.IsChecked
        IsDpi           = [bool]$chkDpi.IsChecked
        IsConfig        = [bool]$chkConfig.IsChecked
        IsSupportOS     = [bool]$chkSupportOS.IsChecked
        IsLongPaths     = [bool]$chkLongPaths.IsChecked
        IsNoOutput      = [bool]$chkNoOutput.IsChecked
        EncryptPayload  = [bool]($chkEncryptPayload -and $chkEncryptPayload.IsChecked)
        BindToMachine   = [bool]($chkBindToMachine -and $chkBindToMachine.IsChecked)
    }

    Add-Log "PwX Studio derleme işlemi başlatıldı..."
    Add-Log "Hedef: $($buildParams.Target) | Mod: $($buildParams.Mode) | Uygulama: $($buildParams.Title) (v$($buildParams.Ver))"

    $tempConvertedIcon = $null
    $tempPatchedSource = $null

    try {
        $iconForBuild = $null
        if ($buildParams.LogoPath) {
            $rawIcon = (Resolve-Path -LiteralPath $buildParams.LogoPath).Path
            if ([System.IO.Path]::GetExtension($rawIcon).ToLower() -eq '.ico') {
                $iconForBuild = $rawIcon
            } else {
                $iconForBuild = Join-Path $env:TEMP ('pwx_icon_' + [guid]::NewGuid().ToString('N') + '.ico')
                $tempConvertedIcon = $iconForBuild
                Convert-ToIco $rawIcon $iconForBuild
                Add-Log "Görsel, derleyici için çok boyutlu 256x256 ICO formatına dönüştürüldü."
            }
        }

        # Evrensel Pencere Simgesi Enjeksiyonu (WinForms & WPF / XAML Destekli)
        $compileInput = (Resolve-Path -LiteralPath $buildParams.Ps1).Path
        if ($iconForBuild) {
            $iconBytes = [System.IO.File]::ReadAllBytes($iconForBuild)
            $iconBase64 = [Convert]::ToBase64String($iconBytes)
            $sourceText = [System.IO.File]::ReadAllText($compileInput)
            $iconBootstrap = @'
# ==============================================================================
# PwX Studio Evrensel Pencere Simgesi Başlatıcı (WinForms + WPF / XAML Enjeksiyonu)
# ==============================================================================
try {
    if (-not $script:PwXIconBytes) {
        $script:PwXIconBytes = [Convert]::FromBase64String('__PWX_ICON_BASE64__')
        $script:PwXIconStream = New-Object System.IO.MemoryStream (,$script:PwXIconBytes)
        
        # Windows Forms Simgesi
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $script:PwXWinFormsIcon = New-Object System.Drawing.Icon ($script:PwXIconStream)
        } catch {}

        # WPF / XAML Simgesi
        try {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
            Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
            Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue
            $script:PwXIconStream.Position = 0
            $script:PwXWpfIcon = [System.Windows.Media.Imaging.BitmapFrame]::Create($script:PwXIconStream)
        } catch {}
    }

    # Evrensel Pencere Simge Atayıcısı
    function global:Set-PwXAppIcon($targetWindowOrForm) {
        try {
            if ($null -eq $targetWindowOrForm) { return }
            if ($targetWindowOrForm -is [System.Windows.Forms.Form] -and $script:PwXWinFormsIcon) {
                $targetWindowOrForm.Icon = $script:PwXWinFormsIcon
            }
            elseif ($targetWindowOrForm -is [System.Windows.Window] -and $script:PwXWpfIcon) {
                $targetWindowOrForm.Icon = $script:PwXWpfIcon
            }
        } catch {}
    }
    # Geriye dönük uyumluluk için takma ad
    function global:Set-PwXFormIcon($target) { Set-PwXAppIcon $target }

    # Otomatik Dinamik Form Kancası (Regex ile yakalanamayan veya sonradan açılan WinForms formları için)
    try {
        [System.Windows.Forms.Application]::add_Idle({
            try {
                foreach ($f in [System.Windows.Forms.Application]::OpenForms) {
                    if ($f -and -not $f.IsDisposed -and ($null -eq $f.Icon -or $f.Icon.Handle -eq [System.Drawing.SystemIcons]::Application.Handle)) {
                        $f.Icon = $script:PwXWinFormsIcon
                    }
                }
            } catch {}
        })
    } catch {}

} catch {}
# ==============================================================================
'@
            $iconBootstrap = $iconBootstrap.Replace('__PWX_ICON_BASE64__', $iconBase64)

            # Hem WinForms (Form) hem de WPF (Window/XamlReader) kalıplarını yakala
            $windowPattern = '(?m)^(\s*)(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:New-Object\s+(?:System\.)?(?:Windows\.Forms\.)?Form[^

]*|\[(?:System\.)?(?:Windows\.Forms\.)?Form\]::new\([^

]*\)|\[(?:System\.)?Windows\.Markup\.XamlReader\]::Load\([^

]*\)|New-Object\s+(?:System\.)?(?:Windows\.)?Window[^

]*|\[(?:System\.)?(?:Windows\.)?Window\]::new\([^

]*\))\s*$'
            $winMatches = [regex]::Matches($sourceText, $windowPattern)

            $patchedText = $sourceText
            if ($winMatches.Count -gt 0) {
                $patchedText = [regex]::Replace($sourceText, $windowPattern, [System.Text.RegularExpressions.MatchEvaluator]{
                    param($m)
                    $indent = $m.Groups[1].Value
                    $varName = $m.Groups[2].Value
                    return $m.Value + [Environment]::NewLine + $indent + 'Set-PwXAppIcon ' + $varName + [Environment]::NewLine + $indent + 'try { if (' + $varName + ' -is [System.Windows.Forms.Form]) { ' + $varName + '.Add_Shown({ Set-PwXAppIcon ' + $varName + ' }) } elseif (' + $varName + ' -is [System.Windows.Window]) { ' + $varName + '.Add_Loaded({ Set-PwXAppIcon ' + $varName + ' }) } } catch {}'
                })
            }

            # İkon bootstrap'ını betiğin en başına ekle (Her halükarda garantili çalışır)
            $patchedText = $iconBootstrap + [Environment]::NewLine + $patchedText

            $tempPatchedSource = Join-Path $env:TEMP ('PwX_IconPatched_' + [guid]::NewGuid().ToString('N') + '.ps1')
            [System.IO.File]::WriteAllText($tempPatchedSource, $patchedText, (New-Object System.Text.UTF8Encoding($true)))
            $compileInput = $tempPatchedSource
            Add-Log "Evrensel pencere simgesi kaynak koda entegre edildi ($($winMatches.Count) pencere/form doğrudan bağlandı, çalışma zamanı dinamik kancası devrede)."
        }

        # pwxe Derleme Motorunu Bulma (Akıllı Arama & Dahili Gömülü Motor)
                if ($chkEmbeddedEngine -and $chkEmbeddedEngine.IsChecked) {
            $engineScript = Deploy-EmbeddedPwXEngine
            if (-not $engineScript) { $engineScript = Get-PwXEnginePath }
        } else {
            $engineScript = Get-PwXEnginePath
        }
        if (-not $engineScript) {
            # Kullanıcıya manuel seçim penceresi sun
            $res = [System.Windows.MessageBox]::Show($window, "pwxe derleme motoru otomatik konumlarda bulunamadı.`r`n`r`n'PwX-Build.ps1' dosyasını manuel olarak seçmek ister misiniz?", "Derleme Motoru Bulunamadı", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
                $ofdEng = New-Object Microsoft.Win32.OpenFileDialog
                $ofdEng.Title = "PwX-Build.ps1 Dosyasını Seçin"
                $ofdEng.Filter = "PwX Derleme Motoru (PwX-Build.ps1)|PwX-Build.ps1|Tüm Dosyalar (*.*)|*.*"
                if ($ofdEng.ShowDialog($window) -eq $true) {
                    $engineScript = $ofdEng.FileName
                    $cfgDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio'
                    if (-not (Test-Path $cfgDir)) { [System.IO.Directory]::CreateDirectory($cfgDir) | Out-Null }
                    [System.IO.File]::WriteAllText((Join-Path $cfgDir 'engine_path.txt'), $engineScript, [System.Text.Encoding]::UTF8)
                }
            }
        }

        if ($engineScript) { 
            Add-Log "Derleme motoru: $engineScript" 
        } else {
            throw "pwxe derleme motoru bulunamadı veya seçilmedi. Lütfen motor klasörünü doğrulayın."
        }

        $bArgs = @{
            Source = $compileInput
            Output = [System.IO.Path]::GetFullPath($buildParams.OutExe)
            Target = $buildParams.Target
            Mode   = $buildParams.Mode
            Force  = $true
        }
        if ($iconForBuild) { $bArgs.Icon = $iconForBuild }
        if ($buildParams.Title) { $bArgs.ProductName = $buildParams.Title; $bArgs.Description = $buildParams.Title }
        if ($buildParams.Company) { $bArgs.CompanyName = $buildParams.Company }
        if ($buildParams.Ver) { $bArgs.FileVersion = $buildParams.Ver; $bArgs.ProductVersion = $buildParams.Ver }
        $bArgs.Admin = $buildParams.IsAdmin
        $bArgs.Utf8 = $buildParams.IsUtf8
        $bArgs.Unicode = $buildParams.IsUnicode
        $bArgs.Dpi = $buildParams.IsDpi
        $bArgs.Config = $buildParams.IsConfig
        $bArgs.SupportOS = $buildParams.IsSupportOS
        $bArgs.LongPaths = $buildParams.IsLongPaths
        $bArgs.NoOutput = $buildParams.IsNoOutput
        if ($buildParams.EncryptPayload) { $bArgs.EncryptPayload = $true }
        if ($buildParams.BindToMachine)  { $bArgs.BindToMachine = $true }
        $bArgs.Architecture = if ($buildParams.IsX86) { 'win-x86' } else { 'win-x64' }
        if ($buildParams.ExecutionLevel) {
            $bArgs.ExecutionLevel = $buildParams.ExecutionLevel
        }
        if ($buildParams.IsSign -and $buildParams.CertVal) {
            if ($buildParams.CertSource -eq 'File') {
                $bArgs.CertificateFile = $buildParams.CertVal
            } else {
                $bArgs.CertificateThumbprint = $buildParams.CertVal
            }
            if ($buildParams.CertPass) {
                $bArgs.CertificatePassword = $buildParams.CertPass
            }
            if ($buildParams.TimestampServer) {
                $bArgs.TimestampServer = $buildParams.TimestampServer
            }
        }
        
        if ($buildParams.Target -eq 'PS7') {
            if ($buildParams.SingleFile) { $bArgs.SingleFile = $true }
            if ($buildParams.SmallSize) { $bArgs.RuntimeMode = 'FrameworkDependent' }
        }

                # Parametreleri motorun desteklediği parametrelerle dinamik eşle (Geriye dönük uyumluluk)
        try {
            $cmd = Get-Command -Name $engineScript -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Parameters) {
                $filteredArgs = @{}
                foreach ($k in $bArgs.Keys) {
                    if ($cmd.Parameters.ContainsKey($k)) {
                        $filteredArgs[$k] = $bArgs[$k]
                    } else {
                        $val = $bArgs[$k]
                        if ($val -and ($val -isnot [bool] -or $val -eq $true)) {
                            Add-Log "[UYARI] Derleme motoru '$k' parametresini desteklemiyor; bu seÃ§enek uygulanamadÄ±." "Warning"
                        }
                    }
                }
                $bArgs = $filteredArgs
            }
        } catch {}

        Add-Log "Derleme motoru çalıştırılıyor: $engineScript"
        $txtStatus.Text = "Derleniyor: $($buildParams.Title)..."

        $res = @(& $engineScript @bArgs) | Where-Object { $_ -and $_.PSObject.Properties['Success'] } | Select-Object -Last 1

        # PS7 gereksinimleri (.NET SDK 8+, NuGet kaynağı) eksikse: kullanıcı onayıyla otomatik kur ve yeniden dene
        if ($null -ne $res -and -not $res.Success -and $buildParams.Target -eq 'PS7') {
            $missing = @($res.Diagnostics | Where-Object { $_.Severity -eq 'Error' -and ($_.Code -eq 'PWX3005' -or $_.Code -eq 'PWX3006') })
            if ($missing.Count -gt 0) {
                $detail = (@($missing | ForEach-Object { '- ' + $_.Message })) -join "`r`n"
                $answer = [System.Windows.MessageBox]::Show($window,
                    "PS7 hedefi için eksik gereksinimler var:`r`n`r`n$detail`r`n`r`nOtomatik kurulsun / düzeltilsin mi?`r`n`r`n(İnternet gerekir. winget veya Microsoft'un resmi dotnet-install betiği kullanılır; yönetici onayı istenebilir. Kurulum sırasında pencere birkaç dakika yanıt vermeyebilir.)",
                    'Gereksinimler Eksik',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question)
                if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {
                    Add-Log 'Eksik gereksinimler otomatik kuruluyor/düzeltiliyor...' 'Warning'
                    $txtStatus.Text = 'Gereksinimler kuruluyor...'
                    $bArgs.AutoInstallPrereqs = $true
                    $res = @(& $engineScript @bArgs) | Where-Object { $_ -and $_.PSObject.Properties['Success'] } | Select-Object -Last 1
                }
            }
        }

        if ($null -ne $res -and -not $res.Success) {
            $errText = (@($res.Diagnostics | Where-Object { $_.Severity -eq 'Error' } | ForEach-Object { "$($_.Code) $($_.Message)" })) -join "`r`n"
            if (-not $errText) { $errText = 'Bilinmeyen hata. Günlük dosyasına bakın.' }
            throw "Derleme motoru hatası:`r`n$errText"
        }

        if (-not (Test-Path -LiteralPath $buildParams.OutExe -PathType Leaf)) {
            throw "Derleme tamamlandı fakat çıktı EXE dosyası bulunamadı."
        }

        $item = Get-Item -LiteralPath $buildParams.OutExe
        $script:LastGeneratedExe = $item.FullName

        Add-Log "BAŞARILI: $($item.FullName) ($([Math]::Round($item.Length / 1KB, 1)) KB)" 'Success'
        $txtStatus.Text = "Derleme başarıyla tamamlandı!"
        $pbStatus.IsIndeterminate = $false
        $pbStatus.Value = 100
        $btnOpenFolder.IsEnabled = $true
        [System.Windows.MessageBox]::Show($window, "EXE başarıyla oluşturuldu:`r`n$($item.FullName)", "İşlem Başarılı", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
    catch {
        $errMsg = $_.Exception.Message
        Add-Log "HATA: $errMsg" 'Error'
        $txtStatus.Text = "Hata oluştu. Günlük ayrıntılarına bakınız."
        $pbStatus.IsIndeterminate = $false
        [System.Windows.MessageBox]::Show($window, $errMsg, "Derleme Hatası", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    finally {
        if ($tempPatchedSource -and (Test-Path -LiteralPath $tempPatchedSource)) {
            Remove-Item -LiteralPath $tempPatchedSource -Force -ErrorAction SilentlyContinue
        }
        if ($tempConvertedIcon -and (Test-Path -LiteralPath $tempConvertedIcon)) {
            Remove-Item -LiteralPath $tempConvertedIcon -Force -ErrorAction SilentlyContinue
        }
        $btnBuild.IsEnabled = $true
    }
})

# Başlangıç durumu
Add-Log "PwX Studio v1.8.0 hazır."
Add-Log "Dönüştürmek istediğiniz .ps1 dosyasını sürükleyip bırakabilir veya 'Gözat' butonunu kullanabilirsiniz."

# Başlangıçta motor durumunu kontrol et ve bildir
try {
    $startupEngine = Get-PwXEnginePath
    if ($startupEngine) {
        Add-Log "Aktif Derleme Motoru: $startupEngine"
    }
} catch {}

# Pencere Kapatıldığında Temiz Çıkış
$window.Add_Closed({
    try {
        if ([System.Windows.Application]::Current) {
            $currApp = [System.Windows.Application]::Current
            if ($currApp.Dispatcher -and $currApp.Dispatcher.CheckAccess()) {
                $currApp.Shutdown()
            }
        }
    } catch {}
})

# Pencereyi Göster
[void]$window.ShowDialog()
