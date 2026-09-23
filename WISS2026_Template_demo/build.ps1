# Build the WISS2026 template with TeX Live 2021 (the version Overleaf pins).
# This script is intentionally ASCII-only: Japanese comments broke parsing under
# Windows PowerShell 5.1 (it reads BOM-less .ps1 as the system code page, Shift-JIS),
# so keep comments/messages in ASCII to stay encoding-safe.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\build.ps1
#   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Clean

[CmdletBinding()]
param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

# TeX Live 2021 Windows binaries live in bin\win32 (bin\windows from 2023 on); auto-detect.
$tlRoot = 'C:\texlive\2021'
$platex = Get-ChildItem -Path (Join-Path $tlRoot 'bin') -Recurse -Filter 'platex.exe' -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $platex) {
    throw "platex.exe not found under $tlRoot\bin\*. Install TeX Live 2021 first (see install\texlive2021.profile)."
}
$tlBin = $platex.Directory.FullName

# Use TeX Live 2021 only for this session (does not affect the default TeX Live 2023).
$env:PATH = "$tlBin;$env:PATH"

Push-Location $PSScriptRoot
try {
    Write-Host "=== TeX Live 2021 ($tlBin) ===" -ForegroundColor Cyan
    & platex --version | Select-Object -First 1

    if ($Clean) {
        Write-Host "=== latexmk -C ===" -ForegroundColor Cyan
        & latexmk -C wiss_template.tex
    }

    Write-Host "=== latexmk wiss_template.tex ===" -ForegroundColor Cyan
    & latexmk wiss_template.tex

    $pdf = Join-Path $PSScriptRoot 'wiss_template.pdf'
    if (-not (Test-Path $pdf)) { throw "PDF was not produced: $pdf" }
    Write-Host "=== done: $pdf ===" -ForegroundColor Green
}
finally {
    Pop-Location
}
