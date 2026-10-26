#Requires -Version 5.1
<#
    PwX Studio v1.7.0 - PowerShell Executable Builder
    - Windows 11 Modern Arayüz (Saf WPF/XAML Mimarisi)
    - Dinamik Tema Desteği: Açık Tema ve Koyu Tema geçişi
    - PowerShell 5.1 (Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Çok kaynaklı Web İkon Arama Hub'ı (Gelişmiş Türkçe/İngilizce Arama & Renk Kartelası)
    - Türkçe karakter uyumlu (UTF-8 dosya ve konsol UTF-8 çıktı motoru)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v1.7.0.ps1
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
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.7.0'
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
    $wc.Headers['User-Agent'] = 'PwX-Studio/1.7.0'

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
        Title="PwX Studio v1.7.0 - PowerShell Executable Builder"
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
                            <TextBlock Text="v1.7.0" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
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
                                </StackPanel>
                            </Grid>
                        </StackPanel>
                    </Border>
                </Grid>

                                <!-- Kart: Authenticode Dijital Kod İmzalama (v1.7.0) -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBlock x:Name="LblCodeSigningTitle" Text="🔏 Authenticode Dijital Kod İmzalama (v1.7.0)" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
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
        <TextBlock x:Name="LblFooter" Grid.Row="3" Text="PwX Studio v1.7.0 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
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
$script:EmbeddedPwXEngineHash = '700b5d16db327b0a6932e278718ab02760e6c42d38ee3ddf01344e64e820a37b'
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
#  pwxe Motor Arama & Gomulu Zip Cikarma (v1.7.0 patch)
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
        if ($window) { $window.Title = "PwX Studio v1.7.0 - PowerShell Executable Builder" }
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
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v1.7.0)" }
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
        if ($btnBuild) { $btnBuild.Content = "🚀 BUILD EXE" }
        if ($btnOpenFolder) { $btnOpenFolder.Content = "📂 Open Folder" }
        if ($txtStatus) { 
            if ($txtStatus.Text -eq "Hazır. Kaynak betiği belirleyip 'EXE OLUŞTUR' butonuna basınız.") {
                $txtStatus.Text = "Ready. Select source script and click 'BUILD EXE'."
            }
        }
        if ($lblConsoleTitle) { $lblConsoleTitle.Text = "⚡ Live Console Log" }
        if ($btnClearLog) { $btnClearLog.Content = "Clear" }
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.7.0 • PowerShell Executable Builder" }
    } else {
        if ($btnLangToggle) {
            $btnLangToggle.Content = [char]::ConvertFromUtf32(0x1F310) + " EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to TÃ¼rkÃ§e)"
        }
        if ($window) { $window.Title = "PwX Studio v1.7.0 - PowerShell Executable Builder" }
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
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v1.7.0)" }
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
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Dijital Kod İmzalama (v1.7.0)" }
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
        if ($btnBuild) { $btnBuild.Content = "🚀 EXE OLUŞTUR" }
        if ($btnOpenFolder) { $btnOpenFolder.Content = "📂 Klasörü Aç" }
        if ($txtStatus) { 
            if ($txtStatus.Text -eq "Ready. Select source script and click 'BUILD EXE'.") {
                $txtStatus.Text = "Hazır. Kaynak betiği belirleyip 'EXE OLUŞTUR' butonuna basınız."
            }
        }
        if ($lblConsoleTitle) { $lblConsoleTitle.Text = "⚡ Canlı Konsol Günlüğü" }
        if ($btnClearLog) { $btnClearLog.Content = "Temizle" }
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.7.0 • PowerShell Executable Builder" }
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
#  UAC & Authenticode Kod İmzalama Olay Yöneticileri (v1.7.0)
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
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/1.7.0'
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
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.7.0'

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
Add-Log "PwX Studio v1.7.0 hazır."
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
