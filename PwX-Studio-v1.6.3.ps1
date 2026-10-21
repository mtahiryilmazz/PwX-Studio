﻿﻿#Requires -Version 5.1
<#
    PwX Studio v1.6.4 - PowerShell Executable Builder
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
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.4'
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
    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.4'

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
        Title="PwX Studio v1.6.4 - PowerShell Executable Builder"
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
                            <TextBlock Text="v1.6.4" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
                        </Border>
                    </StackPanel>
                    <TextBlock x:Name="LblSubtitle" Text="PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." 
                               FontSize="13" Foreground="{DynamicResource SubTextBrush}" Margin="0,3,0,0" />
                </StackPanel>

                <!-- Açık / Koyu Tema Geçiş Anahtarı (Toggle Switch) -->
                <!-- SaÄŸ Butonlar: Dil SeÃ§ici ve Tema AnahtarÄ± -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnLangToggle" Content="ğŸŒ TR" Height="30" MinWidth="85" Padding="8,2" Margin="0,0,12,0" 
                            FontWeight="Bold" FontSize="12" ToolTip="Dili DeÄŸiÅŸtir (Ä°ngilizce'ye geÃ§ / Switch to ğŸŒ EN) (Ä°ngilizce'ye geÃ§ / Switch to English)"/>
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
        <TextBlock x:Name="LblFooter" Grid.Row="3" Text="PwX Studio v1.6.4 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
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
$script:EmbeddedPwXEngineHash = '12e96931170666b77a239c8deb54b8e1ec885306c21c10e73d97f839d64ace99'
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
        $hashFile = Join-Path $engineDir '.engine_hash'
        $existingHash = if (Test-Path -LiteralPath $hashFile) { (Get-Content -LiteralPath $hashFile -Raw -ErrorAction SilentlyContinue).Trim() } else { '' }

        # Motor zaten varsa ve hash gÃ¼ncel ise yeniden aÃ§maya gerek yok
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
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
        foreach ($entry in $zip.Entries) {
            $destPath = [System.IO.Path]::GetFullPath((Join-Path $engineDir $entry.FullName))
            # Zip Slip KorumasÄ±: Hedef dizin dÄ±ÅŸÄ±na yazma giriÅŸimlerini engelle
            if (-not $destPath.StartsWith($canonicalDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Warning "Zip Slip engellendi: $($entry.FullName)"
                continue
            }
            $parentDir = Split-Path -Parent $destPath
            if (-not (Test-Path -LiteralPath $parentDir)) {
                [System.IO.Directory]::CreateDirectory($parentDir) | Out-Null
            }
            if (-not [string]::IsNullOrEmpty($entry.Name)) {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
            }
        }
        $zip.Dispose()
        $ms.Dispose()

        [System.IO.File]::WriteAllText($hashFile, $script:EmbeddedPwXEngineHash, [System.Text.Encoding]::UTF8)

        if (Test-Path -LiteralPath $scriptPath) {
            $cfgDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio'
            if (-not (Test-Path $cfgDir)) { [System.IO.Directory]::CreateDirectory($cfgDir) | Out-Null }
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'engine_path.txt'), $scriptPath, [System.Text.Encoding]::UTF8)
            return $scriptPath
        }
    } catch {
        Write-Warning "Dahili pwxe motoru Ã§Ä±kartÄ±lamadÄ±: $_"
    }
    return $null
}

function Get-PwXEnginePath {
    param([switch]$ForceRedeploy)

    # 1. Ã–nceden kullanÄ±cÄ± tarafÄ±ndan seÃ§ilmiÅŸ doÄŸrulanmÄ±ÅŸ motor yolu
    $cfgFile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine_path.txt'
    if (-not $ForceRedeploy -and (Test-Path -LiteralPath $cfgFile)) {
        try {
            $saved = (Get-Content -LiteralPath $cfgFile -Raw).Trim()
            if ($saved -and (Test-Path -LiteralPath $saved)) {
                $norm = [System.IO.Path]::GetFullPath($saved)
                if ($norm.EndsWith('PwX-Build.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
                    return $norm
                }
            }
        } catch {}
    }

    # 2. GÃ¼venli GeliÅŸtirici Yolu ($PSScriptRoot altÄ± - Asla CWD/Get-Location kullanÄ±lmaz)
    if ($PSScriptRoot) {
        $relCandidates = @(
            (Join-Path $PSScriptRoot 'pwxe\scripts\PwX-Build.ps1'),
            (Join-Path $PSScriptRoot '..\pwxe\scripts\PwX-Build.ps1')
        )
        foreach ($c in $relCandidates) {
            if ($c -and (Test-Path -LiteralPath $c)) {
                return (Resolve-Path -LiteralPath $c).Path
            }
        }
    }

    # 3. Sistemde Resmi Kurulu PowerShell ModÃ¼lÃ¼ (PSGallery / Local ModulePath)
    try {
        $pwxeMod = Get-Module -ListAvailable pwxe -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if ($pwxeMod) {
            $modCand = Join-Path $pwxeMod.ModuleBase 'scripts\PwX-Build.ps1'
            if (Test-Path -LiteralPath $modCand) { return $modCand }
        }
    } catch {}

    # 4. Daha Ã¶nce otomatik aÃ§Ä±lmÄ±ÅŸ yerel AppData motoru (Hash kontrolÃ¼ ile)
    $appDataScript = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\scripts\PwX-Build.ps1'
    $hashFile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PwX-Studio\engine\.engine_hash'
    $hashMatches = if (Test-Path -LiteralPath $hashFile) { (Get-Content -LiteralPath $hashFile -Raw -ErrorAction SilentlyContinue).Trim() -eq $script:EmbeddedPwXEngineHash } else { $false }
    if (-not $ForceRedeploy -and $hashMatches -and (Test-Path -LiteralPath $appDataScript)) {
        return $appDataScript
    }

    # 5. Bulunamazsa veya sÃ¼rÃ¼m eskimiÅŸse: Dahili GÃ¶mÃ¼lÃ¼ Motoru Otomatik Kur
    $deployed = Deploy-EmbeddedPwXEngine -Force:$ForceRedeploy
    if ($deployed -and (Test-Path -LiteralPath $deployed)) {
        return $deployed
    }

    return $null
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
        if ($window) { $window.Title = "PwX Studio v1.6.4 - PowerShell Executable Builder" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.6.4 • PowerShell Executable Builder" }
    } else {
        if ($btnLangToggle) {
            $btnLangToggle.Content = [char]::ConvertFromUtf32(0x1F310) + " EN"
            $btnLangToggle.ToolTip = "Switch Language (Change to TÃ¼rkÃ§e)"
        }
        if ($window) { $window.Title = "PwX Studio v1.6.4 - PowerShell Executable Builder" }
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
        if ($lblFooter) { $lblFooter.Text = "PwX Studio v1.6.4 • PowerShell Executable Builder" }
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
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/1.6.4'
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
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.4'

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
Add-Log "PwX Studio v1.6.4 hazır."
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
