#Requires -Version 5.1
<#
    PwX Studio v1.6.2 - PowerShell Executable Builder
    - Windows 11 Modern Arayüz (Saf WPF/XAML Mimarisi)
    - Dinamik Tema Desteği: Açık Tema ve Koyu Tema geçişi
    - PowerShell 5.1 (Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Çok kaynaklı Web İkon Arama Hub'ı (Gelişmiş Türkçe/İngilizce Arama & Renk Kartelası)
    - Türkçe karakter uyumlu (UTF-8 dosya ve konsol UTF-8 çıktı motoru)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v1.6.1.ps1
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
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.1'
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
    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.1'

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
        Title="PwX Studio v1.6.2 - PowerShell Executable Builder"
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
                            <TextBlock Text="v1.6.2" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
                        </Border>
                    </StackPanel>
                    <TextBlock x:Name="LblSubtitle" Text="PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." 
                               FontSize="13" Foreground="{DynamicResource SubTextBrush}" Margin="0,3,0,0" />
                </StackPanel>

                <!-- Açık / Koyu Tema Geçiş Anahtarı (Toggle Switch) -->
                <!-- SaÄŸ Butonlar: Dil SeÃ§ici ve Tema AnahtarÄ± -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnLangToggle" Content="ğŸŒ TR" Height="28" Padding="10,2" Margin="0,0,12,0" 
                            FontWeight="Bold" FontSize="11" ToolTip="Dili DeÄŸiÅŸtir / Switch Language (TR / EN)"/>
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
                        <TextBlock Text="📁 Dosya Yapılandırması" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,12"/>
                        
                        <TextBlock Text="Kaynak PowerShell Betiği (.ps1):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,12">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="10" />
                                <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="TxtPs1" Grid.Column="0" Height="38" ToolTip="Dönüştürülecek .ps1 betiğini seçin veya dosyayı buraya sürükleyin."/>
                            <Button x:Name="BtnPs1Browse" Grid.Column="2" Content="📁 Gözat..." Width="100" Height="38"/>
                        </Grid>

                        <TextBlock Text="Hedef Yürütülebilir Dosya (.exe):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
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
                            <TextBlock Text="🎨 Uygulama Logosu &amp; Simgesi" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <TextBlock Text="Görsel Dosyası (PNG, JPG, BMP, ICO):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
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
                            <TextBlock Text="Seçilen PNG/JPG görseller derleme anında otomatik olarak 256x256 ICO formatına dönüştürülür." FontSize="11" Foreground="{DynamicResource SubTextBrush}"/>
                        </StackPanel>

                        <!-- Canlı Önizleme Kutusu -->
                        <StackPanel Grid.Column="2" VerticalAlignment="Center" HorizontalAlignment="Center">
                            <Border Width="76" Height="76" Background="{DynamicResource InputBgBrush}" BorderBrush="{DynamicResource InputBorderBrush}" BorderThickness="1" CornerRadius="8" Padding="4">
                                <Grid>
                                    <TextBlock x:Name="TxtNoIcon" Text="SİMGE YOK" FontSize="10" Foreground="{DynamicResource SubTextBrush}" HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center" FontWeight="SemiBold"/>
                                    <Image x:Name="ImgPreview" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                                </Grid>
                            </Border>
                            <TextBlock Text="Önizleme" FontSize="10" Foreground="{DynamicResource SubTextBrush}" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- Kart: Meta Veriler -->
                <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="ℹ️ Uygulama Bilgileri &amp; Meta Veriler" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,12"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="2*" />
                                <ColumnDefinition Width="14" />
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="14" />
                                <ColumnDefinition Width="2*" />
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0">
                                <TextBlock Text="Uygulama Adı / Başlık:" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                                <TextBox x:Name="TxtTitle" Height="38"/>
                            </StackPanel>

                            <StackPanel Grid.Column="2">
                                <TextBlock Text="Sürüm (x.x.x.x):" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
                                <TextBox x:Name="TxtVer" Height="38" Text="1.0.0.0"/>
                            </StackPanel>

                            <StackPanel Grid.Column="4">
                                <TextBlock Text="Şirket / Yayıncı:" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource SubTextBrush}" Margin="0,0,0,5"/>
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
                            <TextBlock Text="⚙️ Hedef Çalışma Zamanı" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <RadioButton x:Name="RbTargetPS51" GroupName="TargetRuntime" Content="PowerShell 5.1 (Dahili csc.exe)" IsChecked="True" 
                                         ToolTip="Windows ile dahili gelen csc.exe derleyicisini kullanır." Margin="0,2,0,8"/>
                            <RadioButton x:Name="RbTargetPS7" GroupName="TargetRuntime" Content="PowerShell 7.4+ (.NET 8 SDK)" 
                                         ToolTip="Modern PowerShell 7 ve .NET 8 SDK altyapısını kullanır." Margin="0,0,0,6"/>
                            <CheckBox x:Name="ChkSingleFile" Content="Tek Dosya (Single-File)" IsEnabled="False" Margin="22,0,0,6"/>
                            <CheckBox x:Name="ChkSmallSize" Content="Küçük boyut (hedefte .NET 8 Runtime gerekir)" IsEnabled="False" Margin="22,0,0,16"
                                      ToolTip="FrameworkDependent: .NET çalışma zamanı EXE'ye eklenmez, çıktı çok daha küçük olur. Çalıştıracak bilgisayarda .NET 8 Runtime (GUI için Windows Desktop Runtime 8) kurulu olmalıdır. pwsh gerekmez."/>

                            <Border Height="1" Background="{DynamicResource BorderBrush}" Margin="0,0,0,14"/>

                            <TextBlock Text="🖥️ Uygulama Türü" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <RadioButton x:Name="RbConsole" GroupName="AppMode" Content="Konsol Uygulaması (CLI)" IsChecked="True" Margin="0,2,0,8"/>
                            <RadioButton x:Name="RbGui" GroupName="AppMode" Content="Pencereli / GUI Uygulama (Konsol Gizli)" Margin="0,0,0,4"/>

                            <Border Height="1" Background="{DynamicResource BorderBrush}" Margin="0,12,0,12"/>

                            <TextBlock Text="🚀 Derleme Motoru Seçimi" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                            <CheckBox x:Name="ChkEmbeddedEngine" Content="Dahili pwxe Motoru (Taşınabilir / Offline)" IsChecked="True" 
                                      ToolTip="pwxe motorunu dış klasörlere ihtiyaç duymadan doğrudan uygulama içerisindeki gömülü motordan çalıştırır. Uygulama masaüstüne veya başka bilgisayara taşındığında sorunsuz çalışmasını sağlar." Margin="0,0,0,4"/>
                        </StackPanel>
                    </Border>

                    <!-- Sağ Sütun: Derleme & Çalışma Bayrakları (2 Alt Sütunlu Tertipli Liste) -->
                    <Border Grid.Column="2" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="16">
                        <StackPanel>
                            <TextBlock Text="🛠️ Derleme &amp; Çalışma Seçenekleri" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*" />
                                    <ColumnDefinition Width="10" />
                                    <ColumnDefinition Width="*" />
                                </Grid.ColumnDefinitions>

                                <StackPanel Grid.Column="0">
                                    <CheckBox x:Name="ChkAdmin" Content="Yönetici Yetkisi (UAC)" ToolTip="Windows UAC yönetici onayı ister."/>
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
                    <TextBlock Text="⚡ Canlı Konsol Günlüğü" FontSize="12" FontWeight="Bold" Foreground="#38BDF8"/>
                    <Button x:Name="BtnClearLog" Content="Temizle" HorizontalAlignment="Right" Padding="10,3" FontSize="11"/>
                </Grid>
                <TextBox x:Name="TxtConsole" Grid.Row="1" Background="{DynamicResource TerminalBgBrush}" Foreground="{DynamicResource TerminalTextBrush}" FontFamily="Cascadia Code, Consolas" FontSize="12" 
                         IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" BorderThickness="0" Padding="4"/>
            </Grid>
        </Border>

        <!-- 4. Footer (Sade ve Temiz) -->
        <TextBlock Grid.Row="3" Text="PwX Studio v1.6.2 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
