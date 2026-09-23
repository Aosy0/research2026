# research2026 作業メモ

WISS 2026 論文テンプレート（pLaTeX）のビルド環境と、発生した問題の調査・修正の記録。

## 方針：Overleaf の見た目を原本とする

このテンプレートは Overleaf 上で配布されており、Overleaf 側では次の構成に固定されている。

| 項目 | Overleaf の設定 |
| --- | --- |
| コンパイラ | `latex_dvipdf`（`latexmk` 経由で `platex` → `dvipdfmx`） |
| TeX Live | `texlive-full:2021.1` = **TeX Live 2021** |
| ビルド設定 | プロジェクト同梱の `latexmkrc` |

そのためローカルでも **TeX Live 2021 を固定で使う**。バージョンが違うと
`nidanfloat` / `flushend` / カーネル / 日本語フォントマップの差で段組みや未来ビジョン枠の
位置が変わり、レイアウトが崩れる（＝別PCで再現しない）原因になる。

> Overleaf の `texlive-full` イメージ自体は非公開で pull できない。
> 代わりに **TeX Live 2021 の最終スナップショット（historic の `tlnet-final`）** を使う。
> 同一の凍結リポジトリから入れれば、どのPCでも同じパッケージ構成になる。

## 構成

```
research2026/
├─ .vscode/
│  └─ settings.json             … LaTeX Workshop を TL2021 でビルドする設定
├─ install/
│  ├─ texlive2021.profile       … TeX Live 2021 インストール用プロファイル
│  ├─ setup-texlive2021.ps1     … セットアップを自動化（ダウンロード〜tlmgr まで）
│  └─ texlive-2021-packages.txt … インストール済みパッケージ一覧（537件・構成の検証用）
└─ WISS2026_Template_demo/
   ├─ wiss_template.tex  … 本文（Overleaf 原本と一致）
   ├─ wiss.cls / wissbase11.cls … スタイルクラス
   ├─ jwiss.bst          … 参考文献スタイル（format.url を標準 pBibTeX 対応に修正）
   ├─ sample.bib         … サンプル文献（警告が出ないよう微修正）
   ├─ latexmkrc          … latexmk 設定
   ├─ latexmk-2021.cmd   … LaTeX Workshop 用ラッパー（PATH に TL2021 を前置）
   └─ build.ps1          … TeX Live 2021 でビルドするスクリプト（ASCII のみ）
```

## セットアップ（各PCで1回）

TeX Live 2021 を `C:\texlive\2021` にインストールする。既存の TeX Live 2023
(`C:\texlive\2023`) とは併設され、PATH は書き換えない。

```powershell
powershell -ExecutionPolicy Bypass -File .\install\setup-texlive2021.ps1
```

手動で行う場合:

```powershell
$repo = 'https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final'
# ミラー代替: http://ftp.uni-kl.de/pub/tug/historic/systems/texlive/2021/tlnet-final

# install-tl.zip を展開し、コンソール版 install-tl-windows.bat を非 GUI で実行する
# （自己解凍 install-tl-windows.exe は GUI が立ち上がり不安定だったため使わない）
Invoke-WebRequest -Uri "$repo/install-tl.zip" -OutFile "$env:TEMP\install-tl-2021.zip"
Expand-Archive "$env:TEMP\install-tl-2021.zip" "$env:TEMP\install-tl-2021" -Force
$bat = Get-ChildItem "$env:TEMP\install-tl-2021" -Recurse -Filter install-tl-windows.bat | Select-Object -First 1

& $bat.FullName -no-gui `
    -profile .\install\texlive2021.profile `
    -repository $repo `
    -logfile "$env:TEMP\tl2021-install.log"

