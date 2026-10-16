#Requires -Version 5.1
<#
    PwX Studio v1.5.0 - PowerShell Executable Builder
    - Tamamen bağımsız yerli "PwX Build Engine" kullanır (PS2EXE bağımlılığı tamamen kaldırılmıştır)
    - PowerShell 5.1 (Windows Dahili csc.exe) ve PowerShell 7 (.NET 8 SDK) hedef desteği
    - Logo: dosyadan veya çok kaynaklı web aramasıyla (Iconify, Font Awesome, Google Material, Icons8) indir; derlemede ICO'ya dönüştür
    - Türkçe karakter uyumlu (dosya UTF-8 BOM'lu kaydedilmiştir; exe konsolu UTF-8 çıktı verir)
    Çalıştırma: powershell.exe -STA -ExecutionPolicy Bypass -File .\PwX-Studio-v1.5.0.ps1
    NOT: Bu dosyayı düzenlerseniz "UTF-8 with BOM" olarak kaydedin (Türkçe karakterler için).
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
[Net.ServicePointManager]::DefaultConnectionLimit = 16

$trCulture = [System.Globalization.CultureInfo]::GetCultureInfo('tr-TR')

# Türkçe arama kelimeleri -> İngilizce (Iconify aramaları İngilizce çalışır)
$TrMap = @{
    'klasör' = 'folder'; 'klasor' = 'folder'; 'dosya' = 'file'; 'ev' = 'home'
    'ayar' = 'settings'; 'ayarlar' = 'settings'; 'kurulum' = 'install'; 'indir' = 'download'
    'kilit' = 'lock'; 'anahtar' = 'key'; 'yazıcı' = 'printer'; 'yazici' = 'printer'
    'ağ' = 'network'; 'ag' = 'network'; 'sunucu' = 'server'; 'bilgisayar' = 'computer'
    'güvenlik' = 'security'; 'guvenlik' = 'security'; 'kalkan' = 'shield'
    'kullanıcı' = 'user'; 'kullanici' = 'user'; 'sepet' = 'cart'; 'arama' = 'search'
    'kitap' = 'book'; 'okul' = 'school'; 'cami' = 'mosque'; 'dünya' = 'globe'; 'dunya' = 'globe'
    'yıldız' = 'star'; 'yildiz' = 'star'; 'kalp' = 'heart'; 'güncelle' = 'update'; 'guncelle' = 'update'
    'sil' = 'delete'; 'çöp' = 'trash'; 'cop' = 'trash'; 'veritabanı' = 'database'; 'veritabani' = 'database'
    'rapor' = 'report'; 'grafik' = 'chart'; 'belge' = 'document'; 'telefon' = 'phone'
    'kamera' = 'camera'; 'müzik' = 'music'; 'muzik' = 'music'; 'oyun' = 'game'; 'bulut' = 'cloud'
    'saat' = 'clock'; 'takvim' = 'calendar'; 'bilgi' = 'info'; 'uyarı' = 'warning'; 'uyari' = 'warning'
    'hata' = 'error'; 'onay' = 'check'; 'kod' = 'code'; 'yedek' = 'backup'; 'araç' = 'tools'
    'uygulama' = 'app'; 'paket' = 'package'; 'mağaza' = 'store'; 'magaza' = 'store'; 'yıldırım' = 'bolt'
    'harita' = 'map'; 'resim' = 'image'; 'ses' = 'volume'; 'mesaj' = 'message'; 'çevir' = 'translate'
}

# ------------------------------------------------------------------
#  C# stub: gömülü script'i geçici dosyaya çıkarıp powershell ile çalıştırır
# ------------------------------------------------------------------
$StubTemplate = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

[assembly: AssemblyTitle("__TITLE__")]
[assembly: AssemblyProduct("__TITLE__")]
[assembly: AssemblyCompany("__COMPANY__")]
[assembly: AssemblyVersion("__VER__")]
[assembly: AssemblyFileVersion("__VER__")]

static class Program
{
    static readonly bool HIDDEN = __HIDDEN__;
    static readonly bool UTF8CON = __UTF8__;

    [DllImport("kernel32.dll")] static extern uint GetConsoleOutputCP();
    [DllImport("kernel32.dll")] static extern bool SetConsoleOutputCP(uint cp);

    [STAThread]
    static int Main(string[] args)
    {
        string tmp = Path.Combine(Path.GetTempPath(), "p2e_" + Guid.NewGuid().ToString("N") + ".ps1");
        uint oldCp = 0;
        try
        {
            if (!HIDDEN && UTF8CON)
            {
                try { oldCp = GetConsoleOutputCP(); SetConsoleOutputCP(65001); } catch { }
            }

            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.ps1"))
            using (FileStream f = File.Create(tmp))
            {
                s.CopyTo(f);
            }

            StringBuilder sb = new StringBuilder();
            sb.Append("-NoProfile -ExecutionPolicy Bypass -STA -File \"" + tmp + "\"");
            foreach (string a in args)
            {
                string esc = a.Replace("\"", "\\\"");
                if (esc.EndsWith("\\")) esc += "\\";
                sb.Append(" \"" + esc + "\"");
            }

            string ps = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
            ProcessStartInfo psi = new ProcessStartInfo(ps, sb.ToString());
            psi.UseShellExecute = false;
            psi.CreateNoWindow = HIDDEN;
            psi.EnvironmentVariables["PS1EXE_DIR"] = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');

            using (Process p = Process.Start(psi))
            {
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception ex)
        {
            if (!HIDDEN) Console.Error.WriteLine(ex.Message);
            return 1;
        }
        finally
        {
            try { if (File.Exists(tmp)) File.Delete(tmp); } catch { }
            if (oldCp != 0) { try { SetConsoleOutputCP(oldCp); } catch { } }
        }
    }
}
'@

# ------------------------------------------------------------------
#  Yardımcı fonksiyonlar
# ------------------------------------------------------------------
function Find-Csc {
    $c = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (Test-Path $c) { return $c }
    $c = Join-Path $env:windir 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
    if (Test-Path $c) { return $c }
    return $null
}

function Escape-Cs([string]$t) {
    return ($t -replace '\\', '\\' -replace '"', '\"')
}

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

function Load-PreviewImage([string]$path) {
    try {
        if ([System.IO.Path]::GetExtension($path).ToLower() -eq '.ico') {
            $ico = New-Object System.Drawing.Icon $path, 64, 64
            return $ico.ToBitmap()
        }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $ms = New-Object System.IO.MemoryStream (,$bytes)
        return [System.Drawing.Image]::FromStream($ms)
    }
    catch { return $null }
}

# ---- Web ikon arama (Iconify) ----
function Convert-TrQuery([string]$q) {
    $words = $q.Trim().ToLower($trCulture) -split '\s+' | Where-Object { $_ }
    $out = foreach ($w in $words) { if ($TrMap.ContainsKey($w)) { $TrMap[$w] } else { $w } }
    return ($out -join ' ')
}

function Search-Icons([string]$query, [int]$sourceIndex, [string]$icons8ApiKey = '') {
    $script:icons8SearchWarning = $false
    $script:iconifySearchWarning = $false
    $q = Convert-TrQuery $query
    $items = New-Object System.Collections.Generic.List[object]
    $prefixes = ''
    # 0 = birleşik arama; 6 = yalnızca Icons8
    $useIcons8 = ($sourceIndex -eq 0 -or $sourceIndex -eq 6)
    switch ($sourceIndex) {
        1 { $prefixes = '' }
        2 { $prefixes = 'flat-color-icons,fluent-emoji,twemoji,noto,logos,emojione,openmoji,vscode-icons' }
        3 { $prefixes = 'mdi,tabler,lucide,ph,bi,carbon,fa6-solid' }
        4 { $prefixes = 'fa,fa6-solid,fa6-regular,fa6-brands,fa-brands' }
        5 { $prefixes = 'material-symbols,material-icon-theme,mdi' }
        6 { $useIcons8 = $true }
        default { $useIcons8 = $true }
    }

    if ($sourceIndex -ne 6) {
        try {
            $queryPart = '?query=' + [uri]::EscapeDataString($q) + '&limit=60'
            if ($prefixes) { $queryPart += '&prefixes=' + [uri]::EscapeDataString($prefixes) }
            $json = $null
            $lastError = $null
            foreach ($apiHost in @('https://api.iconify.design','https://api.simplesvg.com','https://api.unisvg.com')) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Encoding = [System.Text.Encoding]::UTF8
                    $wc.Headers['User-Agent'] = 'PwX-Studio/1.5.0'
                    $json = $wc.DownloadString($apiHost + '/search' + $queryPart) | ConvertFrom-Json
                    if ($json -and $null -ne $json.icons) { break }
                } catch { $lastError = $_.Exception.Message }
            }
            if (-not $json -or $null -eq $json.icons) { throw ('Iconify ana ve yedek API adresleri başarısız. ' + $lastError) }
            foreach ($name in @($json.icons)) {
                if ($name -match '^([^:]+):(.+)$') {
                    $items.Add([pscustomobject]@{ Name=[string]$name; Provider='Iconify'; PreviewUrl=$null; DownloadUrl=$null; License='Kaynağın lisansını kontrol edin' })
                }
            }
        } catch {
            $script:iconifySearchWarning = $true
            if ($sourceIndex -notin @(0,6)) { throw }
        }
    }

    if ($useIcons8) {
        $i8url = 'https://search.icons8.com/api/iconsets/v5/search?term=' + [uri]::EscapeDataString($q) + '&amount=40&offset=0&language=en&authors=icons8&isFree=true&spellcheck=true&suggest=true'
        $wc8 = New-Object System.Net.WebClient
        $wc8.Encoding = [System.Text.Encoding]::UTF8
        $wc8.Headers['User-Agent'] = 'PwX-Studio/1.5.0'
        if ($icons8ApiKey) { $wc8.Headers['Api-Key'] = $icons8ApiKey }
        try {
            $j8 = $wc8.DownloadString($i8url) | ConvertFrom-Json
            foreach ($ic in @($j8.icons)) {
                if ($ic.previewUrl) {
                    $prev = [string]$ic.previewUrl
                    $down = $prev -replace 'size=\d+', 'size=256'
                    $items.Add([pscustomobject]@{ Name=('Icons8: ' + [string]$ic.name); Provider='Icons8'; PreviewUrl=$prev; DownloadUrl=$down; License=($(if ($ic.isFree) {'Ücretsiz koşulları/atıf şartını kontrol edin'} else {'Lisans gerekebilir'})) })
                }
            }
        } catch {
            $script:icons8SearchWarning = $true
            if ($sourceIndex -eq 6) { throw ('Icons8 araması başarısız. API anahtarı veya ağ bağlantısını kontrol edin. Ayrıntı: ' + $_.Exception.Message) }
        }
    }
    return @{ Query = $q; Icons = @($items | Select-Object -First 80) }
}

