#!/usr/bin/env bash
# The three implementations of the receipt hash (bash one-liner, JS helper,
# eval-gate.sh from git blobs) must agree, and the gate must accept a JS receipt.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; T="$ROOT/skills/company-chatbot/templates"
fail=0; ok(){ printf 'PASS  %s\n' "$1"; }; no(){ printf 'FAIL  %s (%s)\n' "$1" "$2"; fail=1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
oneliner(){ (cd "$1" && sed 's/\r$//;s/^[[:space:]]*//;s/[[:space:]]*$//;s#^\./##' evals/prompt-files.txt | grep -v '^#' | grep -v '^$' |
  while IFS= read -r p || [ -n "$p" ]; do if [ -f "$p" ]; then s=$(sha256sum < "$p" | cut -d' ' -f1); else s=missing; fi; printf '%s %s\n' "$p" "$s"; done | sha256sum | cut -d' ' -f1); }
case_(){ # name, list content (printf format)
  R="$W/$1"; mkdir -p "$R/api" "$R/evals"; git -C "$R" init -q -b main
  echo base > "$R/api/prompt.js"; printf 'x\n' > "$R/api/instrucci$(printf '\303\263')n.md"; printf '%s\n' "# list" "api/prompt.js" > "$R/evals/prompt-files.txt"
  git -C "$R" add -A; git -C "$R" commit -qm base; git -C "$R" checkout -q -b change
  printf "$2" > "$R/evals/prompt-files.txt"; echo changed > "$R/api/prompt.js"; git -C "$R" add -A; git -C "$R" commit -qm change
  a="$(oneliner "$R")"; b="$(node "$T/eval-receipt.mjs" hash "$R")"
  [ "$a" = "$b" ] && ok "$1: one-liner = JS" || no "$1: one-liner = JS" "$a vs $b"
  git -C "$R" checkout -q main
  EVAL_RECEIPT_DIR="$W/rc-$1" "$T/eval-gate.sh" "$R" main change 2>/dev/null; rc=$?
  [ "$rc" = 6 ] && ok "$1: gate refuses without receipt" || no "$1: gate refuses without receipt" "rc=$rc"
  git -C "$R" checkout -q change
  # exactly the documented call: dir = EVAL_RECEIPT_DIR
  EVAL_RECEIPT_DIR="$W/rc-$1" node --input-type=module -e "import { writeReceipt } from '$T/eval-receipt.mjs'; writeReceipt({ repoRoot: '$R', dir: process.env.EVAL_RECEIPT_DIR, bot: 't', cases: 1 });"
  git -C "$R" checkout -q main
  EVAL_RECEIPT_DIR="$W/rc-$1" "$T/eval-gate.sh" "$R" main change 2>/dev/null; rc=$?
  [ "$rc" = 0 ] && ok "$1: gate accepts the JS receipt" || no "$1: gate accepts the JS receipt" "rc=$rc"
}
case_ plain 'api/prompt.js\n'
case_ padded_crlf '# bot\r\n  api/prompt.js \r\n\r\n'
case_ dotslash './api/prompt.js\n'
case_ missing 'api/prompt.js\napi/nothere.js\n'
case_ no_final_newline 'api/prompt.js'
case_ accents 'api/prompt.js\napi/instrucci\303\263n.md\n'

# BOM: the gate refuses, the JS helper throws; never a silent pass
R="$W/bom"; mkdir -p "$R/api" "$R/evals"; git -C "$R" init -q -b main; echo a > "$R/api/prompt.js"; printf '\xef\xbb\xbfapi/prompt.js\n' > "$R/evals/prompt-files.txt"
git -C "$R" add -A; git -C "$R" commit -qm base; git -C "$R" checkout -q -b change; echo b > "$R/api/prompt.js"; git -C "$R" commit -qam b; git -C "$R" checkout -q main
EVAL_RECEIPT_DIR="$W/rc-bom" "$T/eval-gate.sh" "$R" main change 2>/dev/null; rc=$?; [ "$rc" = 6 ] && ok "bom: gate refuses" || no "bom: gate refuses" "rc=$rc"
node "$T/eval-receipt.mjs" hash "$R" >/dev/null 2>&1 && no "bom: JS throws" "it did not" || ok "bom: JS throws"
# documented override name
R="$W/plain"; git -C "$R" checkout -q main
EVAL_BLOCK=0 EVAL_RECEIPT_DIR="$W/none" "$T/eval-gate.sh" "$W/bom" main change 2>/dev/null; rc=$?; [ "$rc" = 0 ] && ok "EVAL_BLOCK=0 overrides" || no "EVAL_BLOCK=0 overrides" "rc=$rc"
exit $fail
