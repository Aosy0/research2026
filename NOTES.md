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
│  ├─ texlive2021.profile       … TeX Live 2021 インストール用プロファイル（Windows）
│  ├─ texlive2021-linux.profile … 同（Linux。パスは TEXLIVE_INSTALL_PREFIX から導出）
│  ├─ setup-texlive2021.ps1     … セットアップを自動化（Windows）
│  ├─ setup-texlive2021.sh      … セットアップを自動化（Linux/macOS）
│  └─ texlive-2021-packages.txt … インストール済みパッケージ一覧（537件・構成の検証用）
└─ WISS2026_Template_demo/
   ├─ wiss_template.tex  … テンプレート本文（Overleaf 原本と一致・編集しない）
   ├─ 23fi551_wiss.tex   … 執筆中の論文本文
   ├─ wiss.cls / wissbase11.cls … スタイルクラス
   ├─ jwiss.bst          … 参考文献スタイル（format.url を標準 pBibTeX 対応に修正）
   ├─ sample.bib         … テンプレート付属のサンプル文献（wiss_template.tex が参照）
   ├─ references.bib     … 執筆論文の実文献（23fi551_wiss.tex が参照）
   ├─ latexmkrc          … latexmk 設定
   ├─ latexmk-2021.cmd   … ビルド用ラッパー（Windows・PATH に TL2021 を前置）
   └─ build.sh           … TeX Live 2021 でビルドするスクリプト（Linux/macOS）
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

### Linux / macOS

Windows と同じ凍結リポジトリ（`tlnet-final`）から、同じパッケージ構成を
ユーザー領域（既定 `~/texlive/2021`）へ入れる。システムの TeX Live や PATH は変更しない。

```bash
install/setup-texlive2021.sh
# 導入先を変える場合
TEXLIVE_INSTALL_PREFIX="$HOME/opt/texlive" install/setup-texlive2021.sh
```

- `install-tl` は `-repository` でミラーを指定し、プロファイルは
  `install/texlive2021-linux.profile` を使う。
- `TEXDIR` 等はハードコードせず、`TEXLIVE_INSTALL_PREFIX`（既定 `$HOME/texlive`）から
  導出するため、どのマシンでも同じ手順で再現できる。
- バイナリの arch ディレクトリ（`bin/x86_64-linux` 等）はスクリプトが自動検出する。
  `platex` は `eptex` へのシンボリックリンクなので、検出時に `-type l` を含める必要がある。
- 追加パッケージ（`sttools`＝`flushend` 提供、`nidanfloat`）もスクリプトが入れる。
- `latexindent`（エディタの自動整形用）: TeX Live 2021 は Linux でこの Perl モジュール群を
  同梱しないため、OS 側に入れる。スクリプトが不足を検出して案内する。
  ```bash
  sudo apt-get install libyaml-tiny-perl libfile-homedir-perl libunicode-linebreak-perl
  ```
  あわせて `~/.local/bin/latexindent` に TL2021 の `latexindent` を呼ぶラッパーを生成する
  （`~/.local/bin` が PATH にあること）。これで LaTeX Workshop の既定設定
  （`"latex-workshop.formatting.latex": "latexindent"`）が PATH から解決できる。
  モジュールが無いと「Can not find latexindent in PATH.」で整形が失敗する（ビルドには無関係）。

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

`latexmk-2021.cmd` が PATH 先頭に `C:\texlive\2021\bin\win32` を足して `latexmk` を呼ぶ
（既定の TeX Live には影響しない）。`latexmkrc` の設定で `platex` → `pbibtex` → `dvipdfmx`
が順に走り、生成物は `out/` にまとまる。

```powershell
cd WISS2026_Template_demo
.\latexmk-2021.cmd wiss_template.tex   # テンプレート（4ページ）
.\latexmk-2021.cmd 23fi551_wiss.tex    # 執筆論文
# 生成物を消してやり直す場合
Remove-Item -Recurse -Force .\out
```

> 以前の `build.ps1` は削除済み。ビルドは `latexmk-2021.cmd` に統一した。

### コマンドライン（Linux / macOS）

```bash
WISS2026_Template_demo/build.sh
# 生成物を消してからビルドし直す場合
WISS2026_Template_demo/build.sh --clean
```

`build.sh` はその起動中だけ `~/texlive/2021/bin/<arch>-linux`（`TEXLIVE_INSTALL_PREFIX`
で変更可）を PATH 先頭に足し、`latexmk wiss_template.tex` を実行する。
既定のシステム TeX Live には影響しない。**テンプレートファイルは一切変更しない。**

### VS Code（LaTeX Workshop）

ユーザー設定（グローバル）は PATH 上の `latexmk`（TeX Live 2026）を使うため、そのままだと
`nidanfloat` で失敗する。リポジトリの `.vscode/settings.json` でこのプロジェクトだけ
**TL2021 を使うレシピ**に上書きしている。