function Get-IconSvgUrl($item, [int]$size, [string]$hex) {
    $parts = ([string]$item.Name).Split(':', 2)
    if ($parts.Count -ne 2) { throw "Geçersiz Iconify ikon adı: $($item.Name)" }
    $url = "https://api.iconify.design/$($parts[0])/$($parts[1]).svg?height=$size"
    if ($hex) { $url += '&color=%23' + $hex }
    return $url
}

function Get-IconPngCandidates($item, [int]$size, [string]$hex) {
    if ($item.Provider -eq 'Icons8') {
        $u = [string]$item.DownloadUrl
        if (-not $u) { $u = [string]$item.PreviewUrl }
        return @($u | Where-Object { $_ })
    }
    $parts = ([string]$item.Name).Split(':', 2)
    if ($parts.Count -ne 2) { throw "Geçersiz Iconify ikon adı: $($item.Name)" }
    $prefix = $parts[0]; $iconName = $parts[1]
    $urls = New-Object System.Collections.Generic.List[string]
    foreach ($apiHost in @('https://api.iconify.design','https://api.simplesvg.com','https://api.unisvg.com')) {
        $svg = $apiHost + '/' + $prefix + '/' + $iconName + '.svg?height=' + $size
        if ($hex) { $svg += '&color=%23' + $hex }
        $encoded = [uri]::EscapeDataString($svg)
        # SVG->PNG proxy'leri sırayla denenir; tek sağlayıcıdaki arıza indirmeyi durdurmaz.
        $urls.Add("https://images.weserv.nl/?url=$encoded&output=png&w=$size&h=$size&fit=contain")
        $urls.Add("https://wsrv.nl/?url=$encoded&output=png&w=$size&h=$size&fit=contain")
    }
    return @($urls.ToArray())
}

function Get-IconResultPngUrl($item, [int]$size, [string]$hex) {
    return @((Get-IconPngCandidates $item $size $hex))[0]
}

function Get-IconResultFallbackPngUrl($item, [int]$size, [string]$hex) {
    $c = @(Get-IconPngCandidates $item $size $hex)
    if ($c.Count -gt 1) { return $c[1] }
    return $c[0]
}

function Test-ImageFile([string]$path) {
    try {
        $fs = [System.IO.File]::OpenRead($path)
        try { $img = [System.Drawing.Image]::FromStream($fs, $true, $true); $null = $img.Width; $img.Dispose() }
        finally { $fs.Dispose() }
        return $true
    } catch { return $false }
}

function Save-NormalizedPng([string]$source, [string]$destination) {
    $fs = [System.IO.File]::OpenRead($source)
    try {
        $img = [System.Drawing.Image]::FromStream($fs, $true, $true)
        try {
            $bmp = New-Object System.Drawing.Bitmap 256, 256, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                try {
                    $g.Clear([System.Drawing.Color]::Transparent)
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $scale = [Math]::Min(240.0 / $img.Width, 240.0 / $img.Height)
                    $w = [Math]::Max(1, [int][Math]::Round($img.Width * $scale))
                    $h = [Math]::Max(1, [int][Math]::Round($img.Height * $scale))
                    $g.DrawImage($img, [int]((256-$w)/2), [int]((256-$h)/2), $w, $h)
                } finally { $g.Dispose() }
                $bmp.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $bmp.Dispose() }
        } finally { $img.Dispose() }
    } finally { $fs.Dispose() }
}

function Get-ColorHex([System.Drawing.Color]$c) {
    return ('{0:X2}{1:X2}{2:X2}' -f $c.R, $c.G, $c.B)
}

# ------------------------------------------------------------------
#  Ana pencere
# ------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PwX Studio v1.5.0'
$form.Size = New-Object System.Drawing.Size(880, 915)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MinimumSize = New-Object System.Drawing.Size(880, 915)
$form.MaximumSize = New-Object System.Drawing.Size(880, 915)
$form.MaximizeBox = $false
# Sabit piksel yerleşimi: ilk açılışta DPI/font otomatik ölçeklemesi kontrolleri kaydırmasın.
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
$form.AutoScroll = $false
$form.AutoScrollMinSize = [System.Drawing.Size]::Empty
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$form.ForeColor = [System.Drawing.Color]::FromArgb(32, 36, 42)

function Add-Label([string]$text, [int]$x, [int]$y, $parent = $form) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.AutoSize = $true
    $parent.Controls.Add($l)
    return $l
}
function Add-Text([int]$x, [int]$y, [int]$w, $parent = $form) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point($x, $y)
    $t.Size = New-Object System.Drawing.Size($w, 24)
    $parent.Controls.Add($t)
    return $t
}
function Add-Button([string]$text, [int]$x, [int]$y, [int]$w, $parent = $form) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, 26)
    $parent.Controls.Add($b)
    return $b
}

