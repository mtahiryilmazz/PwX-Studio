<#
.SYNOPSIS  PwX Build Engine duman testleri (Roadmap T-001, T-002, T-003, T-004, T-005, T-009).
#>
[CmdletBinding()]
param([ValidateSet('PS51', 'PS7', 'All')][string]$Target = 'All', [switch]$SingleFile)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root   = Split-Path -Parent $PSScriptRoot
$build  = Join-Path $root 'scripts\PwX-Build.ps1'
$sample = Join-Path $PSScriptRoot 'samples\hello.ps1'
$targets = if ($Target -eq 'All') { @('PS51', 'PS7') } else { @($Target) }
$rows = New-Object System.Collections.Generic.List[object]

function Add-Row($t, $id, $name, $ok, $detail = '') { $rows.Add([pscustomobject]@{ Target = $t; Test = $id; Name = $name; Result = $(if ($ok) { 'PASS' } else { 'FAIL' }); Detail = $detail }) }

foreach ($t in $targets) {
    $dir = Join-Path $root "artifacts\test-results\$t"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $exe = Join-Path $dir 'hello.exe'
    $bargs = @{ Source = $sample; Output = $exe; Target = $t; Force = $true }
    if ($t -eq 'PS7' -and $SingleFile) { $bargs.SingleFile = $true }

    $res = & $build @bargs
    if (-not $res.Success) { Add-Row $t 'BUILD' 'Derleme' $false 'Derleme başarısız'; continue }
    $exePath = $res.OutputPath

    $o = (& $exePath | Out-String)
    Add-Row $t 'T-001' 'Varsayılan çıktı' ($o -match 'PwX Studio')

    $o = (& $exePath -Message 'abc' | Out-String)
    Add-Row $t 'T-002' 'Adlandırılmış parametre' ($o -match 'abc')

    $o = (& $exePath -Message 'iki kelime, dünya' | Out-String)
    Add-Row $t 'T-003' 'Boşluklu argüman' ($o -match 'iki kelime, dünya')

    & $exePath -Code 17 | Out-Null
    Add-Row $t 'T-004' 'Çıkış kodu 17' ($LASTEXITCODE -eq 17) "alınan: $LASTEXITCODE"

    $o = (& $exePath | Out-String)
    Add-Row $t 'T-005' 'Türkçe karakterler' ($o -match 'ğüşıöçĞÜŞİÖÇ')
}

# PS7 GUI host must compile and propagate the script's exit N value to the process.
if ($targets -contains 'PS7') {
    $guiOut = Join-Path $root 'artifacts\test-results\PS7-GUI\hello-gui.exe'
    $guiRes = & $build -Source $sample -Output $guiOut -Target PS7 -Mode Gui -Force
    if ($guiRes.Success -and (Test-Path -LiteralPath $guiRes.OutputPath)) {
        & $guiRes.OutputPath -Code 17
        $guiExit = $LASTEXITCODE
        Add-Row 'PS7-GUI' 'T-GUI-001' 'GUI host betik çıkış kodunu iletir' ($guiExit -eq 17) "beklenen: 17; alınan: $guiExit"
    }
    else {
        Add-Row 'PS7-GUI' 'T-GUI-001' 'GUI host betik çıkış kodunu iletir' $false 'GUI derlemesi başarısız'
    }
}

# T-009: sözdizimi hatası -> derleme başarısız, EXE oluşmamalı
$bad = Join-Path ([IO.Path]::GetTempPath()) ('pwx-bad-' + [guid]::NewGuid().ToString('N') + '.ps1')
[IO.File]::WriteAllText($bad, "Write-Output 'x'`r`nif ($true {", (New-Object Text.UTF8Encoding($true)))
$badOut = Join-Path $root 'artifacts\test-results\bad.exe'
& $build -Source $bad -Output $badOut -Target PS51 -Force *> $null
Add-Row 'ALL' 'T-009' 'Sözdizimi hatası reddedilir' (($LASTEXITCODE -eq 1) -and -not (Test-Path $badOut))
Remove-Item $bad -Force -ErrorAction SilentlyContinue

$rows | Format-Table -AutoSize
if ($rows | Where-Object Result -eq 'FAIL') { exit 1 }