- `latexmk-2021.cmd` … Windows 用。PATH に TL2021 を前置して `latexmk` を呼ぶラッパー
- `build.sh` … Linux/macOS 用。PATH に TL2021 を前置して `latexmk` を呼ぶ
- `.vscode/settings.json` … OS 別にツール／レシピを 2 つ定義

LaTeX Workshop は **ツール／レシピを OS で条件分岐できない**（`command` は文字列のみ、
`%...%` プレースホルダも `command` には適用されない）。またツールの `env` は
`${env:PATH}` / `$PATH` を展開せず、PATH を丸ごと置換する。そのため PATH 前置は各 OS 用の
ラッパー側で行い、両レシピを併記して `latex-workshop.latex.recipe.default` で選ぶ。

```jsonc
"latex-workshop.latex.recipes": [
  { "name": "latexmk (TeX Live 2021, Linux)", "tools": ["latexmk2021-linux"] },
  { "name": "latexmk (TeX Live 2021)",         "tools": ["latexmk2021"] }
],
// recipe.default はレシピ名を指定できる（"first"/"lastUsed" 以外）
"latex-workshop.latex.recipe.default": "latexmk (TeX Live 2021, Linux)"
```

- Linux/macOS: 既定のままで `bash` + `build.sh` が動く。
- Windows: 既定を `"latexmk (TeX Live 2021)"` に変更する（`cmd` + `.cmd` を使う）。
- うまく既定が選ばれない場合は「LaTeX Workshop: Build with recipe」で一度選ぶ（以後は記憶される）。

設定変更後は VS Code の **「ウィンドウの再読み込み」**（またはエディタ再起動）で有効になる。

> 症状の例: Linux で Windows 用ツールのまま実行すると
> `spawn cmd ENOENT`（`cmd` が無い）で失敗する。上記の Linux レシピに切り替えれば解消する。

### 保存時の整形と句読点変換（`、。` → `，．`）

保存時に「整形」と「句読点変換」を自動で行う。当初 Punc Flip（`almond-latte.punc-flip`）を
使っていたが、VS Code の保存時処理は**逐次実行**であり、LaTeX Workshop のフォーマッタも
Punc Flip も「**全文を置換する編集**」を返すため、**後から適用された方だけが残り、もう片方は
消える**（VS Code 本体 `textFileSaveParticipant.ts` / `extHostDocumentSaveParticipant.ts`）。
両方を自動で両立させる定石は無い。

そこで **latexindent に句読点置換まで統合**し、1つのフォーマッタで完結させる:

- `WISS2026_Template_demo/latexindent.yaml` … `replacements` で `、`→`，`、`。`→`．`
- `.vscode/settings.json`:
  ```jsonc
  "latex-workshop.formatting.latex": "latexindent",
  "latex-workshop.formatting.latexindent.args":
      ["-c", "%DIR%/", "%TMPFILE%", "-l", "%DIR%/latexindent.yaml", "-r"],
  "[latex]": { "editor.formatOnSave": true },
  "punc-flip.excludePatterns": ["**/node_modules/**", "**/.git/**", "**/*.tex"]
  ```
  `-r`（replacement mode）が無いと `replacements` は適用されない点に注意。
- Punc Flip は `.tex` を除外（`.md`/`.txt` では従来どおり保存時変換が使える）。

> 検証: LaTeX Workshop と同一のコマンドで実ファイルを処理し、終了コード 0・`、`/`。` の残り 0・
> `，` 80 箇所を確認。設定変更後は VS Code の **「ウィンドウの再読み込み」** が必要。

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

### 検証結果（2026-09-29・再現性確認）

fresh clone（`out/` 無し）相当、および追跡済み `wiss_template.bbl` を削除した状態で検証。
どちらも `latexmk-2021.cmd` の終了コード **0**、`!` エラー 0。

| 文書 | 出力 | 備考 |
| --- | --- | --- |
| `wiss_template.tex` | 4ページ | テンプレート原本のまま。`sample.bib` から bibtex で `.bbl` を再生成 |
| `23fi551_wiss.tex` | 2ページ | `references.bib` から `.bbl` を再生成 |

### 検証結果（2026-10-04・Linux / Ubuntu 24.04）

Linux 版スクリプト（`setup-texlive2021.sh` / `build.sh`）でも同じ結果を確認。