# 不足パッケージ（flushend を含む sttools、nidanfloat）を追加
$bin = 'C:\texlive\2021\bin\win32'
& "$bin\tlmgr.bat" --repository $repo install sttools nidanfloat
```

構成の記録（構成一致の検証用）:

```powershell
& C:\texlive\2021\bin\win32\tlmgr.bat list --only-installed > install\texlive-2021-packages.txt
```

### プロファイルのポイント

- `selected_scheme scheme-small` ＋ `collection-langjapanese` / `collection-latexrecommended` / `collection-binextra`
  - `scheme-full` はドキュメント PDF とソース(.dtx)を大量に含み **4時間以上**かかるうえ、
    この文書のコンパイルには不要。同一の TL2021 パッケージを使うため**出力は変わらない**。
  - 足りないパッケージは後から `tlmgr install <pkg>` で追加できる。
- `install_docfiles 0` / `install_srcfiles 0` … マニュアルとソースを除外
- `instopt_adjustpath 0` … 既存 TL2023 の PATH を壊さない
- `desktop_integration / file_assocs 0` … システム統合を行わない

### 使えるミラー（2026-09 時点で確認）

| ミラー | 結果 |
| --- | --- |
| `https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final` | OK（推奨） |
| `http://ftp.uni-kl.de/pub/tug/historic/systems/texlive/2021/tlnet-final` | OK（代替） |
| `https://ftp.math.utah.edu/...` | タイムアウト |
| `https://pi.kwarc.info/historic/...` | ホスト不明 |
| `https://mirror.ctan.org/systems/texlive/2021/tlnet-final` | 403 |

## ビルド

### コマンドライン

```powershell
cd WISS2026_Template_demo
powershell -ExecutionPolicy Bypass -File .\build.ps1
# 生成物を消してからビルドし直す場合
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Clean
```

`build.ps1` はこのセッション内だけ `C:\texlive\2021\bin\win32` を PATH 先頭に足し、
`latexmk wiss_template.tex` を実行する。既定の TeX Live 2023 には影響しない。

### VS Code（LaTeX Workshop）

ユーザー設定（グローバル）は TeX Live 2023 の `latexmk` を使うため、そのままだと
`nidanfloat` で失敗する。リポジトリの `.vscode/settings.json` でこのプロジェクトだけ
**TL2021 を使うレシピ**に上書きしている。

- `latexmk-2021.cmd` … PATH に TL2021 を前置して `latexmk` を呼ぶラッパー
- `.vscode/settings.json` … 上記ラッパーを `cmd /c` 経由で実行するツール／レシピ

> LaTeX Workshop のツール `env` は `${env:PATH}` を展開せず、PATH を丸ごと置換する
> （該当 PR は却下済み）。そのため `env` ではなく cmd 側で PATH を設定するラッパーを使う。

設定変更後は VS Code の **「ウィンドウの再読み込み」**（またはエディタ再起動）で
レシピ「latexmk (TeX Live 2021)」が有効になる。

### 検証結果（2026-09-23）

| 項目 | 結果 |
| --- | --- |
| エンジン | e-pTeX 3.141592653-p3.9.0-210218-2.6（TeX Live 2021/W32TeX） |
| pBibTeX | 0.99d-j0.33 |
| dvipdfmx | 20211117 |
| latexmk | 4.77 |
| 出力 | `wiss_template.pdf` **4ページ**（`[1][2][3][4]`） |
| `Infinite shrinkage` | 発生しない（`nidanfloat` 対策行は不要） |
| BibTeX | エラー・警告なし。`latexmk` 終了コード **0** |

## つまずいた点（再発防止）

1. **`install-tl-windows.exe`（自己解凍 GUI）は不安定**
   - `-no-gui` が効かず GUI が立ち上がる／ネットワーク切断で最初からやり直しになる。
   - → `install-tl.zip` の `install-tl-windows.bat` を `-no-gui` で実行する。
2. **長いインストールは切り離しプロセスで**
   - エージェントやターミナルの待機がタイムアウトしても、`Start-Process` で起動した
     インストーラ本体は止まらない。待機だけを中断しても再開不要（ログは `%TEMP%\tl2021-install.log`）。
3. **TeX Live 2021 の Windows バイナリは `bin\win32`**
   - 2023 以降は `bin\windows`。`build.ps1` は `bin\*\platex.exe` を自動検出する。
4. **PowerShell スクリプトは ASCII のみで書く**
   - BOM 無し UTF-8 の日本語コメントは Windows PowerShell 5.1（Shift-JIS 解釈）で
     構文エラーになる。`build.ps1` / `setup-texlive2021.ps1` は ASCII に統一。
