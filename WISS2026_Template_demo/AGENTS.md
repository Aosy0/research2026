# WISS2026_Template_demo

このフォルダは、`~/Docker/machimoki` のプロジェクトについて書く **WISS 2026 投稿論文**の原稿置き場である。

- 原稿: `23fi551_wiss.tex`
- 文献: `references.bib`（`\bibliography{references}`）
- 図: `machimoki_ui.png` ほか
- ビルド: `./build.sh 23fi551_wiss.tex`（TeX Live 2021 を使用、出力は `out/`）。
  引数なしの `./build.sh` はテンプレート `wiss_template.tex` をビルドするので原稿には使わない。

## machimoki との関係

対象実装は `~/Docker/machimoki` にある。設計・アーキテクチャ・CLI/API・
メッシュ検査の合否ルール・テスト方法は `~/Docker/machimoki/AGENTS.md` と
`~/Docker/machimoki/README.md` にまとまっているので、まずそれを参照する。

原稿に実装の挙動や仕様を書く際は、**推測で書かず必ず machimoki の該当コードを確認する**こと。
主な対応箇所の目安:

- `core/`: ブラウザ非依存のメッシュ生成・検査パイプライン（manifold-3d, 3MF/STL 出力）
- `frontend/`: React + Vite + CesiumJS/Three.js の Web UI
- `worker/`: 静的配信／軽量プロキシ
- `skills/machimoki-pipeline`, `skills/machimoki-testing`: パイプライン手順・テスト手順

## 注意

- machimoki 側のファイルは参照のみ。原稿作業のために編集しない。
- 論文の主張（新規性・寄与）は原稿本体の方針に従う。

## ページ数チェック（本文2ページ制約）

WISSのデモ論文は「本文2ページ以内（参考文献・謝辞・未来ビジョンは除外）」。
これを自動検査するスクリプトがある:

```bash
./check-body-pages.sh            # 23fi551_wiss.tex を検査
./check-body-pages.sh foo.tex    # 任意の原稿
```

- 検査項目:
  - ビルド後（`check-body-pages.sh`）: 本文末尾（`\label{bodyend}`）のページ /
    図（`fig:*`）のページ / Overfull `\hbox` / 未定義の引用・参照 /
    PDFサイズ（20MB以下）
  - 静的チェック（`check-format.py`）: 概要の文字数（400字程度）と空行 /
    `\journalhead` / 図の参照漏れ・未参照の図 / 画像形式（jpg警告）・存在 /
    章構成（節が1つだけの章）/ 句読点（、。の残り）
- **原稿の「まとめ」末尾に `\label{bodyend}` が必要**（無いと終了コード2で知らせる）。
  未来ビジョン節はページ数対象外なので、`bodyend` は「まとめ」の末尾に置く。
- 終了コード: `0`=PASS / `1`=本文・図が2ページ超過など / `2`=ビルド失敗・ラベル不足。
- 図も本文ページに含まれる。図が3ページ目に載るとFAILになる。
- スクリプトはビルドも実行する（TeX Live 2021 の `build.sh` を使用）。

## 権利・ライセンス対応（現状と将来TODO）

### 現状（研究段階でクリア済み）

- **PLATEAU**: 出典明記＋加工明示が条件（商用可・CC BY 4.0 互換）。
  論文の謝辞に「国土交通省の「Project PLATEAU」が公開する3D都市モデルを加工して利用した」と記載済み。
- **地理院タイル**: 出典明記が条件。UIに帰属表示済み、図1キャプションに「（地図データ：国土地理院）」を記載済み。
- **machimoki README**: ライセンス・帰属セクションあり（商用可、© PLATEAU、© 国土地理院、Cesium Ion 不使用）。
- **注意**: 「権利的に完全に自由」「誰でも自由に販売可」とは断定しない。
  データライセンスと、建物の著作物・意匠権は別問題。

### 将来TODO（公開・商用化の前に必要。研究段階では不要）

1. 書き出しファイルへの出典・ライセンス埋め込み（`.machimoki` manifest、`ATTRIBUTION.txt`、3MFメタデータ）
2. 利用規約・免責・商用利用ガイド（Mini Skyline 方式のライセンス判定・帰属バンドル）
3. データセット個別条件の確認（PLATEAU の一部例外・測量法、地理院タイルの種別）
4. 第三者権利（建物の著作物・意匠権）への対応（問い合わせ窓口、削除対応、必要時は専門家レビュー）
5. README の「商用利用は自由」はデータライセンス上の話であり第三者権利は別、と注記

参考事例: Map2Model（2026年7月、第三者による意匠権等の主張で閉鎖。データライセンスは問題ではなかった）。