# Modern tema altyapisi (Windows PowerShell 5.1 ile uyumlu)
$script:currentTheme = 'Açık'
function Apply-Theme($root, [string]$theme) {
    $dark = ($theme -eq 'Koyu')
    if ($dark) {
        $bg = [System.Drawing.Color]::FromArgb(30, 32, 36)
        $surface = [System.Drawing.Color]::FromArgb(41, 44, 50)
        $inputBg = [System.Drawing.Color]::FromArgb(24, 26, 30)
        $fg = [System.Drawing.Color]::FromArgb(238, 240, 244)
        $muted = [System.Drawing.Color]::FromArgb(180, 186, 196)
        $border = [System.Drawing.Color]::FromArgb(68, 73, 82)
        $buttonBg = [System.Drawing.Color]::FromArgb(53, 58, 67)
    } else {
        $bg = [System.Drawing.Color]::FromArgb(245, 247, 250)
        $surface = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $inputBg = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $fg = [System.Drawing.Color]::FromArgb(32, 36, 42)
        $muted = [System.Drawing.Color]::FromArgb(90, 98, 110)
        $border = [System.Drawing.Color]::FromArgb(218, 223, 230)
        $buttonBg = [System.Drawing.Color]::FromArgb(235, 239, 245)
    }
    $root.BackColor = $bg
    $root.ForeColor = $fg
    foreach ($c in $root.Controls) {
        $c.ForeColor = $fg
        if ($c -is [System.Windows.Forms.TextBox]) {
            $c.BackColor = $inputBg
            $c.BorderStyle = 'FixedSingle'
        } elseif ($c -is [System.Windows.Forms.ComboBox]) {
            $c.BackColor = $inputBg
        } elseif ($c -is [System.Windows.Forms.Button]) {
            $c.FlatStyle = 'Flat'
            $c.FlatAppearance.BorderColor = $border
            $c.FlatAppearance.BorderSize = 1
            $c.UseVisualStyleBackColor = $false
            $c.BackColor = $buttonBg
            $c.Cursor = [System.Windows.Forms.Cursors]::Hand
            if ($c.Name -eq 'btnThemeToggle') {
                $c.FlatAppearance.BorderSize = 0
                $c.FlatAppearance.MouseDownBackColor = $bg
                $c.FlatAppearance.MouseOverBackColor = $bg
                $c.BackColor = $bg
            }
            if ($c.Name -eq 'btnBuild' -or $c.Text -eq 'EXE OLUŞTUR') {
                $c.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
                $c.ForeColor = [System.Drawing.Color]::White
                $c.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 100, 190)
            }
        } elseif ($c -is [System.Windows.Forms.GroupBox]) {
            $c.BackColor = $bg
            $c.ForeColor = $fg
        } elseif ($c -is [System.Windows.Forms.PictureBox]) {
            $c.BackColor = $surface
            $c.BorderStyle = 'FixedSingle'
        } elseif ($c -is [System.Windows.Forms.Label]) {
            $c.BackColor = [System.Drawing.Color]::Transparent
            $c.ForeColor = $muted
        } else {
            $c.BackColor = $bg
        }
        if ($c.Controls.Count -gt 0) { Apply-Theme $c $theme }
    }
}

# Tema anahtarı: Lucide sun/moon çizim dilinden esinlenen, bağımlılıksız switch.
# Resmî SVG kaynakları:
# https://lucide.dev/icons/sun
# https://lucide.dev/icons/moon
# WinForms GDI+ SVG dosyasını yerel olarak çizmediğinden, aynı 24x24 Lucide çizgi geometrisi
# çevrimdışı olarak vektörel çizilir; harici DLL, font veya ağ bağlantısı gerekmez.
function Get-LucideThemeBitmap([string]$name) {
    # Resmî Lucide SVG şekilleri çevrimdışı PNG kaynaklarına gömülüdür; ağ erişimi gerekmez.
    $encoded = switch ($name) {
        'sun' { 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAGvElEQVR4nO2bT2wUVRzHP29229A/GAkSg4AWykGIFtpuuxCKCQGMIaKYmMZ40MjFA1yM3S60HsYESrqLmihcAQ0JsV4gKB7QcLBitzttqaRBDxQEwUAkmMB2kXbneehAtrPT2ZnZ2S6RfpMe9veb93vf95vfvL73+70Hs5hFyTCiUj6iUl5KDkqpOh6I0ZGu4na6itsDMTpKxUOUolMtThjoM4nXhCIkZppLaSJA8KIj2QygJA4QFv1ayWYCJZsDHhXMOqDUBEqNoNsGQ/uomQhSfek5LrS2kvHSqQTdicwpenoILP2DFcEJ7tbv5rKbtq4iQIvTlQkyKuD8ssv0JrqY74qpAZnhVycyJ0h0MX/ZZXoFnM8EGdXidLlp73gdkIizNAAXTW2GM+NsDHdwy02nAFqc3cBHxs89oQj73NpIdDE/UMaPwKosscxAbTjCJSc2HEeAovAkuQ5bFSjjRy+REIqwryLFvIoU83wcPIAwuDqC4wiQKopWRa+AtRZqz5HgBTaDR8IvoRQtQnU2pziOAKGi6+NsBYYt1KsC5Zzq6SHg1J5X9PQQCJRzCovBA8P6OFudDh5cToLhDm5lxtmIlRMkzcuvsM6NPS9YfoV1SJotVJ6i0PU6wM4JElJu7bnFNH14/gQ9LYQeOEFAMovY0cY2BtzY8ZIPaGxjQMLRB78FJAuZfwraDp9RCVZXEhaQDrUzaPesVFGSc1mj6LwGbEayCMHTk0puILgGnFbgRH2KRL7vWIvRIKHi7hiJDSoTXscwI/mAZJxNAmJAvaMGghF0Pg61801xmRXZAcNxqsbhCPCmRxM9pHgvpDLmI60pKJoD+rpZHFT4Fut/V24wpOi82hDluh+8zCiKA0YOUp0eoxf7wV+TcMUg8SywyObZIVK0FCMSXO8GneDeGEewHvyYEBzQMxxqivJ7tkLbz/NSsl3ATqDC1K5eVnMIeMtvrr5HwECMV6TgewvVucAEb+TbrhqbruNAnVknBS83tXHaJ6qAzwkRqaJIYbmxGb6n85KTvXo4wqV7Oi2Quz0Wkm4p/X1pvjpgqIowsNokHgtMsK0lyh2ndlqi3MnANiBtUtUPfkq4UJ7Z8NUBOrxuIf7CbZYGJiMBOGiWS2nZh2fkTILJbpqVQM5bBEDPcK4pSr+Nvc1mgdQ57JWcIjisS9qm2JNsAnZP18Yt/ynfUzJOp4A9dqSEpLOx3TrtpMW5CSzIEv0ZirDEzl4+aHGuAwuzRDdDEWMJbYIX/g8/gTMqQQGd+QhJQecZNTdyjE3NU1Oehav57DnAFdPvBVYbKK/8fZsD0guRgMyWCT9mbJFjQxp9+YKHDtigMiFhb14+kr1Wu6/Q+4yDaUsqCgt/ACSLTZK/jb6mwCv/nDdUyCSoxdGAxqk9siLUxm/5iFlhcD8rdclItkyC1hShabo2bvnnfMvGA3YzvR1+wOQAKdkOtHsxputsN78igf1K0C1/X9cBCpwwywTsTMRZ6taWFqMWwQ4LVU4fhcBXB9SnSADnTOKKABzv7WauUzt9n/MEguPAHJNqsLHNc3RawlcHCBUdSdRCVTdHoTf5Gcvy2dBi1Ab/5WfgBbNOUWgXwr//AFCkfIAW52ug1UKVlnBA0TncGOVCtmJwPyuNb34HuW8eJMdC7bztN9eiOMBIhf2EfQ7wL8nkHkFADVNXe2YMkmJ9MRIiRUuJDXbzjD6ZEnOWCLUxpehsLVZKrGgHJBqiXC+D9UCPZyOSY6RYX6zBw8ymxbuBBkcNBCNIoqEI3xWXmQ+Fkaq5NAtIN33IkN2zUkUZqKIJwTYp2SQkS4zCiARuCLgqJxdSJxpTJPMVRpKfUC+hInWH/pIURhJdzA+UcyqrUPlVKMK7bmyMqJSnFyKt1vZ20OJ8CbwDgKA/c58tM1oam7Y+L2nMVyIrFFqMBkRODXLmiqN2hxMEVLm15xbT9OH5pIorB9gNHkH/xRrOuiXgFhdrOIuwXA57coJjB0gVRSnjJNOczMjcZ4vXY3Nu0NpKJnOfLUxzUkUp46RUXZx9cvrgQCWr/T4f5PW+gN0hDQFrByqt8wFWcB4BZfwDORsRz4Mv9L6AjROkwdURHDug6QNGmazxTzpB0lfAGcGwFOwFKoFKKdhr3CFwhYdOkA/vHkggZnB1BFeTYCjCrgzUEqButIYWz8fifLwvEO7g1mgNLQSoy0BtKMIuN+1dV4ednsC0gwDF/C0Vcl/AmHzPe2n72J8Wn3VAqQmUGiVxgN/3BQpBaRzg432BQlESBxjFiw5gzPjryFN2/3/iUbg6O4vHHf8B8Nl2l+cs7WwAAAAASUVORK5CYII=' }
        'moon' { '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' }
        default { throw "Bilinmeyen tema ikonu: $name" }
    }
    $bytes = [Convert]::FromBase64String($encoded)
    $ms = New-Object System.IO.MemoryStream (,$bytes)
    try {
        $img = [System.Drawing.Image]::FromStream($ms)
        try { return New-Object System.Drawing.Bitmap $img } finally { $img.Dispose() }
    } finally { $ms.Dispose() }
}

function Paint-ThemeSwitch($sender, $eventArgs) {
    $g = $eventArgs.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    # Butonun arka planını temizleme; WinForms'un çizdiği arka plan korunur.
    $darkNow = ($script:currentTheme -eq 'Koyu')
    $track = if ($darkNow) { [System.Drawing.Color]::FromArgb(48, 112, 210) } else { [System.Drawing.Color]::FromArgb(215, 222, 232) }
    $knob = if ($darkNow) { [System.Drawing.Color]::FromArgb(248, 250, 252) } else { [System.Drawing.Color]::White }
    $icon = if ($darkNow) { [System.Drawing.Color]::FromArgb(58, 72, 94) } else { [System.Drawing.Color]::FromArgb(204, 139, 0) }
    $w = $sender.ClientSize.Width
    $h = $sender.ClientSize.Height
    $trackH = [single]([Math]::Min(30, $h - 8))
    $trackW = [single]([Math]::Min(68, $w - 8))
    $tx = [single](($w - $trackW) / 2)
    $ty = [single](($h - $trackH) / 2)
    $trackPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = $trackH / 2
    $trackPath.AddArc($tx, $ty, $trackH, $trackH, 90, 180)
    $trackPath.AddArc(($tx + $trackW - $trackH), $ty, $trackH, $trackH, 270, 180)
    $trackPath.CloseFigure()
    $brush = New-Object System.Drawing.SolidBrush($track)
    try { $g.FillPath($brush, $trackPath) } finally { $brush.Dispose(); $trackPath.Dispose() }
    $knobSize = [single]($trackH - 4)
    $knobX = if ($darkNow) { $tx + $trackW - $knobSize - 2 } else { $tx + 2 }
    $knobY = $ty + 2
    $knobBrush = New-Object System.Drawing.SolidBrush($knob)
    try { $g.FillEllipse($knobBrush, $knobX, $knobY, $knobSize, $knobSize) } finally { $knobBrush.Dispose() }
    $iconSize = [single]($knobSize * 0.58)
    $ix = $knobX + ($knobSize - $iconSize) / 2
    $iy = $knobY + ($knobSize - $iconSize) / 2
    $iconImage = if ($darkNow) { $script:moonThemeBitmap } else { $script:sunThemeBitmap }
    if ($iconImage) { $g.DrawImage($iconImage, [single]$ix, [single]$iy, [single]$iconSize, [single]$iconSize) }
    if ($sender.Focused) {
        $focusPen = New-Object System.Drawing.Pen([System.Drawing.SystemColors]::Highlight, 1)
        try { $g.DrawRectangle($focusPen, 1, 1, $w - 3, $h - 3) } finally { $focusPen.Dispose() }
    }
}
$script:sunThemeBitmap = Get-LucideThemeBitmap 'sun'
$script:moonThemeBitmap = Get-LucideThemeBitmap 'moon'
$btnThemeToggle = New-Object System.Windows.Forms.Button
$btnThemeToggle.Name = 'btnThemeToggle'
$btnThemeToggle.Location = New-Object System.Drawing.Point(730, 8)
$btnThemeToggle.Size = New-Object System.Drawing.Size(76, 40)
$btnThemeToggle.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnThemeToggle.Text = ''
$btnThemeToggle.FlatStyle = 'Flat'
$btnThemeToggle.FlatAppearance.BorderSize = 0
$btnThemeToggle.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Transparent
$btnThemeToggle.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::Transparent
$btnThemeToggle.BackColor = [System.Drawing.Color]::Transparent
$btnThemeToggle.UseVisualStyleBackColor = $false
$btnThemeToggle.TabStop = $true
$btnThemeToggle.AccessibleRole = [System.Windows.Forms.AccessibleRole]::CheckButton
$btnThemeToggle.AccessibleName = 'Tema anahtarı'
$btnThemeToggle.AccessibleDescription = 'Açık ve koyu tema arasında geçiş yapar. Açık tema için güneş, koyu tema için ay simgesi.'
$btnThemeToggle.Add_Paint({ param($s, $e) Paint-ThemeSwitch $s $e })
$form.Controls.Add($btnThemeToggle)

# PwX Studio marka başlığı: sabit üst şerit, ana form yerleşimini değiştirmez.
$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Name = 'lblPwXBrand'
$lblBrand.Text = 'PwX Studio'
$lblBrand.Location = New-Object System.Drawing.Point(15, 10)
$lblBrand.AutoSize = $true
$lblBrand.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 15, [System.Drawing.FontStyle]::Bold)
$lblBrand.ForeColor = [System.Drawing.Color]::FromArgb(74, 119, 245)
$lblBrand.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($lblBrand)
$lblBrand.BringToFront()
$btnThemeToggle.BringToFront()
$script:themeTip = New-Object System.Windows.Forms.ToolTip
$script:themeTip.SetToolTip($btnThemeToggle, 'Koyu temaya geç')
$btnThemeToggle.Add_Click({
    if ($script:currentTheme -eq 'Koyu') { $script:currentTheme = 'Açık' } else { $script:currentTheme = 'Koyu' }
    Apply-Theme $form $script:currentTheme
    if ($lblBrand) { $lblBrand.ForeColor = [System.Drawing.Color]::FromArgb(74, 119, 245) }
    $btnThemeToggle.AccessibleDescription = if ($script:currentTheme -eq 'Koyu') { 'Koyu tema etkin. Açık temaya geçmek için anahtara basın.' } else { 'Açık tema etkin. Koyu temaya geçmek için anahtara basın.' }
    $script:themeTip.SetToolTip($btnThemeToggle, $(if ($script:currentTheme -eq 'Koyu') { 'Açık temaya geç' } else { 'Koyu temaya geç' }))
    $btnThemeToggle.Invalidate()
})