'@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
Set-WindowFitToWorkArea -Win $window -Center

# Logo ve ikon ata (Akıllı İkon Tespiti & Dahili İkon Desteği)
$pwxIconCandidate = $null
$iconPaths = @()
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

$null           = $window.FindName('RbConsole')
$rbGui          = $window.FindName('RbGui')

$chkAdmin       = $window.FindName('ChkAdmin')
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

# ==================================================================
#  pwxe Derleme Motoru Yönetimi (Akıllı Arama ve Dahili Gömülü Motor)
# ==================================================================
$script:EmbeddedPwXEngineZipBase64 = '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'

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

function Deploy-EmbeddedPwXEngine {
    param([switch]$Force)
    try {
        $engineDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine'
        $scriptPath = Join-Path $engineDir 'scripts\PwX-Build.ps1'
        if (-not $Force -and (Test-Path -LiteralPath $scriptPath)) {
            return $scriptPath
        }

        if (-not (Test-Path -LiteralPath $engineDir)) {
            [System.IO.Directory]::CreateDirectory($engineDir) | Out-Null
        }

        $bytes = [System.Convert]::FromBase64String($script:EmbeddedPwXEngineZipBase64)
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
        foreach ($entry in $zip.Entries) {
            $destPath = Join-Path $engineDir $entry.FullName
            $parentDir = Split-Path -Parent $destPath
            if (-not (Test-Path -LiteralPath $parentDir)) {
                [System.IO.Directory]::CreateDirectory($parentDir) | Out-Null
            }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
        }
        $zip.Dispose()
        $ms.Dispose()

        if (Test-Path -LiteralPath $scriptPath) {
            $cfgDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio'
            if (-not (Test-Path $cfgDir)) { [System.IO.Directory]::CreateDirectory($cfgDir) | Out-Null }
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'engine_path.txt'), $scriptPath, [System.Text.Encoding]::UTF8)
            return $scriptPath
        }
    } catch {
        Write-Warning "Dahili pwxe motoru çıkartılamadı: $_"
    }
    return $null
}

