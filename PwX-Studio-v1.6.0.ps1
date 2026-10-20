#Requires -Version 5.1
<#
    PwX Studio v1.6.0 - PowerShell Executable Builder
    - Windows 11 Modern Arayüz (Saf WPF/XAML Mimarisi)
    - Dinamik Tema Desteği: Açık Tema ve Koyu Tema geçişi
    - PowerShell 5.1 (Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Çok kaynaklı Web İkon Arama Hub'ı (Gelişmiş Türkçe/İngilizce Arama & Renk Kartelası)
    - Türkçe karakter uyumlu (UTF-8 dosya ve konsol UTF-8 çıktı motoru)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v1.6.0.ps1
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
[Net.ServicePointManager]::DefaultConnectionLimit = 16

# WPF Uygulama Yaşam Döngüsü: İkincil modal pencereler kapatıldığında ana pencerenin kapanmasını önle
if ($null -eq [System.Windows.Application]::Current) {
    $app = New-Object System.Windows.Application
    $app.ShutdownMode = [System.Windows.ShutdownMode]::OnExplicitShutdown
} else {
    [System.Windows.Application]::Current.ShutdownMode = [System.Windows.ShutdownMode]::OnExplicitShutdown
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
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.0'
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
    $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.0'

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
        Title="PwX Studio v1.6.0 - PowerShell Executable Builder"
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
                            <TextBlock Text="v1.6.0" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" />
                        </Border>
                    </StackPanel>
                    <TextBlock Text="PowerShell betiklerini (.ps1) sıfır bağımlılıkla yerel Windows çalıştırılabilir dosyalarına (.exe) dönüştürün." 
                               FontSize="13" Foreground="{DynamicResource SubTextBrush}" Margin="0,3,0,0" />
                </StackPanel>

                <!-- Açık / Koyu Tema Geçiş Anahtarı (Toggle Switch) -->
                <CheckBox x:Name="BtnThemeToggle" Grid.Column="1" Style="{StaticResource ThemeToggleSwitch}" VerticalAlignment="Center" Margin="10,0,0,0"/>
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
        <TextBlock Grid.Row="3" Text="PwX Studio v1.6.0 • PowerShell Executable Builder" FontSize="11" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
'@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
Set-WindowFitToWorkArea -Win $window -Center

# Logo ve ikon ata (Varsa)
$pwxIconCandidate = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'ico\PwX-Studio.ico' } else { '.\ico\PwX-Studio.ico' }
if (Test-Path -LiteralPath $pwxIconCandidate) {
    try {
        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new((Resolve-Path $pwxIconCandidate).Path))
    } catch {}
}

# Element Haritası
$btnThemeToggle = $window.FindName('BtnThemeToggle')
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
                    $wcSvg.Headers['User-Agent'] = 'PwX-Studio/1.6.0'
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
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.6.0'

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
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
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
        $engineScript = Get-PwXEnginePath
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
Add-Log "PwX Studio v1.6.0 hazır."
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
    if ([System.Windows.Application]::Current) {
        [System.Windows.Application]::Current.Shutdown()
    }
})

# Pencereyi Göster
[void]$window.ShowDialog()