# PS1 dosyası
[void](Add-Label 'PS1 dosyası:' 15 45)
$txtPs1 = Add-Text 15 65 530
$btnPs1 = Add-Button 'Gözat...' 555 64 90
$txtPs1.AllowDrop = $true

# Logo
[void](Add-Label 'Logo (PNG / JPG / BMP / ICO) - isteğe bağlı:' 15 102)
$txtLogo = Add-Text 15 122 435
$btnLogo = Add-Button 'Gözat...' 455 121 90
$btnWeb  = Add-Button 'Web''den Ara' 555 121 90
$pic = New-Object System.Windows.Forms.PictureBox
$pic.Location = New-Object System.Drawing.Point(560, 155)
$pic.Size = New-Object System.Drawing.Size(80, 80)
$pic.SizeMode = 'Zoom'
$pic.BorderStyle = 'FixedSingle'
$form.Controls.Add($pic)

# Çıktı
[void](Add-Label 'Çıktı EXE:' 15 159)
$txtOut = Add-Text 15 179 440
$btnOut = Add-Button 'Farklı kaydet...' 465 178 90

# Bilgiler
[void](Add-Label 'Uygulama adı:' 15 220)
$txtTitle = Add-Text 15 240 250
[void](Add-Label 'Sürüm:' 285 220)
$txtVer = Add-Text 285 240 100
$txtVer.Text = '1.0.0.0'
[void](Add-Label 'Şirket / Yayıncı:' 15 275)
$txtCompany = Add-Text 15 295 370

# Hedef Çalışma Zamanı — PwX Build Engine
$grpTarget = New-Object System.Windows.Forms.GroupBox
$grpTarget.Text = 'Hedef Çalışma Zamanı (PwX Build Engine)'
$grpTarget.Location = New-Object System.Drawing.Point(15, 332)
$grpTarget.Size = New-Object System.Drawing.Size(650, 56)
$form.Controls.Add($grpTarget)

$rbTargetPS51 = New-Object System.Windows.Forms.RadioButton
$rbTargetPS51.Text = 'PowerShell 5.1 (Dahili csc.exe)'
$rbTargetPS51.Location = New-Object System.Drawing.Point(15, 22)
$rbTargetPS51.Size = New-Object System.Drawing.Size(220, 22)
$rbTargetPS51.Checked = $true
$grpTarget.Controls.Add($rbTargetPS51)

