# TeX Live 2021 インストール用プロファイル（このプロジェクトに必要な範囲）
#
# 背景: Overleaf の WISS2026 テンプレートは texlive-full:2021.1 (TeX Live 2021) に固定。
#       同じリリースを再現するため historic の tlnet-final（凍結済み）から取得する。
#       フル構成はドキュメント/ソースが大部分で 4 時間以上かかるため、
#       この文書のコンパイルに必要な範囲（scheme-small + 日本語 + latexrecommended + binextra）
#       のみを入れる。同一の TL2021 パッケージを使うためコンパイル結果は scheme-full と同じ。
#       足りないパッケージがあれば後から `tlmgr install <pkg>` で追加できる。
#
# 使い方 (install-tl.zip を展開し、コンソール版を非 GUI で実行):
#   install-tl-windows.bat -no-gui -profile install\texlive2021.profile ^
#       -repository https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final
#
# 使えるミラー（2026-09 時点で確認）:
#   https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final   （HTTPS・推奨）
#   http://ftp.uni-kl.de/pub/tug/historic/systems/texlive/2021/tlnet-final          （HTTP・代替）
#   ※ utah.edu / pi.kwarc.info / mirror.ctan.org は接続不可または 404 だった
#
# ポイント:
#   instopt_adjustpath 0                 : 既存の TeX Live 2023 の PATH を書き換えない
#   desktop_integration / file_assocs 0  : システム統合を行わない
#   install_docfiles / install_srcfiles 0: コンパイルに不要な PDF マニュアル・ソースを除外
#   tlnet-final は凍結済みなので、同じミラーから入れれば全PCで同一構成になる

selected_scheme scheme-small
collection-langjapanese 1
collection-latexrecommended 1
collection-binextra 1
TEXDIR C:/texlive/2021
TEXMFLOCAL C:/texlive/texmf-local
TEXMFSYSVAR C:/texlive/2021/texmf-var
TEXMFSYSCONFIG C:/texlive/2021/texmf-config
TEXMFVAR ~/.texlive2021/texmf-var
TEXMFCONFIG ~/.texlive2021/texmf-config
TEXMFHOME ~/texmf
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
