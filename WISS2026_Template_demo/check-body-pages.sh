#!/usr/bin/env bash
# WISS 2026 原稿チェック: 本文が2ページ以内に収まっているか
#
# 検査内容:
#   1) 本文末尾（「まとめ」の \label{bodyend}）が2ページ以内か
#   2) 図（\label{fig:*}）がすべて2ページ以内に載っているか
#      （figure* などが3ページ目に飛ぶと本文扱いになるためアウト）
#   3) 余白はみ出し（Overfull \hbox）の件数
#   4) 未定義の引用・参照
#
# 使い方:
#   ./check-body-pages.sh            # 23fi551_wiss.tex を検査
#   ./check-body-pages.sh foo.tex    # 任意の原稿
#
# 事前条件: 原稿の「まとめ」末尾に \label{bodyend} があること。
# 終了コード: 0 = PASS / 1 = レイアウト違反 / 2 = ビルド失敗・設定不足

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
TEX="${1:-23fi551_wiss.tex}"
BASE="${TEX%.tex}"
LIMIT=2

cd "$DIR" || exit 2

if [ ! -f "$TEX" ]; then
  echo "原稿が見つかりません: $TEX" >&2
  exit 2
fi

BUILD_LOG="$(mktemp)"
if ! ./build.sh "$TEX" >"$BUILD_LOG" 2>&1; then
  echo "BUILD FAILED"
  tail -30 "$BUILD_LOG"
  exit 2
fi

LOG="out/${BASE}.log"
AUX="out/${BASE}.aux"
status=0

page_of() { # $1 = label 名（完全一致）
  sed -n "s/.*\\\\newlabel{$1}{{[^}]*}{\([0-9][0-9]*\)}.*/\1/p" "$AUX" | head -1
}

echo "== WISS 原稿チェック: $TEX（本文 ${LIMIT} ページ以内） =="

# 1) 本文末尾のページ
if [ ! -f "$AUX" ] || ! grep -q '\\newlabel{bodyend}' "$AUX"; then
  echo "NG  \\label{bodyend} が見つかりません（「まとめ」末尾に追加してください）"
  status=2
else
  BODY_PAGE="$(page_of bodyend)"
  if [ -n "$BODY_PAGE" ] && [ "$BODY_PAGE" -le "$LIMIT" ]; then
    echo "OK  本文末尾（まとめ）: ${BODY_PAGE}ページ目"
  else
    echo "NG  本文末尾（まとめ）: ${BODY_PAGE:-?}ページ目 → ${LIMIT}ページ超過"
    status=1
  fi
fi

# 2) 図のページ
FIGS="$(grep -oE '\\newlabel\{fig:[^}]+\}' "$AUX" 2>/dev/null | sed 's/.*{//;s/}//')"
if [ -n "$FIGS" ]; then
  bad=0
  for f in $FIGS; do
    p="$(page_of "$f")"
    if [ -z "$p" ] || [ "$p" -gt "$LIMIT" ]; then
      echo "NG  図 ${f}: ${p:-?}ページ目 → ${LIMIT}ページ超過"
      bad=1
    fi
  done
  if [ "$bad" -eq 0 ]; then
    echo "OK  図（$(echo "$FIGS" | wc -w)件）: すべて${LIMIT}ページ以内"
  else
    status=1
  fi
else
  echo "INFO 図ラベル（fig:*）なし"
fi

# 3) 余白はみ出し
OVER="$(grep -c 'Overfull \\hbox' "$LOG" 2>/dev/null || true)"
if [ "$OVER" -eq 0 ]; then
  echo "OK  Overfull \\hbox: 0件"
else
  echo "WARN Overfull \\hbox: ${OVER}件（余白はみ出し。要修正）"
fi

# 4) 未定義の引用・参照
UNDEF="$(grep -cE 'Citation .* undefined|Reference .* undefined' "$LOG" 2>/dev/null || true)"
if [ "$UNDEF" -eq 0 ]; then
  echo "OK  未定義の引用・参照: 0件"
else
  echo "NG  未定義の引用・参照: ${UNDEF}件"
  status=1
fi

# 5) PDFサイズ（上限 20MB）
PDF="out/${BASE}.pdf"
if [ -f "$PDF" ]; then
  PDF_SIZE="$(wc -c < "$PDF")"
  if [ "$PDF_SIZE" -le 20971520 ]; then
    echo "OK  PDFサイズ: $((PDF_SIZE / 1024)) KB（上限 20MB）"
  else
    echo "NG  PDFサイズ: $((PDF_SIZE / 1024)) KB → 20MB超過"
    status=1
  fi
fi

# 6) 原稿の静的チェック（概要文字数・図参照・章構成・句読点など）
echo "--- 原稿の静的チェック ---"
if ! python3 "$DIR/check-format.py" "$TEX"; then
  status=1
fi

# 総ページ数（参考）
grep -oE 'Output written on [^)]*\([0-9]+ pages?[^)]*\)' "$LOG" || true

if [ "$status" -eq 0 ]; then
  echo "== 結果: PASS =="
elif [ "$status" -eq 2 ]; then
  echo "== 結果: 設定不足（ラベル追加またはビルド確認） =="
else
  echo "== 結果: FAIL（本文・図を${LIMIT}ページに収めてください） =="
fi
exit "$status"