$rbTargetPS7 = New-Object System.Windows.Forms.RadioButton
$rbTargetPS7.Text = 'PowerShell 7.4+ (.NET 8 SDK)'
$rbTargetPS7.Location = New-Object System.Drawing.Point(245, 22)
$rbTargetPS7.Size = New-Object System.Drawing.Size(210, 22)
$grpTarget.Controls.Add($rbTargetPS7)

$chkSingleFile = New-Object System.Windows.Forms.CheckBox
$chkSingleFile.Text = 'Tek Dosya (Single-File)'
$chkSingleFile.Location = New-Object System.Drawing.Point(465, 22)
$chkSingleFile.Size = New-Object System.Drawing.Size(170, 22)
$chkSingleFile.Checked = $false
$chkSingleFile.Enabled = $false
$grpTarget.Controls.Add($chkSingleFile)

$rbTargetPS7.Add_CheckedChanged({
    $chkSingleFile.Enabled = $rbTargetPS7.Checked
})

# Seçenekler — sabit iki sütunlu hizalı düzen
$grp = New-Object System.Windows.Forms.GroupBox
$grp.Text = 'Seçenekler'
$grp.Location = New-Object System.Drawing.Point(15, 396)
$grp.Size = New-Object System.Drawing.Size(650, 246)
$form.Controls.Add($grp)

# Ana uygulama türü: tam satır, aynı başlangıç ve genişlik
$rbConsole = New-Object System.Windows.Forms.RadioButton
$rbConsole.Text = 'Konsol uygulaması (Write-Host / Read-Host kullanan scriptler)'
$rbConsole.Location = New-Object System.Drawing.Point(15, 22)
$rbConsole.Size = New-Object System.Drawing.Size(610, 22)
$rbConsole.AutoSize = $false
$rbConsole.Checked = $true
$grp.Controls.Add($rbConsole)

$rbWin = New-Object System.Windows.Forms.RadioButton
$rbWin.Text = 'Pencereli uygulama (konsol gizli - WinForms / WPF / sessiz scriptler)'
$rbWin.Location = New-Object System.Drawing.Point(15, 46)
$rbWin.Size = New-Object System.Drawing.Size(610, 22)
$rbWin.AutoSize = $false
$grp.Controls.Add($rbWin)

# Seçenekler iki sütuna ayrıldı. Kontroller aynı genişlik ve satır aralığını kullanır.
function Add-OptionCheckBox([string]$text, [int]$x, [int]$y, [string]$variableName, [bool]$checked = $false, [bool]$enabled = $true) {
    $control = New-Object System.Windows.Forms.CheckBox
    $control.Text = $text
    $control.Location = New-Object System.Drawing.Point($x, $y)
    $control.Size = New-Object System.Drawing.Size(300, 22)
    $control.AutoSize = $false
    $control.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $control.Checked = $checked
    $control.Enabled = $enabled
    $grp.Controls.Add($control)
    Set-Variable -Name $variableName -Value $control -Scope 1
}

Add-OptionCheckBox 'Yönetici yetkisi (UAC)'                  15  72 'chkAdmin'
Add-OptionCheckBox '$ScriptRoot / $PSScriptRoot desteği'   320  72 'chkRoot' $true $false
Add-OptionCheckBox 'Konsol UTF-8 (Türkçe karakterler)'       15  96 'chkUtf8' $true
Add-OptionCheckBox 'Standart çıktıyı bastır'                320  96 'chkNoOutput'
Add-OptionCheckBox '32-bit (x86)'                            15 120 'chkX86'
Add-OptionCheckBox '64-bit (x64)'                           320 120 'chkX64' $true
Add-OptionCheckBox 'Unicode konsol'                          15 144 'chkUnicode'
Add-OptionCheckBox 'EXE.config (DPI / uyumluluk)'           320 144 'chkConfig'
Add-OptionCheckBox 'DPI farkındalığı'                        15 168 'chkDpi'
Add-OptionCheckBox 'WinForms DPI (config gerekli)'          320 168 'chkWinFormsDpi'
Add-OptionCheckBox 'Yeni Windows sürüm bilgisi'              15 192 'chkSupportOS'
Add-OptionCheckBox 'Uzun dosya yolları'                    320 192 'chkLongPaths'
Add-OptionCheckBox 'Hata ayıklama hazırlığı'                 15 216 'chkPrepareDebug'

# Secenekler icin aciklama balonlari (fareyle uzerine gelince)
$optionTips = New-Object System.Windows.Forms.ToolTip
$optionTips.AutoPopDelay = 15000
$optionTips.InitialDelay = 350
$optionTips.ReshowDelay = 150
$optionTips.ShowAlways = $true
$optionTips.IsBalloon = $true
$optionTips.ToolTipTitle = 'Bu seçenek ne işe yarar?'
$optionTipMap = @{
    $rbConsole = 'Konsol kullanan scriptler için seçin. Write-Host, Read-Host ve konsol mesajları görünür kalır.'
    $rbWin = 'Konsol penceresini gizler. WinForms/WPF arayüzleri veya arka planda sessiz çalışan scriptler için uygundur.'
    $chkAdmin = 'EXE açılırken Windows UAC yönetici izni ister. Yalnızca yönetici yetkisi gerektiren işlemler için etkinleştirin.'
    $rbTargetPS51 = 'PowerShell 5.1: Windows dahili csc.exe derleyicisiyle derler. Hedef makinede PowerShell 5.1 gerektirir; harici SDK gerektirmez.'
    $rbTargetPS7 = 'PowerShell 7.4+: Microsoft.PowerShell.SDK ve .NET 8 kullanarak modern PowerShell 7 ortamı için bağımsız EXE üretir.'
    $chkSingleFile = 'Tüm PS7 ve .NET bağımlılıklarını tek bir bağımsız .exe dosyasında paketler.'
    $chkRoot = 'ScriptRoot ve PSScriptRoot değişkenlerinin EXE içindeki script klasörünü göstermesini sağlar. Sabit olarak etkin.'
    $chkUtf8 = 'Konsol metinlerinin UTF-8 kodlamasıyla gösterilmesini sağlar; Türkçe karakterlerin bozulma riskini azaltır.'
    $chkX86 = '32-bit Windows/uyumluluk hedefi için 32-bit EXE üretir. x64 ile aynı anda seçmeyin.'
    $chkX64 = '64-bit Windows için 64-bit EXE üretir. Modern Windows sistemlerinde genellikle önerilen seçenektir.'
    $chkUnicode = 'Konsolun Unicode karakterleri göstermesine yardımcı olur. Özellikle farklı diller ve özel karakterler içeren konsol uygulamalarında kullanılır.'
    $chkConfig = 'EXE yanında .config dosyası oluşturur. DPI ve bazı Windows uyumluluk ayarlarını yapılandırmak için kullanılır.'
    $chkDpi = 'Uygulamanın yüksek DPI/ölçeklendirme farkındalığını belirtir; farklı ekran ölçeklerinde arayüzün daha doğru boyutlanmasına yardımcı olabilir.'
    $chkWinFormsDpi = 'WinForms arayüzü için DPI davranışını yapılandırır. Bu seçeneğin etkili olması için EXE.config oluşturma seçeneği de gerekir.'
    $chkSupportOS = 'Derlenen uygulamanın Windows sürüm bilgisini modern sürümlerde doğru algılamasına yönelik uyumluluk ayarını ekler.'
    $chkLongPaths = 'Uzun dosya yollarıyla çalışmaya yönelik derleyici/uyumluluk seçeneğini etkinleştirir. Her uygulama veya Windows bileşeninde tek başına uzun yol desteği garantilemez.'
    $chkPrepareDebug = 'Hata ayıklamayı kolaylaştıracak hazırlık seçeneklerini etkinleştirir. Son kullanıcıya dağıtılan sürümde genellikle gerekmez.'
    $chkNoOutput = 'Standart konsol çıktısını bastırır. Çıktı mesajlarını görmek istediğiniz veya konsol kullanan scriptlerde etkinleştirmeyin.'
}
foreach ($control in $optionTipMap.Keys) {
    $optionTips.SetToolTip($control, $optionTipMap[$control])
}

# Derle
$btnBuild = Add-Button 'EXE OLUŞTUR' 15 565 650
$btnBuild.Height = 36
$btnBuild.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

