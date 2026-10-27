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
$script:EmbeddedPwXEngineHash = 'e792f8a8727415830922ad5e752ab48a58eb1e1cac7e828161881835c271999f'
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
