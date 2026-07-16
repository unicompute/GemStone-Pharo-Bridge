#!/usr/bin/env bash
set -eo pipefail

BASE_SHA="${1:-a1864654ac0e6001f240a738d6f092de8e8f9764}"

packages=(
  "GemStone-GBS-Converted"
  "GemStone-GBS-Tools"
  "GemStone-Pharo-Tests"
)

# Pharo 14 upgrade: deprecated `Smalltalk os environment` / `Smalltalk os` call
# sites rewritten to `OSEnvironment current` / `OSPlatform current`, plus a
# lane-layering skip guard for the setAsideDirtyWhile tests.
expected_files=(
  "src/GemStone-GBS-Converted/GbsLibrary.class.st"
  "src/GemStone-GBS-Converted/GbsSessionParameters.class.st"
  "src/GemStone-GBS-Converted/GbxStatArchiver.class.st"
  "src/GemStone-GBS-Tools/GbsClassicLauncher.class.st"
  "src/GemStone-Pharo-Tests/GbsLiveSessionTestSupport.class.st"
  "src/GemStone-Pharo-Tests/GbxRemainingPortTest.class.st"
)
expected_reason="Pharo 14 upgrade: OSEnvironment/OSPlatform/inform: deprecation rewrites and setAsideDirtyWhile lane skip guard"

changed_files=()
base_files=()
while IFS= read -r file; do
  base_files+=("$file")
done < <(
  git ls-tree -r --name-only "$BASE_SHA" -- \
    src/GemStone-GBS-Converted \
    src/GemStone-GBS-Tools \
    src/GemStone-Pharo-Tests
)
work_files=()
while IFS= read -r file; do
  work_files+=("$file")
done < <(
  find \
    src/GemStone-GBS-Converted \
    src/GemStone-GBS-Tools \
    src/GemStone-Pharo-Tests \
    -type f | LC_ALL=C sort
)

while IFS= read -r file; do
  [[ -z "${file}" ]] && continue

  in_base=0
  in_work=0
  if git cat-file -e "$BASE_SHA:$file" 2>/dev/null; then
    in_base=1
  fi
  if [[ -f "$file" ]]; then
    in_work=1
  fi

  if [[ "${in_base}" -eq 1 && "${in_work}" -eq 1 ]]; then
    if ! diff -q <(git show "$BASE_SHA:$file") "$file" >/dev/null 2>&1; then
      changed_files+=("$file")
    fi
    continue
  fi

  if [[ "${in_base}" -ne "${in_work}" ]]; then
    changed_files+=("$file")
  fi
done < <(
  printf '%s\n' "${base_files[@]}" "${work_files[@]}" | LC_ALL=C sort -u
)

is_expected_file() {
  local candidate="$1"
  local expected
  for expected in "${expected_files[@]}"; do
    [[ "$candidate" == "$expected" ]] && return 0
  done
  return 1
}

unexpected_files=()
expected_changed_files=()
for file in "${changed_files[@]}"; do
  if is_expected_file "$file"; then
    expected_changed_files+=("$file")
  else
    unexpected_files+=("$file")
  fi
done

if [ "${#changed_files[@]}" -eq 0 ]; then
  printf 'ORIGINAL_LAYER_DRIFT_OK base=%s\n' "$BASE_SHA"
  exit 0
fi

if [ "${#unexpected_files[@]}" -eq 0 ]; then
  printf 'ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY base=%s files=%s\n' "$BASE_SHA" "${#expected_changed_files[@]}"
  for file in "${expected_changed_files[@]}"; do
    printf 'ORIGINAL_LAYER_DRIFT_EXPECTED file=%s reason=%s\n' "$file" "$expected_reason"
  done
  for package in "${packages[@]}"; do
    package_prefix="src/${package}/"
    package_count=0

    for file in "${expected_changed_files[@]}"; do
      if [[ "$file" == "$package_prefix"* ]]; then
        package_count=$((package_count + 1))
      fi
    done

    printf 'ORIGINAL_LAYER_DRIFT package=%s count=%s\n' "$package" "$package_count"

    for file in "${expected_changed_files[@]}"; do
      if [[ "$file" == "$package_prefix"* ]]; then
        printf '%s\n' "$file"
      fi
    done
  done

  exit 0
fi

printf 'ORIGINAL_LAYER_DRIFT base=%s files=%s\n' "$BASE_SHA" "${#changed_files[@]}"

for package in "${packages[@]}"; do
  package_prefix="src/${package}/"
  package_count=0

  for file in "${changed_files[@]}"; do
    if [[ "$file" == "$package_prefix"* ]]; then
      package_count=$((package_count + 1))
    fi
  done

  printf 'ORIGINAL_LAYER_DRIFT package=%s count=%s\n' "$package" "$package_count"

  for file in "${changed_files[@]}"; do
    if [[ "$file" == "$package_prefix"* ]]; then
      printf '%s\n' "$file"
    fi
  done
done