# Log
$log = New-Object System.Windows.Forms.TextBox
$log.Location = New-Object System.Drawing.Point(15, 609)
$log.Size = New-Object System.Drawing.Size(650, 150)
$log.Multiline = $true
$log.ScrollBars = 'Vertical'
$log.ReadOnly = $true
$log.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($log)

# PwX Studio: 870x825 sabit pencere yerleşimi; ana formda kaydırma kapalı
$txtPs1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$btnPs1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$txtLogo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$btnLogo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnWeb.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$pic.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$txtOut.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$btnOut.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$txtCompany.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$grpTarget.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$grp.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$btnBuild.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$log.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom

# İlk açılış ve son yerleşim için tek, idempotent düzen fonksiyonu.
# Form gösterildikten sonra çağrılarak WinForms'un ilk ölçüm/yerleşim işlemlerinin
# kontrollerin konumlarını ezmesi engellenir.
function Set-MainLayout {
    if ($form.IsDisposed -or -not $form.IsHandleCreated) { return }
    $form.SuspendLayout()
    try {
        $clientW = $form.ClientSize.Width
        $clientH = $form.ClientSize.Height
        $left = 15
        $right = $clientW - 15
        $usableW = [Math]::Max(650, $right - $left)

        $btnThemeToggle.Left = [Math]::Max($left, $right - $btnThemeToggle.Width)
        $btnPs1.Left = [Math]::Max($left, $right - $btnPs1.Width)
        $txtPs1.Width = [Math]::Max(160, $btnPs1.Left - $txtPs1.Left - 10)

        $btnWeb.Left = [Math]::Max($left, $right - $btnWeb.Width)
        $btnLogo.Left = [Math]::Max($left, $btnWeb.Left - $btnLogo.Width - 8)
        $txtLogo.Width = [Math]::Max(160, $btnLogo.Left - $txtLogo.Left - 10)

        $pic.Left = [Math]::Max($left, $right - $pic.Width)
        $btnOut.Left = [Math]::Max($left, $right - $btnOut.Width - 95)
        $txtOut.Width = [Math]::Max(160, $btnOut.Left - $txtOut.Left - 10)
        $txtCompany.Width = [Math]::Max(160, $right - $txtCompany.Left)

        $grpTarget.Top = 332
        $grpTarget.Width = $usableW
        $grp.Top = $grpTarget.Bottom + 8
        $grp.Height = 246
        $grp.Width = $usableW
        $btnBuild.Top = $grp.Bottom + 12
        $btnBuild.Width = $usableW
        $log.Top = $btnBuild.Bottom + 8
        $log.Width = $usableW
        $log.Height = [Math]::Max(80, $clientH - $log.Top - 15)
        $log.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
        $form.AutoScroll = $false
        $form.AutoScrollMinSize = [System.Drawing.Size]::Empty
        if ($btnThemeToggle -and -not $btnThemeToggle.IsDisposed) { $btnThemeToggle.Invalidate() }
    } finally {
        $form.ResumeLayout($true)
    }
}

$form.Add_Resize({ Set-MainLayout; if ($lblBrand) { $lblBrand.ForeColor = [System.Drawing.Color]::FromArgb(74, 119, 245) } })
$form.Add_Shown({
    # Shown olayı, ilk DPI/font/layout ölçümleri bittikten sonra çalışır.
    Set-MainLayout
    $form.BeginInvoke([Action]{ Set-MainLayout }) | Out-Null
})

$form.Add_FormClosed({
    if ($script:sunThemeBitmap) { $script:sunThemeBitmap.Dispose(); $script:sunThemeBitmap = $null }
    if ($script:moonThemeBitmap) { $script:moonThemeBitmap.Dispose(); $script:moonThemeBitmap = $null }
})

function Write-Log([string]$m) {
    $log.AppendText($m + [Environment]::NewLine)
    [System.Windows.Forms.Application]::DoEvents()
}

# ------------------------------------------------------------------
#  Web ikon arama penceresi
# ------------------------------------------------------------------
$script:iconColor = [System.Drawing.Color]::FromArgb(0x1F, 0x6F, 0xEB)
$script:selName   = $null
$script:selBox    = $null
$script:pickedFile = $null

function Open-IconSiteSearch([string]$site, [string]$query) {
    if ([string]::IsNullOrWhiteSpace($query)) {
        [void][System.Windows.Forms.MessageBox]::Show('Önce aranacak ikon kelimesini yazın.', 'İkon arama')
        return
    }
    $q = [uri]::EscapeDataString((Convert-TrQuery $query))
    switch ($site) {
        'Flaticon' { $url = 'https://www.flaticon.com/search?word=' + $q }
        'Magnific' { $url = 'https://www.magnific.com/icons?query=' + $q }
        default { return }
    }
    try { Start-Process $url; $lblStatus.Text = $site + ' araması tarayıcıda açıldı. İndirme ve lisans koşulları site üzerinden tamamlanır.' }
    catch { [void][System.Windows.Forms.MessageBox]::Show('Tarayıcı açılamadı: ' + $_.Exception.Message, 'Hata') }
}

$dlg = New-Object System.Windows.Forms.Form
$dlg.Text = 'Web''den İkon Ara (Çoklu Kaynak)'
$dlg.Size = New-Object System.Drawing.Size(760, 610)
$dlg.StartPosition = 'CenterParent'
$dlg.FormBorderStyle = 'FixedDialog'
$dlg.MaximizeBox = $false
$dlg.MinimizeBox = $false
$dlg.Font = $form.Font

[void](Add-Label 'Ara (Türkçe veya İngilizce):' 15 12 $dlg)
$txtQ = Add-Text 15 32 215 $dlg

[void](Add-Label 'İkon seti:' 240 12 $dlg)
$cmbSet = New-Object System.Windows.Forms.ComboBox
$cmbSet.DropDownStyle = 'DropDownList'
$cmbSet.Location = New-Object System.Drawing.Point(240, 32)
$cmbSet.Size = New-Object System.Drawing.Size(210, 24)
[void]$cmbSet.Items.Add('Tüm kaynaklar (Iconify + Icons8)')
[void]$cmbSet.Items.Add('Iconify - tüm setler')
[void]$cmbSet.Items.Add('Renkli ikonlar')
[void]$cmbSet.Items.Add('Tek renkli ikonlar')
[void]$cmbSet.Items.Add('Font Awesome')
[void]$cmbSet.Items.Add('Google Material')
[void]$cmbSet.Items.Add('Icons8')
[void]$cmbSet.Items.Add('Flaticon (web araması)')
[void]$cmbSet.Items.Add('Magnific Icons (web araması)')
$cmbSet.SelectedIndex = 0
$dlg.Controls.Add($cmbSet)

# Tek arama düğmesi: tüm sağlayıcılar mevcut arama akışından seçilir.
$btnSearch = Add-Button 'Ara' 455 31 85 $dlg
$dlg.AcceptButton = $btnSearch

$chkColor = New-Object System.Windows.Forms.CheckBox
$chkColor.Text = 'Renk uygula (tek renkli ikonlar için):'
$chkColor.Location = New-Object System.Drawing.Point(15, 66)
$chkColor.AutoSize = $true
$dlg.Controls.Add($chkColor)

$btnColor = Add-Button '' 285 62 50 $dlg
$btnColor.BackColor = $script:iconColor
[void](Add-Label 'Icons8 API anahtarı (gerekiyorsa):' 350 66 $dlg)
$txtIcons8Key = Add-Text 535 62 190 $dlg
$txtIcons8Key.UseSystemPasswordChar = $true
$txtIcons8Key.TabIndex = 4
$tipKey = New-Object System.Windows.Forms.ToolTip
$tipKey.SetToolTip($txtIcons8Key, 'Icons8 geliştirici panelinden aldığınız API anahtarını bu oturum için girin. Kaydedilmez.')

$lblStatus = Add-Label 'Kaynağı seçip Ara düğmesini kullanın. Flaticon ve Magnific, aynı arama akışından ilgili web aramasını açar; indirme/lisans koşulları kendi sitelerinde tamamlanır.' 15 97 $dlg

$flow = New-Object System.Windows.Forms.FlowLayoutPanel
$flow.Location = New-Object System.Drawing.Point(15, 122)
$flow.Size = New-Object System.Drawing.Size(715, 390)
$flow.AutoScroll = $true
$flow.BorderStyle = 'FixedSingle'
$flow.BackColor = [System.Drawing.Color]::White
$dlg.Controls.Add($flow)

