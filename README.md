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
- 2つ目のPCでも `install/setup-texlive2021.ps1` を実行すれば同じ構成になります。
- 文献は論文ごとに分けています。テンプレート `wiss_template.tex` は `sample.bib`、
  執筆論文 `23fi551_wiss.tex` は `references.bib` を参照します。
  テンプレート本文は**原本のまま**変更していません。

## VS Code（LaTeX Workshop）

グローバル設定は PATH 上の `latexmk`（= TeX Live 2023）を使うため、そのままだと
`nidanfloat` で失敗します。このリポジトリの **`.vscode/settings.json`** が、このプロジェクトだけ
**TeX Live 2021 を使うレシピ**に上書きします（`latexmk-2021.cmd` 経由）。

設定変更後は VS Code の **「ウィンドウの再読み込み」** を行ってください。
レシピ「latexmk (TeX Live 2021)」が既定になります。

## ドキュメント

- 詳細・経緯・トラブルシュート: [NOTES.md](NOTES.md)
- インストール用プロファイル: [install/texlive2021.profile](install/texlive2021.profile)
- セットアップスクリプト: [install/setup-texlive2021.ps1](install/setup-texlive2021.ps1)
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
