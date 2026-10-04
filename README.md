# research2026

WISS 2026 論文テンプレート（pLaTeX）を **Overleaf と同じ TeX Live 2021** でビルドするためのリポジトリ。

- 原本（見た目の基準）: https://www.overleaf.com/latex/templates/wiss2026-template-demofa-biao-wiss-challengeyong/bftdyvdjyfnn
  - Overleaf 側の設定: コンパイラ `latex_dvipdf`、TeX Live `2021.1`

## クイックスタート

```powershell
# 1) TeX Live 2021 を C:\texlive\2021 にインストール（初回のみ・15〜40分）
powershell -ExecutionPolicy Bypass -File .\install\setup-texlive2021.ps1

# 2) ビルド（コマンドライン）
cd WISS2026_Template_demo
.\latexmk-2021.cmd wiss_template.tex   # テンプレート（4ページ）
.\latexmk-2021.cmd 23fi551_wiss.tex    # 執筆論文
```

生成物: `WISS2026_Template_demo\out\wiss_template.pdf`（**4ページ**）

- 既定の TeX Live（本環境は `C:\texlive\2026`）には影響しません（そのセッション内だけ 2021 を優先）。

## クイックスタート（Linux）

```bash
# 1) TeX Live 2021 を ~/texlive/2021 にインストール（初回のみ・15〜40分）
install/setup-texlive2021.sh

# 2) ビルド（コマンドライン）
WISS2026_Template_demo/build.sh
```

生成物: `WISS2026_Template_demo/out/wiss_template.pdf`（**4ページ**）

- Windows 版と同じ `tlnet-final`（凍結リポジトリ）から、同じパッケージ構成
  （`scheme-small` + 日本語 + latexrecommended + binextra + `sttools`/`nidanfloat`）を導入します。
- インストール先は `TEXLIVE_INSTALL_PREFIX`（既定 `$HOME/texlive`）で変更できます。
- システムの TeX Live や PATH には触れません（`build.sh` はその起動中だけ 2021 を前置）。
- **テンプレートファイル（`.tex`/`.cls`/`.bst` 等）は変更しません。** どの環境でも同じ手順でビルドできます。
- macOS でも同じスクリプトが使えます（`bin/*-darwin` を自動検出）。
- 2つ目のPCでも `install/setup-texlive2021.ps1` を実行すれば同じ構成になります。
- 文献は論文ごとに分けています。テンプレート `wiss_template.tex` は `sample.bib`、
  執筆論文 `23fi551_wiss.tex` は `references.bib` を参照します。
  テンプレート本文は**原本のまま**変更していません。

## VS Code（LaTeX Workshop）

グローバル設定は PATH 上の `latexmk`（= TeX Live 2023）を使うため、そのままだと
`nidanfloat` で失敗します。このリポジトリの **`.vscode/settings.json`** が、このプロジェクトだけ
**TeX Live 2021 を使うレシピ**に上書きします。

LaTeX Workshop はツール/レシピを **OS で分岐できない**ため、Windows 用（`cmd` +
`latexmk-2021.cmd`）と Linux/macOS 用（`bash` + `build.sh`）のレシピを両方定義しています。

```jsonc
// .vscode/settings.json
"latex-workshop.latex.recipe.default": "latexmk (TeX Live 2021, Linux)"
```

- **Linux/macOS**: 既定（上記）のままで動きます。`build.sh` がその起動中だけ TL2021 を前置します。
- **Windows**: 既定を次のように変更してください（`cmd` 経由の既存レシピを使うため）。
  ```jsonc
  "latex-workshop.latex.recipe.default": "latexmk (TeX Live 2021)"
  ```

設定変更後は VS Code の **「ウィンドウの再読み込み」** を行ってください。
うまく既定が選ばれない場合は、コマンドパレットの **「LaTeX Workshop: Build with recipe」** で
使用するレシピを一度選ぶと、その選択が記憶されます。

> 補足: LaTeX Workshop の `tool.env` は `${env:PATH}` を展開せず PATH を丸ごと置換するため、
> PATH 前置は各 OS 用ラッパー（`latexmk-2021.cmd` / `build.sh`）側で行っています。

## ドキュメント

- 詳細・経緯・トラブルシュート: [NOTES.md](NOTES.md)
- インストール用プロファイル: [install/texlive2021.profile](install/texlive2021.profile)（Windows）/ [install/texlive2021-linux.profile](install/texlive2021-linux.profile)（Linux）
- セットアップスクリプト: [install/setup-texlive2021.ps1](install/setup-texlive2021.ps1)（Windows）/ [install/setup-texlive2021.sh](install/setup-texlive2021.sh)（Linux）
- ビルドスクリプト: `WISS2026_Template_demo/latexmk-2021.cmd`（Windows）/ [WISS2026_Template_demo/build.sh](WISS2026_Template_demo/build.sh)（Linux）
- パッケージ一覧（構成の記録）: [install/texlive-2021-packages.txt](install/texlive-2021-packages.txt)

## なぜ TeX Live 2021 なのか

Overleaf がこのテンプレートを `texlive-full:2021.1` に固定しているため。
バージョンが異なると `nidanfloat` / `flushend` / カーネル / 日本語フォントの差で
レイアウトが崩れ、PC 間で再現しません。同一の凍結リポジトリ（`tlnet-final`）から
入れることで、どのPCでも同じパッケージ構成になります。

インストールするのは `scheme-small` ＋ 日本語・latexrecommended・binextra の必要最小限です
（`scheme-full` はドキュメント/ソース込みで4時間以上かかるうえ、この文書には不要）。
同一の TL2021 パッケージを使うため**コンパイル結果は `scheme-full` と同じ**です。
不足パッケージは後から `tlmgr install <pkg>` で追加できます。

## 注意

- `install/setup-texlive2021.ps1` などの PowerShell スクリプトは **ASCII のみ**で記述しています。
  BOM 無し UTF-8 の日本語コメントは Windows PowerShell 5.1 で構文エラーになるため、
  日本語の説明はこの README / NOTES に置いています。
- `jwiss.bst` の `format.url` は JBibTeX 由来の未定義関数を参照していたため、
  標準 pBibTeX で動く形に修正済みです（詳細は [NOTES.md](NOTES.md)）。
  これにより BibTeX のエラー・警告が無くなり、`latexmk` は終了コード 0 で完了します。