$tip = New-Object System.Windows.Forms.ToolTip

$btnUse = Add-Button 'Seç ve İndir' 515 524 120 $dlg
$btnCancel = Add-Button 'İptal' 645 524 85 $dlg
$btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$dlg.CancelButton = $btnCancel
$lblSel = Add-Label 'Seçili ikon: -' 15 529 $dlg

function Get-CurrentHex {
    if ($chkColor.Checked) { return (Get-ColorHex $script:iconColor) }
    return ''
}

function Select-IconBox($box) {
    if ($script:selBox -and -not $script:selBox.IsDisposed) { $script:selBox.BackColor = [System.Drawing.Color]::White }
    $script:selBox = $box
    $script:selName = $box.Tag
    $box.BackColor = [System.Drawing.Color]::LightSkyBlue
    $lblSel.Text = 'Seçili ikon: ' + $script:selName.Name + ' [' + $script:selName.Provider + ']'
}

function Invoke-IconDownload {
    if (-not $script:selName) {
        [void][System.Windows.Forms.MessageBox]::Show('Önce bir ikon seçin.', 'Bilgi')
        return
    }
    $btnUse.Enabled = $false
    $lblStatus.Text = 'İkon indiriliyor...'
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $dir = Join-Path $env:TEMP 'ps1exe_icons'
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $safeName = ([string]$script:selName.Name -replace '[^\w\-]', '_')
        $file = Join-Path $dir ($safeName + '.png')
        $wc = New-Object System.Net.WebClient
        $wc.Headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) PwX-Studio/1.5.0'
        $rawFile = Join-Path $dir ($safeName + '.download')
        $errors = New-Object System.Collections.Generic.List[string]
        $candidates = @(Get-IconPngCandidates $script:selName 256 (Get-CurrentHex))
        foreach ($url in $candidates) {
            try {
                if (Test-Path $rawFile) { Remove-Item -LiteralPath $rawFile -Force }
                $wc.DownloadFile([uri]$url, $rawFile)
                if (Test-ImageFile $rawFile) {
                    Save-NormalizedPng $rawFile $file
                    break
                }
                $errors.Add('Sunucu görsel yerine geçersiz içerik döndürdü: ' + ([uri]$url).Host)
            } catch { $errors.Add(([uri]$url).Host + ': ' + $_.Exception.Message) }
        }
        if (-not (Test-Path $file) -or -not (Test-ImageFile $file)) {
            throw ('İkon indirilemedi. Denenen kaynaklar: ' + ($errors -join ' | '))
        }
        Remove-Item -LiteralPath $rawFile -Force -ErrorAction SilentlyContinue
        $script:pickedFile = $file
        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show('İkon indirilemedi: ' + $_.Exception.Message, 'Hata')
    }
    finally {
        $btnUse.Enabled = $true
        $lblStatus.Text = ''
    }
}

$btnColor.Add_Click({
    $cd = New-Object System.Windows.Forms.ColorDialog
    $cd.Color = $script:iconColor
    $cd.FullOpen = $true
    if ($cd.ShowDialog() -eq 'OK') {
        $script:iconColor = $cd.Color
        $btnColor.BackColor = $cd.Color
        $chkColor.Checked = $true
    }
})

$btnSearch.Add_Click({
    if (-not $txtQ.Text.Trim()) { return }
    # Flaticon ve Magnific, herkese açık/kararlı ikon indirme API'si sunmadığından
    # kaynak seçimi ve arama tek düğme altında tutulur; site sonuçları tarayıcıda açılır.
    if ($cmbSet.SelectedIndex -eq 7) { Open-IconSiteSearch 'Flaticon' $txtQ.Text; return }
    if ($cmbSet.SelectedIndex -eq 8) { Open-IconSiteSearch 'Magnific' $txtQ.Text; return }
    $btnSearch.Enabled = $false
    $script:selName = $null
    $script:selBox = $null
    $lblSel.Text = 'Seçili ikon: -'
    foreach ($c in @($flow.Controls)) { $c.Dispose() }
    $flow.Controls.Clear()
    $lblStatus.Text = 'Aranıyor...'
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $r = Search-Icons $txtQ.Text $cmbSet.SelectedIndex $txtIcons8Key.Text.Trim()
        if ($r.Icons.Count -eq 0) {
            if ($script:iconifySearchWarning -or $script:icons8SearchWarning) { $lblStatus.Text = 'İkon kaynaklarına erişilemedi. İnternet bağlantısını, proxy ayarlarını ve Icons8 API anahtarını kontrol edin.' }
            else { $lblStatus.Text = "Sonuç bulunamadı ('$($r.Query)'). Başka bir kelime deneyin." }
        }
        else {
            $lblStatus.Text = "$($r.Icons.Count) ikon bulundu ('$($r.Query)'). İkon önizlemesi gelmezse de seçip indirmeyi deneyebilirsiniz."
            if ($script:icons8SearchWarning -and $cmbSet.SelectedIndex -eq 0) { $lblStatus.Text += ' (Icons8 erişilemedi; Iconify sonuçları gösteriliyor.)' }
            if ($script:iconifySearchWarning -and $cmbSet.SelectedIndex -eq 0) { $lblStatus.Text += ' (Iconify erişilemedi; Icons8 sonuçları gösteriliyor.)' }
            $hex = Get-CurrentHex
            foreach ($iconItem in $r.Icons) {
                $pb = New-Object System.Windows.Forms.PictureBox
                $pb.Size = New-Object System.Drawing.Size(76, 76)
                $pb.Margin = New-Object System.Windows.Forms.Padding(4)
                $pb.SizeMode = 'Zoom'
                $pb.BorderStyle = 'FixedSingle'
                $pb.BackColor = [System.Drawing.Color]::White
                $pb.Cursor = [System.Windows.Forms.Cursors]::Hand
                $pb.Tag = $iconItem
                $tip.SetToolTip($pb, ($iconItem.Name + ' | ' + $iconItem.Provider + ' | ' + $iconItem.License))
                $pb.Add_Click({ param($s, $e) Select-IconBox $s })
                $pb.Add_DoubleClick({ param($s, $e) Select-IconBox $s; Invoke-IconDownload })
                $flow.Controls.Add($pb)

                $wc = New-Object System.Net.WebClient
                $wc.Headers['User-Agent'] = 'PwX-Studio/1.5.0'
                $state = [pscustomobject]@{ Box=$pb; FallbackUrl=(Get-IconResultFallbackPngUrl $iconItem 96 $hex); IsFallback=$false; Provider=$iconItem.Provider }
                $wc.Add_DownloadDataCompleted({
                    param($sender, $e)
                    $st = $e.UserState
                    $box = $st.Box
                    if ($e.Error -or $e.Cancelled) {
                        if (-not $st.IsFallback -and $st.Provider -ne 'Icons8' -and $box -and -not $box.IsDisposed) {
                            try {
                                $st.IsFallback = $true
                                $sender.DownloadDataAsync([uri]$st.FallbackUrl, $st)
                                return
                            } catch {}
                        }
                        if ($box -and -not $box.IsDisposed) {
                            $box.BackColor = [System.Drawing.Color]::MistyRose
                            $tip.SetToolTip($box, 'Önizleme yüklenemedi. İkonu seçip indirmeyi yine de deneyebilirsiniz.')
                        }
                        return
                    }
                    if ($box -and -not $box.IsDisposed) {
                        try {
                            $ms = New-Object System.IO.MemoryStream (,$e.Result)
                            $img = [System.Drawing.Image]::FromStream($ms)
                            $box.Image = New-Object System.Drawing.Bitmap $img
                            $img.Dispose(); $ms.Dispose()
                        } catch {
                            $box.BackColor = [System.Drawing.Color]::MistyRose
                        }
                    }
                })
                $wc.DownloadDataAsync([uri](Get-IconResultPngUrl $iconItem 96 $hex), $state)
            }
        }
    }
    catch {
        $lblStatus.Text = 'Arama başarısız: ' + $_.Exception.Message
    }
    finally { $btnSearch.Enabled = $true }
})

$btnUse.Add_Click({ Invoke-IconDownload })

