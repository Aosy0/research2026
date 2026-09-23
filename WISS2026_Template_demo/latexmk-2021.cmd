@echo off
rem Run latexmk with TeX Live 2021 (the version Overleaf pins).
rem Used by .vscode/settings.json. ASCII-only on purpose (see build.ps1).
rem cmd expands %PATH% here, so this reliably prepends TL2021 for latexmk and
rem its subprocesses (platex, pbibtex, dvipdfmx) without touching the system PATH.
set "PATH=C:\texlive\2021\bin\win32;%PATH%"
latexmk %*
exit /b %ERRORLEVEL%
