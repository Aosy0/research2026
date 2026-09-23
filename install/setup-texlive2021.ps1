# Install TeX Live 2021 (the version Overleaf pins) into C:\texlive\2021.
#
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as the system
# code page (Shift-JIS), and Japanese comments/messages break parsing. Keep ASCII.
#
# Run from anywhere:
#   powershell -ExecutionPolicy Bypass -File .\install\setup-texlive2021.ps1
#
# Installs the minimal set needed by the WISS2026 template
# (scheme-small + collection-langjapanese + collection-latexrecommended + collection-binextra),
# then adds sttools (provides flushend) and nidanfloat.
# Takes ~15-40 min depending on the mirror. The existing TeX Live 2023 is not touched.
#
# Working historic mirrors (verified 2026-09):
#   https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final  (default)
#   http://ftp.uni-kl.de/pub/tug/historic/systems/texlive/2021/tlnet-final

[CmdletBinding()]
param(
    [string]$Repo = 'https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final',
    [string]$TlRoot = 'C:\texlive\2021'
)

$ErrorActionPreference = 'Stop'

$profile = Join-Path $PSScriptRoot 'texlive2021.profile'
if (-not (Test-Path $profile)) { throw "profile not found: $profile" }

$binExisting = Join-Path $TlRoot 'bin'
if ((Test-Path $binExisting) -and (Get-ChildItem $binExisting -Recurse -Filter 'platex.exe' -ErrorAction SilentlyContinue)) {
    Write-Host "TeX Live 2021 already present at $TlRoot (skipping base install)." -ForegroundColor Yellow
}
else {
    $zip = Join-Path $env:TEMP 'install-tl-2021.zip'
    $dst = Join-Path $env:TEMP 'install-tl-2021'
    Write-Host "Downloading installer from $Repo ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "$Repo/install-tl.zip" -OutFile $zip -TimeoutSec 300
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $dst -Force
    $bat = Get-ChildItem $dst -Recurse -Filter 'install-tl-windows.bat' | Select-Object -First 1

    $log = Join-Path $env:TEMP 'tl2021-install.log'
    Write-Host "Installing TeX Live 2021 to $TlRoot (non-GUI). This takes a while ..." -ForegroundColor Cyan
    & $bat.FullName -no-gui -profile $profile -repository $Repo -logfile $log
}

$platex = Get-ChildItem -Path (Join-Path $TlRoot 'bin') -Recurse -Filter 'platex.exe' | Select-Object -First 1
if (-not $platex) { throw "installation failed: platex.exe not found under $TlRoot\bin" }
$bin = $platex.Directory.FullName
$env:PATH = "$bin;$env:PATH"

Write-Host "=== platex ===" -ForegroundColor Cyan
& $platex.FullName --version | Select-Object -First 1

Write-Host "=== installing extras (sttools, nidanfloat) ===" -ForegroundColor Cyan
& (Join-Path $bin 'tlmgr.bat') --repository $Repo install sttools nidanfloat

Write-Host "=== done. Build with WISS2026_Template_demo\build.ps1 ===" -ForegroundColor Green