function Get-PwXEnginePath {
    param([switch]$ForceRedeploy)

    # 1. Önceden yapılandırılmış/kaydedilmiş motor yolu
    $cfgFile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine_path.txt'
    if (-not $ForceRedeploy -and (Test-Path -LiteralPath $cfgFile)) {
        try {
            $saved = (Get-Content -LiteralPath $cfgFile -Raw).Trim()
            if ($saved -and (Test-Path -LiteralPath $saved)) { return $saved }
        } catch {}
    }

    # 2. Göreli / Komşu Dizinler (Geliştirici veya Taşınabilir Klasör)
    $relCandidates = @(
        (Join-Path $PSScriptRoot 'pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $PSScriptRoot '..\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $PSScriptRoot 'pwxengine\scripts\PwX-Build.ps1'),
        (Join-Path (Get-Location) 'pwxe\scripts\PwX-Build.ps1'),
        (Join-Path (Get-Location) '..\pwxe\scripts\PwX-Build.ps1')
    )
    foreach ($c in $relCandidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }

    # 3. Yüklü PowerShell Modülü (PSGallery / Yerel PSModulePath)
    try {
        $pwxeMod = Get-Module -ListAvailable pwxe -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if ($pwxeMod) {
            $modCand = Join-Path $pwxeMod.ModuleBase 'scripts\PwX-Build.ps1'
            if (Test-Path -LiteralPath $modCand) { return $modCand }
        }
    } catch {}

    # 4. Akıllı Tarama: Yaygın Kullanıcı & Geliştirme Dizinleri
    $userProf = [Environment]::GetFolderPath('UserProfile')
    $myDocs   = [Environment]::GetFolderPath('MyDocuments')
    $smartCandidates = @(
        (Join-Path $myDocs 'Github\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $myDocs 'GitHub\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $userProf 'Documents\Github\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $userProf 'Documents\GitHub\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $userProf 'Desktop\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $userProf 'Downloads\pwxe\scripts\PwX-Build.ps1'),
        (Join-Path $userProf 'source\repos\pwxe\scripts\PwX-Build.ps1')
    )
    foreach ($sc in $smartCandidates) {
        if ($sc -and (Test-Path -LiteralPath $sc)) { return $sc }
    }

    # 5. Daha önce otomatik açılmış yerel AppData motoru
    $appDataScript = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\scripts\PwX-Build.ps1'
    if (-not $ForceRedeploy -and (Test-Path -LiteralPath $appDataScript)) {
        return $appDataScript
    }

    # 6. Herhangi bir yerde bulunamazsa: Dahili Gömülü Motoru Otomatik Kur
    $deployed = Deploy-EmbeddedPwXEngine
    if ($deployed -and (Test-Path -LiteralPath $deployed)) {
        return $deployed
    }

    return $null
}

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
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/1.6.1'
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
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.1'

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

        # Formlara Pencere Simgesi Atama Enjeksiyonu
        $compileInput = (Resolve-Path -LiteralPath $buildParams.Ps1).Path
        if ($iconForBuild) {
            $iconBytes = [System.IO.File]::ReadAllBytes($iconForBuild)
            $iconBase64 = [Convert]::ToBase64String($iconBytes)
            $sourceText = [System.IO.File]::ReadAllText($compileInput)
            $iconBootstrap = @'
# PwX Studio embedded window icon bootstrap
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
try {
    if (-not $script:PwXEmbeddedIcon) {
        $script:PwXIconBytes = [Convert]::FromBase64String('__PWX_ICON_BASE64__')
        $script:PwXIconStream = New-Object System.IO.MemoryStream (,$script:PwXIconBytes)
        $script:PwXEmbeddedIcon = New-Object System.Drawing.Icon -ArgumentList $script:PwXIconStream
    }
    function Set-PwXFormIcon($targetForm) {
        try { if ($targetForm -is [System.Windows.Forms.Form] -and $script:PwXEmbeddedIcon) { $targetForm.Icon = $script:PwXEmbeddedIcon } } catch {}
    }
} catch { }
'@
            $iconBootstrap = $iconBootstrap.Replace('__PWX_ICON_BASE64__', $iconBase64)
            $formPattern = '(?m)^(\s*)(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:New-Object\s+(?:System\.Windows\.Forms\.)?Form\b[^\r\n]*|\[System\.Windows\.Forms\.Form\]::new\([^\r\n]*\))\s*$'
            $formMatches = [regex]::Matches($sourceText, $formPattern)
            if ($formMatches.Count -gt 0) {
                $patchedText = [regex]::Replace($sourceText, $formPattern, [System.Text.RegularExpressions.MatchEvaluator]{
                    param($m)
                    $indent = $m.Groups[1].Value
                    $varName = $m.Groups[2].Value
                    return $m.Value + [Environment]::NewLine + $indent + 'Set-PwXFormIcon ' + $varName + [Environment]::NewLine + $indent + $varName + '.Add_Shown({ Set-PwXFormIcon ' + $varName + ' })'
                })
                $drawingLine = '(?m)^\s*Add-Type\s+-AssemblyName\s+System\.Drawing\s*$'
                if ([regex]::IsMatch($patchedText, $drawingLine)) {
                    $patchedText = [regex]::Replace($patchedText, $drawingLine, { param($m) $m.Value + [Environment]::NewLine + $iconBootstrap }, 1)
                } else { 
                    $patchedText = $iconBootstrap + [Environment]::NewLine + $patchedText 
                }
                $tempPatchedSource = Join-Path $env:TEMP ('PwX_IconPatched_' + [guid]::NewGuid().ToString('N') + '.ps1')
                [System.IO.File]::WriteAllText($tempPatchedSource, $patchedText, (New-Object System.Text.UTF8Encoding($true)))
                $compileInput = $tempPatchedSource
                Add-Log "Pencere simgesi kaynak koda uygulandı ($($formMatches.Count) form yakalandı)."
            }
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
Add-Log "PwX Studio v1.6.2 hazır."
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