5. **VS Code が既定で TL2023 を使う**
   - グローバルの `latex-workshop.latex.tools` は PATH 上の `latexmk`（= TL2023）。
     `.vscode/settings.json` で TL2021 レシピに上書きする。

## 調査と修正の記録

### 1. `nidanfloat` と LaTeX 2022 以降の非互換

**症状**

```
! LaTeX mark Error: Infinite shrinkage found in 'column'.
No pages of output.
```

**原因**

- `nidanfloat.sty`（2018年版 v2.9、二段浮動体）が `\@outputdblcol` / `\@combinefloats` を
  上書きし、段ボックスを `\vbox to <高さ>{... \vss}` として組み立てる。
- LaTeX 2022 以降のカーネルは段送り時に `\@expl@@@mark@update@dblcol@structures@@` で
  段ボックスの mark を抽出し、その `\vss`（無限の負の伸縮）を検出して停止する。

**結論**

- **TeX Live 2021 のカーネルにはこのチェックが無い**ため、Overleaf（TL2021）では
  テンプレート原本のまま正常にコンパイルできる。
- したがってローカルも **TeX Live 2021 を使う**ことで対策コードは不要。
  `wiss_template.tex` は Overleaf 原本と一致させている（対策行は削除済み）。
- 参考：どうしても TeX Live 2022 以降でビルドする場合のみ、`\usepackage{nidanfloat}` の
  直後に次を入れると回避できる（Overleaf 原本からは1行逸脱する）。
  ```latex
  \makeatletter\let\@expl@@@mark@update@dblcol@structures@@\@empty\makeatother
  ```

### 2. `jwiss.bst` が未定義関数を参照（修正済み）

**症状**

```
writeln is an unknown function---line 311 of file jwiss.bst
lastaccessed is an unknown function---line 315 of file jwiss.bst
empty.or.unknown is an unknown function---line 315 of file jwiss.bst
(There were 7 error messages)
```

これにより `pbibtex` がエラーを返し、`latexmk` の終了コードが 12 になる。
（LaTeX Workshop では「Recipe terminated with error」と表示される）

**原因**

- `jwiss.bst` の `format.url`（299-322行）は ACM-Reference-Format.bst の `output.url` からの
  移植。`writeln` / `lastaccessed` / `empty.or.unknown` は ACM 側で定義・ENTRY 登録されている
  識別子（`lastaccessed` は ENTRY のフィールド名、他は補助関数）で、JWISS スタイルには無い。
- 加えて呼び出しは `format.url output`（987行）であり、**文字列を返す契約**なのに、
  移植元は `writeln` で直接出力する「stack untouched」版だった（URL エントリ時に壊れる）。

**修正**

`format.url` を標準 pBibTeX で動く・契約どおり文字列を返す形に置き換え:

```bst
FUNCTION { format.url }
{ url empty$
    { "" }
    { "\url{" url * "}" * }
  if$
}
```

- `\showURL` / `\urldef` は LaTeX 側に定義が無く（urlbst.sty 相当が必要）、そもそも使えない。
- URL フィールドを使わない本サンプルでは **.bbl の出力は従来と同一**。
- これで `pbibtex` のエラーが消え、`latexmk` 終了コード **0**。`latexmkrc` の
  `$force_mode = 1;`（回避策）は不要になったため削除した。

### 3. `sample.bib` の警告（微修正）

- `@url{wiss}` … スタイルに `url` エントリ型が無く「entry type isn't style-file defined」警告。
  → `@misc{wiss}` に変更（既定の `misc` 扱いと同じ出力のまま警告を解消）。
- `IEEE2014` … ソート用の author/key が無く「to sort, need author or key」警告。
  → `key = {IEEE Style Manual}` を追加（出力には現れない）。

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
- TeX Live は年別ディレクトリで複数バージョンを併設できる。切替は PATH の付け替えで行う
  （本プロジェクトは `build.ps1` と `latexmk-2021.cmd` が 2021 を優先する）。
