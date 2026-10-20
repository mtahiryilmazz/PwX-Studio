﻿﻿#Requires -Version 5.1
<#
    PwX Studio v1.6.3 - PowerShell Executable Builder
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
        Title="PwX Studio v1.6.3 - PowerShell Executable Builder"
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
                            <TextBlock Text="v1.6.3" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
                        </Border>
                    </StackPanel>
                    <TextBlock x:Name="LblSubtitle" Text="PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." 
                               FontSize="13" Foreground="{DynamicResource SubTextBrush}" Margin="0,3,0,0" />
                </StackPanel>

                <!-- Açık / Koyu Tema Geçiş Anahtarı (Toggle Switch) -->
                <!-- SaÄŸ Butonlar: Dil SeÃ§ici ve Tema AnahtarÄ± -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnLangToggle" Content="🇹🇷 TR" Height="30" MinWidth="85" Padding="8,2" Margin="0,0,12,0" 
                            FontWeight="Bold" FontSize="12" ToolTip="Dili Değiştir / Switch Language (🇹🇷 TR / 🇬🇧 EN)"/>
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
                    <TextBlock x:Name="LblConsoleTitle" Text="⚡ Canlı Konsol Günlüğü" FontSize="12" FontWeight="Bold" Foreground="#38BDF8"/>
                    <Button x:Name="BtnClearLog" Content="Temizle" HorizontalAlignment="Right" Padding="10,3" FontSize="11"/>
                </Grid>
                <TextBox x:Name="TxtConsole" Grid.Row="1" Background="{DynamicResource TerminalBgBrush}" Foreground="{DynamicResource TerminalTextBrush}" FontFamily="Cascadia Code, Consolas" FontSize="12" 
                         IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" BorderThickness="0" Padding="4"/>
            </Grid>
        </Border>

        <!-- 4. Footer (Sade ve Temiz) -->
        <TextBlock x:Name="LblFooter" Grid.Row="3" Text="PwX Studio v1.6.3 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
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

$rbConsole      = $window.FindName('RbConsole')
$lblFooter      = $window.FindName('LblFooter')
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

$script:currentLanguage = 'TR'

function Set-AppLanguage([string]$lang) {
    $script:currentLanguage = $lang
    if ($lang -eq 'EN') {
        if ($btnLangToggle) {
            $btnLangToggle.Content = "🇬🇧 EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to 🇹🇷 TR)"
        }
        if ($window) { $window.Title = "PwX Studio v1.6.3 - PowerShell Executable Builder" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.6.3 • PowerShell Executable Builder" }
    } else {
        if ($btnLangToggle) {
            $btnLangToggle.Content = "🇹🇷 TR"
            $btnLangToggle.ToolTip = "Dili Değiştir (İngilizce'ye geç / Switch to 🇬🇧 EN)"
        }
        if ($window) { $window.Title = "PwX Studio v1.6.3 - PowerShell Executable Builder" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.6.3 • PowerShell Executable Builder" }
    }
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
Add-Log "PwX Studio v1.6.3 hazır."
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
