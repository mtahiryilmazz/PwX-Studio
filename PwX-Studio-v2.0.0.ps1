#Requires -Version 5.1
<#
    PwX Studio v2.0.0 - PowerShell Executable Builder
    - Windows 11 Modern Arayüz (Saf WPF/XAML Mimarisi)
    - Dinamik Tema Desteği: Açık Tema ve Koyu Tema geçişi
    - PowerShell 5.1 (Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Çok kaynaklı Web İkon Arama Hub'ı (Gelişmiş Türkçe/İngilizce Arama & Renk Kartelası)
    - Türkçe karakter uyumlu (UTF-8 dosya ve konsol UTF-8 çıktı motoru)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v2.0.0.ps1
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
                    $wc.Headers['User-Agent'] = 'PwX-Studio/2.0.0'
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
    $wc.Headers['User-Agent'] = 'PwX-Studio/2.0.0'

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
        Title="PwX Studio v2.0.0 - PowerShell Executable Builder"
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
                            <TextBlock Text="v2.0.0" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
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
                                        <ComboBoxItem x:Name="CmbItemAsInvoker" Content="Standart" Tag="asInvoker" IsSelected="True" ToolTip="[asInvoker] Standart kullanıcı yetkisiyle açılır, UAC onayı istemez."/>
                                        <ComboBoxItem x:Name="CmbItemHighestAvailable" Content="En Yüksek" Tag="highestAvailable" ToolTip="[highestAvailable] Kullanıcı yöneticiyse UAC onayı ister, standart kullanıcıysa sormadan açılır."/>
                                        <ComboBoxItem x:Name="CmbItemRequireAdmin" Content="Tam Yetki (Yönetici)" Tag="requireAdministrator" ToolTip="[requireAdministrator] Her açılışta mutlaka Windows UAC yönetici onayı ister, tam yetkiyle çalışır."/>
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
                                    <CheckBox x:Name="ChkInProcess" Content="Süreç İçi Çalıştırma (In-Process)" ToolTip="Alt powershell.exe süreci açmadan doğrudan System.Management.Automation Runspace içinde çalıştırır (sıfır alt süreç, EDR/antivirüs dostu)."/>
                                </StackPanel>
                            </Grid>
                        </StackPanel>
                    </Border>
                </Grid>

                                <!-- Kart: Authenticode Dijital Kod İmzalama (v2.0.0) -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBlock x:Name="LblCodeSigningTitle" Text="🔏 Authenticode Dijital Kod İmzalama (v2.0.0)" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
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
        <TextBlock x:Name="LblFooter" Grid.Row="3" Text="PwX Studio v2.0.0 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
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
$script:EmbeddedPwXEngineHash = 'a102ceb4e3a743e12ae458ebc7db622183e0248defd79c66ea9968450391c7dd'
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
#  pwxe Motor Arama & Gomulu Zip Cikarma (v2.0.0 patch)
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
$chkInProcess      = $window.FindName('ChkInProcess')

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
        if ($window) { $window.Title = "PwX Studio v2.0.0 - PowerShell Executable Builder" }
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
            $cmbItemAsInvoker.Content = "Standard"
            $cmbItemAsInvoker.ToolTip = "[asInvoker] Runs with standard user privileges without prompting for elevation."
        }
        if ($cmbItemHighestAvailable) {
            $cmbItemHighestAvailable.Content = "Highest Available"
            $cmbItemHighestAvailable.ToolTip = "[highestAvailable] Prompts for UAC elevation if user is an administrator; runs without prompt if standard user."
        }
        if ($cmbItemRequireAdmin) {
            $cmbItemRequireAdmin.Content = "Full Administrator"
            $cmbItemRequireAdmin.ToolTip = "[requireAdministrator] Always prompts for UAC elevation and requires full administrator privileges."
        }
        if ($cmbItemThumbprint) {
            $cmbItemThumbprint.Content = "Thumbprint (Windows Certificate Store)"
            $cmbItemThumbprint.ToolTip = "Uses installed code signing certificate from Windows Certificate Store (CurrentUser\My)."
        }
        if ($cmbItemFile) {
            $cmbItemFile.Content = "PFX / P12 File"
            $cmbItemFile.ToolTip = "Uses .pfx or .p12 certificate file located on disk."
        }
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v2.0.0)" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v2.0.0 • PowerShell Executable Builder" }
    } else {
        if ($btnLangToggle) {
            $btnLangToggle.Content = [char]::ConvertFromUtf32(0x1F310) + " EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to TÃ¼rkÃ§e)"
        }
        if ($window) { $window.Title = "PwX Studio v2.0.0 - PowerShell Executable Builder" }
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
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Digital Code Signing (v2.0.0)" }
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
            $cmbItemAsInvoker.Content = "Standart"
            $cmbItemAsInvoker.ToolTip = "[asInvoker] Standart kullanıcı yetkisiyle açılır, UAC onayı istemez."
        }
        if ($cmbItemHighestAvailable) {
            $cmbItemHighestAvailable.Content = "En Yüksek"
            $cmbItemHighestAvailable.ToolTip = "[highestAvailable] Kullanıcı yöneticiyse UAC onayı ister, standart kullanıcıysa sormadan açılır."
        }
        if ($cmbItemRequireAdmin) {
            $cmbItemRequireAdmin.Content = "Tam Yetki (Yönetici)"
            $cmbItemRequireAdmin.ToolTip = "[requireAdministrator] Her açılışta mutlaka Windows UAC yönetici onayı ister, tam yetkiyle çalışır."
        }
        if ($cmbItemThumbprint) {
            $cmbItemThumbprint.Content = "Parmak İzi (Thumbprint - Windows Deposu)"
            $cmbItemThumbprint.ToolTip = "Windows Sertifika Deposundaki (CurrentUser\My) yüklü kod imzalama sertifikasını kullanır."
        }
        if ($cmbItemFile) {
            $cmbItemFile.Content = "PFX / P12 Dosyası"
            $cmbItemFile.ToolTip = "Diskte bulunan .pfx veya .p12 sertifika dosyasını kullanır."
        }
        if ($lblCodeSigningTitle) { $lblCodeSigningTitle.Text = "🔏 Authenticode Dijital Kod İmzalama (v2.0.0)" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v2.0.0 • PowerShell Executable Builder" }
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
#  UAC & Authenticode Kod İmzalama Olay Yöneticileri (v2.0.0)
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
        if ($cmbExecutionLevel.SelectedItem -and $cmbExecutionLevel.SelectedItem.Tag -eq 'asInvoker') {
            foreach ($it in $cmbExecutionLevel.Items) {
                if ($it.Tag -eq 'requireAdministrator') { $cmbExecutionLevel.SelectedItem = $it; break }
            }
        }
    })
    $chkAdmin.Add_Unchecked({
        if ($cmbExecutionLevel.SelectedItem -and $cmbExecutionLevel.SelectedItem.Tag -eq 'requireAdministrator') {
            foreach ($it in $cmbExecutionLevel.Items) {
                if ($it.Tag -eq 'asInvoker') { $cmbExecutionLevel.SelectedItem = $it; break }
            }
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
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/2.0.0'
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
                $wc.Headers['User-Agent'] = 'PwX-Studio/2.0.0'

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
        InProcess       = [bool]($chkInProcess -and $chkInProcess.IsChecked)
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
        if ($buildParams.InProcess)      { $bArgs.InProcess = $true; $bArgs.HostMode = 'InProcess' }
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
Add-Log "PwX Studio v2.0.0 hazır."
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