# ------------------------------------------------------------------
#  Ana pencere olayları
# ------------------------------------------------------------------
function Set-Ps1([string]$path) {
    $txtPs1.Text = $path
    $base = [System.IO.Path]::GetFileNameWithoutExtension($path)
    if (-not $txtTitle.Text) { $txtTitle.Text = $base }
    $txtOut.Text = Join-Path ([System.IO.Path]::GetDirectoryName($path)) ($base + '.exe')
}

$btnPs1.Add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Filter = 'PowerShell script (*.ps1)|*.ps1'
    if ($d.ShowDialog() -eq 'OK') { Set-Ps1 $d.FileName }
})

$txtPs1.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $_.Effect = 'Copy' }
})
$txtPs1.Add_DragDrop({
    $f = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($f -and $f[0].ToLower().EndsWith('.ps1')) { Set-Ps1 $f[0] }
})

$btnLogo.Add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Filter = 'Görsel (*.png;*.jpg;*.jpeg;*.bmp;*.ico)|*.png;*.jpg;*.jpeg;*.bmp;*.ico'
    if ($d.ShowDialog() -eq 'OK') {
        $txtLogo.Text = $d.FileName
        $pic.Image = Load-PreviewImage $d.FileName
    }
})

$btnWeb.Add_Click({
    $script:pickedFile = $null
    if ($dlg.ShowDialog($form) -eq 'OK' -and $script:pickedFile) {
        $txtLogo.Text = $script:pickedFile
        $pic.Image = Load-PreviewImage $script:pickedFile
    }
})

$btnOut.Add_Click({
    $d = New-Object System.Windows.Forms.SaveFileDialog
    $d.Filter = 'Uygulama (*.exe)|*.exe'
    if ($txtOut.Text) { $d.FileName = $txtOut.Text }
    if ($d.ShowDialog() -eq 'OK') { $txtOut.Text = $d.FileName }
})

$btnBuild.Add_Click({
    $btnBuild.Enabled = $false
    $log.Clear()
    $tempPatchedSource = $null
    $tempConvertedIcon = $null
    try {
        $ps1 = $txtPs1.Text.Trim()
        $outExe = $txtOut.Text.Trim()
        if (-not (Test-Path -LiteralPath $ps1 -PathType Leaf)) { throw 'Geçerli bir .ps1 dosyası seçin.' }
        if ([IO.Path]::GetExtension($ps1) -ine '.ps1') { throw 'Kaynak dosya .ps1 uzantılı olmalıdır.' }
        if (-not $outExe) { throw 'Çıktı EXE yolunu belirtin.' }
        if ([IO.Path]::GetExtension($outExe) -ine '.exe') { throw 'Çıktı dosyası .exe uzantılı olmalıdır.' }
        if ($txtLogo.Text.Trim() -and -not (Test-Path -LiteralPath $txtLogo.Text.Trim() -PathType Leaf)) { throw 'İkon dosyası bulunamadı.' }
        if ($chkX86.Checked -and $chkX64.Checked) { throw 'x86 ve x64 aynı anda seçilemez. Yalnızca birini seçin.' }

        $outDir = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($outExe))
        if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

        $iconForBuild = $null
        if ($txtLogo.Text.Trim()) {
            $selectedIconPath = (Resolve-Path -LiteralPath $txtLogo.Text.Trim()).Path
            if ([IO.Path]::GetExtension($selectedIconPath) -ieq '.ico') { 
                $iconForBuild = $selectedIconPath 
            } else {
                $iconForBuild = Join-Path $env:TEMP ('pwx_icon_' + [guid]::NewGuid().ToString('N') + '.ico')
                $tempConvertedIcon = $iconForBuild
                Convert-ToIco $selectedIconPath $iconForBuild
                Write-Log 'Seçilen görsel EXE uyumlu çok boyutlu ICO formatına dönüştürüldü.'
            }
        }

        $compileInput = (Resolve-Path -LiteralPath $ps1).Path
        if ($iconForBuild) {
            # Simge yolu önce çözülür; seçilen ICO kaynak PowerShell'e gömülür ve desteklenen WinForms formlarına atanır.
            $iconBytes = [System.IO.File]::ReadAllBytes($iconForBuild)
            $iconBase64 = [Convert]::ToBase64String($iconBytes)
            $sourceText = [System.IO.File]::ReadAllText($compileInput)
            $iconBootstrap = @'
# PwX Studio embedded window icon bootstrap
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
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
                Write-Log ("Pencere simgesi kaynak koda uygulandı: {0} WinForms form kurucusu bulundu." -f $formMatches.Count)
            }
        }

        # -------------------------------------------------------------
        #  PwX Build Engine (Yerli Bağımsız Motor)
        # -------------------------------------------------------------
        $engineScript = Join-Path $PSScriptRoot 'pwxengine\scripts\PwX-Build.ps1'
        if (-not (Test-Path -LiteralPath $engineScript)) {
            $engineScript = Join-Path (Get-Location) 'pwxengine\scripts\PwX-Build.ps1'
        }
        if (-not (Test-Path -LiteralPath $engineScript)) {
            throw "PwX Build Engine betiği bulunamadı: $engineScript"
        }

        $target = if ($rbTargetPS7.Checked) { 'PS7' } else { 'PS51' }
        $mode   = if ($rbWin.Checked) { 'Gui' } else { 'Console' }
        $title  = if ($txtTitle.Text.Trim()) { $txtTitle.Text.Trim() } else { [IO.Path]::GetFileNameWithoutExtension($ps1) }
        $comp   = $txtCompany.Text.Trim()
        $ver    = if ($txtVer.Text.Trim() -match '^\d+(\.\d+){1,3}$') { $txtVer.Text.Trim() } else { '1.0.0.0' }

        Write-Log "PwX Build Engine başlatılıyor... [Hedef=$target, Mod=$mode]"
        $bArgs = @{
            Source = $compileInput
            Output = [IO.Path]::GetFullPath($outExe)
            Target = $target
            Mode   = $mode
            Force  = $true
        }
        if ($iconForBuild) { $bArgs.Icon = $iconForBuild }
        if ($title) { $bArgs.ProductName = $title; $bArgs.Description = $title }
        if ($comp) { $bArgs.CompanyName = $comp }
        if ($ver) { $bArgs.FileVersion = $ver; $bArgs.ProductVersion = $ver }
        if ($target -eq 'PS7') {
            if ($chkX86.Checked) {
                Write-Log 'Bilgi: PS7 çalışma zamanı win-x64 mimarisi ile derleniyor.'
            }
            $bArgs.Architecture = 'win-x64'
            if ($chkSingleFile.Checked) { $bArgs.SingleFile = $true }
        }

        Write-Log ('Seçenekler: ' + (($bArgs.Keys | Sort-Object) -join ', '))
        $res = & $engineScript @bArgs
        if ($null -ne $res -and -not $res.Success) {
            throw "PwX Build Engine derleme hatası: $($res.Error)"
        }

        if (-not (Test-Path -LiteralPath $outExe -PathType Leaf)) { throw 'Derleme tamamlandı görünse de EXE dosyası oluşmadı. Günlük çıktısını kontrol edin.' }
        $item = Get-Item -LiteralPath $outExe
        Write-Log "BAŞARILI: $($item.FullName)"
        Write-Log ("Dosya boyutu: {0:N1} KB" -f ($item.Length / 1KB))
        [void][System.Windows.Forms.MessageBox]::Show("EXE oluşturuldu:`r`n$outExe", 'İşlem tamamlandı', 'OK', 'Information')
        [System.Diagnostics.Process]::Start('explorer.exe', "/select,`"$outExe`"") | Out-Null
    }
    catch {
        Write-Log ('HATA: ' + $_.Exception.Message)
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Derleme hatası', 'OK', 'Error')
    }
    finally {
        if ($tempPatchedSource -and (Test-Path -LiteralPath $tempPatchedSource)) { Remove-Item -LiteralPath $tempPatchedSource -Force -ErrorAction SilentlyContinue }
        if ($tempConvertedIcon -and (Test-Path -LiteralPath $tempConvertedIcon)) { Remove-Item -LiteralPath $tempConvertedIcon -Force -ErrorAction SilentlyContinue }
        $btnBuild.Enabled = $true
    }
})
# Başlangıç temasını uygula; güneş/ay simgesi Paint-ThemeSwitch tarafından çizilir.
Apply-Theme $form $script:currentTheme
$lblBrand.ForeColor = [System.Drawing.Color]::FromArgb(74, 119, 245)
$btnThemeToggle.Invalidate()
[void]$form.ShowDialog()
