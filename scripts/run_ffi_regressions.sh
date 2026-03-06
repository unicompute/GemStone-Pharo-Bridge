#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/tariq/src/gemtools"
GS_LIB="/opt/gemstone/product/lib"

if [[ -d "$GS_LIB" ]]; then
  export DYLD_LIBRARY_PATH="${GS_LIB}:${DYLD_LIBRARY_PATH:-}"
fi

compare_output() {
  local cmd="$1"
  local expected="$2"
  local tmp
  tmp="$(mktemp)"
  eval "$cmd" > "$tmp"
  if ! diff -u "$expected" "$tmp"; then
    echo "FFI regression mismatch for: $cmd" >&2
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
}

compare_output "$ROOT/test_gci_string" "$ROOT/test_gci_string.txt"
compare_output "$ROOT/test_gci_version" "$ROOT/test_gci_version.txt"
compare_output "$ROOT/test_gci_print" "$ROOT/test_gci_print.txt"
compare_output "$ROOT/test_gci_threads" "$ROOT/test_gci_threads.txt"
compare_output "$ROOT/gci_layout_check" "$ROOT/gci_layout_mac.txt"

echo "FFI_REGRESSION PASS"
