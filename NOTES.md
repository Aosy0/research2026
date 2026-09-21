# research2026 作業メモ

WISS 2026 論文テンプレート（pLaTeX）のビルド環境と、発生した問題の調査・修正の記録。

## 構成

- `WISS2026_Template_demo/` … WISS 2026 論文テンプレート一式
  - `wiss_template.tex` … 本文（テンプレート）
  - `wiss.cls` / `wissbase11.cls` … スタイルクラス
  - `jwiss.bst` … 参考文献スタイル
  - `latexmkrc` … latexmk 設定

## ビルド環境

- TeX Live 2023（`C:\texlive\2023`）
- `platex` / `pbibtex` / `dvipdfmx` / `latexmk` 4.82

```powershell
cd WISS2026_Template_demo
latexmk wiss_template.tex
```

## 調査と修正（2026-09-21）

### 1. 致命的：`nidanfloat` が LaTeX 2020 以降と非互換

**症状**

```
! LaTeX mark Error: Infinite shrinkage found in 'column'.
No pages of output.
```

**原因**

- `nidanfloat.sty`（2018年版 v2.9、二段浮動体）が `\@outputdblcol` / `\@combinefloats` を上書きし、
  段ボックスを `\vbox to <高さ>{... \vss}` として組み立てる。
- LaTeX カーネルは段送り時に `\@opcol` → `\@expl@@@mark@update@dblcol@structures@@`
  （`latex.ltx:17311-17314`）で段ボックスの mark を抽出する。
- その `\vss`（無限の負の伸縮）を mark 機構が検出し、
  `msg_error:nnn {mark} {infinite-shrinkage}`（`latex.ltx:14832`）で停止する。

**検証**

- 最小再現に成功：`\documentclass{jsarticle}` + `\usepackage{nidanfloat}` + `\twocolumn` + `figure*`。
- `\usepackage{nidanfloat}` を外すとコンパイル成功（内容に依存しない）。

**対策**（`wiss_template.tex` の `\usepackage{nidanfloat}` 直後に1行追加）

```latex
\makeatletter\let\@expl@@@mark@update@dblcol@structures@@\@empty\makeatother
```

- `nidanfloat` の挙動は維持し、二段組の mark 更新のみ無効化する。
- `wiss.cls` のヘッダは `mark` を使わず `\journalhead` / `\title@j` 由来のため影響なし。
- TeX Live 2019 以前では該当マクロが存在しないだけで無害。

### 2. `jwiss.bst` が未定義関数を参照（未解決・回避のみ）

- `format.url`（`jwiss.bst:299-322`）が `writeln` / `lastaccessed` / `empty.or.unknown` を使用。
  これらは JBibTeX / urlbst 由来のヘルパで、TeX Live の (u)pBibTeX には存在しない（コピー漏れ）。
- 影響：`pbibtex` が8件のエラーを返し、`latexmk` が exit code 12 で中断する。
  ただし `.bbl` 自体は正常に生成され、引用・参照は解決される。

**回避**（`latexmkrc` に追加）

```perl
$force_mode = 1;
```

**残課題**

- `@online` 等で URL を引用すると `.bbl` に `\showURL{...}` / `\urldef\tempurl` が出力されるが、
  これらは未定義（urlbst.sty 相当が必要）。URL 付き文献を使う場合は要対応。
- 根本修正するなら `format.url` を標準の `write$` / `newline$` に書き換える。

## 環境メモ

- リポジトリは当初 Box Drive 上にあった。
  `C:\Users\koboy\Box` はマウントボリュームへのジャンクション（再解析ポイント）で、
  オンデマンド同期のため git / LaTeX の運用に不向き。→ ローカルへ移動。
- `~/Documents`（シェルの「Documents」）は OneDrive リダイレクト：
  `C:\Users\koboy\OneDrive\ドキュメント`（オンデマンド同期）。
  一方、**実体のあるローカル Documents は `C:\Users\koboy\Documents`**（他の開発プロジェクトもここ）。
- 別PCで使う場合は Box/OneDrive 同期を介さず、GitHub から `git clone` する
  （オンデマンドのプレースホルダは git / LaTeX を壊す）。
- `git config --global safe.directory` に旧パスが残っている場合は更新する。

## 移動後の確認

```powershell
cd WISS2026_Template_demo
latexmk wiss_template.tex
# → wiss_template.pdf が 4 ページで生成され、ログに Infinite shrinkage が無ければOK
```
