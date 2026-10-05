#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WISS 2026 原稿の静的チェック（ビルド不要）

チェック項目:
  - 概要の文字数（和文400字程度）と、概要内の空行の有無
  - \\journalhead が空でないか
  - 図の参照（未参照の図・未定義の参照）とキャプションの位置
  - 画像形式（jpg/jpeg は非可逆のため警告）とファイルの存在
  - 章構成（1つしか節がない章）
  - 句読点（、。の残り）

使い方: python3 check-format.py [23fi551_wiss.tex]
終了コード: 0=問題なし / 1=要修正 / 2=ファイルなし
"""
import re
import sys
import unicodedata
from pathlib import Path

tex = Path(sys.argv[1] if len(sys.argv) > 1 else '23fi551_wiss.tex')
if not tex.exists():
    print(f"NG  原稿が見つかりません: {tex}")
    sys.exit(2)
src = tex.read_text(encoding='utf-8')

status = 0


def ok(msg):
    print(f"OK  {msg}")


def warn(msg):
    global status
    status = 1
    print(f"WARN {msg}")


def ng(msg):
    global status
    status = 1
    print(f"NG  {msg}")


# ---- 概要（文字数・一続きか） ----
m = re.search(r'\\begin\{abstract\}(.*?)\\end\{abstract\}', src, re.S)
if not m:
    ng("概要（abstract環境）がありません")
else:
    body = m.group(1)
    if re.search(r'\n[ \t]*\n', body):
        warn("概要内に空行があります（「概要．」と本文は一続きに書く）")
    text = re.sub(r'%.*$', '', body, flags=re.M)
    text = re.sub(r'\\verb(.)(.*?)\1', '', text, flags=re.S)
    text = re.sub(r'\\(cite|ref|label)\*?(\[[^\]]*\])?\{[^}]*\}', '', text)
    text = re.sub(r'\\[a-zA-Z]+\*?', '', text)
    text = text.replace('{', '').replace('}', '')
    text = re.sub(r'\s+', '', text)
    zen = sum(1.0 if unicodedata.east_asian_width(c) in ('W', 'F', 'A') else 0.5 for c in text)
    msg = f"概要: 実文字 {len(text)} 字 / 全角換算 {zen:.1f} 字（目安: 和文400字程度）"
    if len(text) > 440:
        warn(msg + " → 超過気味")
    elif len(text) < 300:
        warn(msg + " → 短め")
    else:
        ok(msg)

# ---- ヘッダ（ハシラ） ----
if re.search(r'\\journalhead\{\s*\}', src):
    ng("\\journalhead{} が空です（ヘッダにはしらが必要）")
elif '\\journalhead{' not in src:
    ng("\\journalhead{} がありません")
else:
    ok("\\journalhead は設定済み")

# ---- 図の参照・キャプション位置 ----
labels = set(re.findall(r'\\label\{(fig:[^}]+)\}', src))
refs = set(re.findall(r'\\ref\{(fig:[^}]+)\}', src))
for lab in sorted(labels - refs):
    warn(f"図 {lab} が本文から参照されていません（「…を図Nに示す」を追加）")
for ref in sorted(refs - labels):
    ng(f"参照 {ref} に対応する \\label がありません")
for env in re.findall(r'\\begin\{figure\*?\}(.*?)\\end\{figure\*?\}', src, re.S):
    if '\\includegraphics' in env and '\\caption' in env:
        if env.index('\\includegraphics') > env.index('\\caption'):
            warn("図のキャプションが画像より前にあります（キャプションは図の下）")
if labels:
    ok(f"図ラベル {len(labels)} 件・本文参照 {len(refs)} 件")

# ---- 画像形式・存在 ----
imgs = re.findall(r'\\includegraphics(\[[^\]]*\])?\{([^}]+)\}', src)
for _, name in imgs:
    ext = name.rsplit('.', 1)[-1].lower() if '.' in name else ''
    if ext in ('jpg', 'jpeg'):
        warn(f"画像 {name}: jpg/jpeg は非可逆圧縮（画面キャプチャはPNG等を推奨）")
    if not (tex.parent / name).exists():
        ng(f"画像ファイルが見つかりません: {name}")
if imgs:
    ok(f"画像 {len(imgs)} 件の形式・存在を確認")

# ---- 章構成（節が1つだけの章） ----
sections = []
cur = None
for line in src.splitlines():
    m2 = re.match(r'\s*\\(section|subsection|subsubsection)\*?\{(.*)\}', line)
    if not m2:
        continue
    level, title = m2.group(1), m2.group(2)
    if level == 'section':
        if cur:
            sections.append(cur)
        cur = [title, 0]
    elif level == 'subsection' and cur is not None:
        cur[1] += 1
if cur:
    sections.append(cur)
for title, n in sections:
    if n == 1:
        warn(f"章「{title}」に節が1つだけです（章構成を見直す）")
if sections:
    ok(f"章 {len(sections)} 個の節構成を確認")

# ---- 句読点 ----
body = re.sub(r'%.*$', '', src, flags=re.M)
n_kuten = body.count('。')
n_touten = body.count('、')
if n_kuten or n_touten:
    warn(f"句読点「。」{n_kuten}件・「、」{n_touten}件（「．」「，」を推奨）")
else:
    ok("句読点は「．」「，」で統一")

sys.exit(status)