| 項目 | 結果 |
| --- | --- |
| エンジン | e-pTeX 3.141592653-p3.9.0-210218-2.6 (utf8.euc)（TeX Live 2021/Linux） |
| pBibTeX | 0.99d-j0.33 (utf8.euc) |
| dvipdfmx | 20210318（Linux バイナリ。TeX Live 2021 凍結版） |
| latexmk | 4.77 |
| 出力 | `out/wiss_template.pdf` **4ページ**（`[1][2][3][4]`） |
| BibTeX | エラー・警告なし。`latexmk` 終了コード **0** |
| テンプレート | `.tex`/`.cls`/`.bst` は無改変（`git status` で新規追加はスクリプトのみ） |

## つまずいた点（再発防止）

1. **`install-tl-windows.exe`（自己解凍 GUI）は不安定**
   - `-no-gui` が効かず GUI が立ち上がる／ネットワーク切断で最初からやり直しになる。
   - → `install-tl.zip` の `install-tl-windows.bat` を `-no-gui` で実行する。
2. **長いインストールは切り離しプロセスで**
   - エージェントやターミナルの待機がタイムアウトしても、`Start-Process` で起動した
     インストーラ本体は止まらない。待機だけを中断しても再開不要（ログは `%TEMP%\tl2021-install.log`）。
3. **TeX Live 2021 の Windows バイナリは `bin\win32`**
   - 2023 以降は `bin\windows`。`latexmk-2021.cmd` は `C:\texlive\2021\bin\win32` を前置する。
4. **PowerShell スクリプトは ASCII のみで書く**
   - BOM 無し UTF-8 の日本語コメントは Windows PowerShell 5.1（Shift-JIS 解釈）で
     構文エラーになる。`setup-texlive2021.ps1` は ASCII に統一。
5. **VS Code が既定で新しい TeX Live を使う**
   - グローバルの `latex-workshop.latex.tools` は PATH 上の `latexmk`（本環境は TL2026）。
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

### 4. `flushend` + `nidanfloat` で最終ページ出力が停止（`23fi551_wiss.tex`）

**症状**

```
! Infinite glue shrinkage found in box being split.
\iterate ...it \flushend@@varbox@a to\var@@temp@a
l.89 \end{document}
```

LaTeX は「you can safely proceed」で回復し DVI も出力するが、`platex` の終了コードが **1** に
なるため `latexmk` が PDF 生成の前に中断する（LaTeX Workshop では「Recipe terminated with
error」）。テンプレート原本（4ページ）では起きず、内容の短い論文で発生した。

**原因**

- `flushend` は最終ページの2段組を揃えるため段ボックスを `\vsplit` する。
- その箱に `nidanfloat` が入れた `\vss`（無限収縮グルー）が混ざると、e-pTeX が
  `\vsplit` 時にエラーを出す（TeX Live 2021 のカーネルでも発生）。`flushend` の最新版
  （v4.3 / 2025-06-18）でもこの `\vsplit` 設計は変わっていない。

**修正**

`23fi551_wiss.tex` のプリアンブルで `flushend` を外し、`nidanfloat` の `balance`
オプションで最終ページの段組み揃えを維持する（テンプレート本体 `wiss_template.tex` は
`flushend` のまま。こちらは4ページでエラーが出ない）。

```diff
-\usepackage{nidanfloat}
+\usepackage[balance]{nidanfloat}
 \usepackage{multicol}
 \usepackage{color}
-\usepackage{flushend}
 \usepackage{url}
```

> `latexmk -f`（エラーを無視して継続）では PDF が生成されず、根本解決にならない。

### 5. `sample.bib` をテンプレート原本へ復元＋実文献を `references.bib` に分離（再現性）

**症状**

`wiss_template.tex` は `\cite{wiss}` / `\cite{rekimoto2000}` / `\cite{IEEE2014}` を参照するが、
`sample.bib` が執筆論文の実文献（`jansen2015` 等）に差し替えられていたため、bibtex が
**空の `.bbl`** を生成し、`! LaTeX Error: Something's wrong--perhaps a missing \item.` で
`platex` が終了コード 1 → `latexmk` 中断。

**原因**

- それまで `wiss_template.tex` が通っていたのは、追跡済みの `wiss_template.bbl`（prebuilt）を
  platex が読んでいたため。bibtex が一度でも走ると `out/` に空の `.bbl` ができ、そちらが
  優先されてビルドが壊れる（＝別PC・再ビルドで再現しない状態だった）。

**修正**

- `sample.bib` をテンプレート本来の内容（`d4436dc`、警告修正済み）へ復元。
  これで `wiss_template.tex` は prebuilt `.bbl` に依存せず、bibtex が常に正しい `.bbl` を再生成できる。
- 執筆論文の実文献は `references.bib` に分離し、`23fi551_wiss.tex` の参照先を変更。
  ```diff
  -\bibliography{sample}
  +\bibliography{references}
  ```

> `wiss_template.tex` は **一切変更していない**。

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
  （本プロジェクトは `latexmk-2021.cmd` が 2021 を優先する）。
