# TeX Live 2021 install profile for Linux (the version Overleaf pins).
#
# Same idea as texlive2021.profile (Windows), but without hard-coded
# Windows paths. The install prefix is chosen at runtime via the
# TEXLIVE_INSTALL_PREFIX environment variable (default: $HOME/texlive),
# so TEXDIR becomes $TEXLIVE_INSTALL_PREFIX/2021 on any machine.
# See setup-texlive2021.sh.
#
# Reproducibility: historic tlnet-final is frozen, so installing the same
# package set from the same repository yields the same TeX Live 2021 on
# every machine.
#
# Only the minimum needed by the WISS2026 template is installed
# (scheme-small + collection-langjapanese + collection-latexrecommended
# + collection-binextra); sttools (flushend) and nidanfloat are added
# afterwards by the setup script. Missing packages can be added later
# with `tlmgr install <pkg>`.

selected_scheme scheme-small
collection-langjapanese 1
collection-latexrecommended 1
collection-binextra 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
