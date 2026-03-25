#!/bin/bash

# Run all frameworks with a fixed mixed traffic profile:
# 1000 req/s for 3 minutes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ALL_FRAMEWORKS=("next" "next-cachecomponents" "react-router" "tanstack")
INCLUDE_FRAMEWORKS="${INCLUDE_FRAMEWORKS:-}"
EXCLUDE_FRAMEWORKS="${EXCLUDE_FRAMEWORKS:-}"
TARGET_RPS=1000
DURATION_SECONDS=180
COOLDOWN_SECONDS=20

build_framework_list() {
  local selected=()
  local include_raw=",${INCLUDE_FRAMEWORKS// /},"
  local exclude_raw=",${EXCLUDE_FRAMEWORKS// /},"

  for fw in "${ALL_FRAMEWORKS[@]}"; do
    if [[ -n "$INCLUDE_FRAMEWORKS" && "$include_raw" != *",$fw,"* ]]; then
      continue
    fi
    if [[ -n "$EXCLUDE_FRAMEWORKS" && "$exclude_raw" == *",$fw,"* ]]; then
      continue
    fi
    selected+=("$fw")
  done

  if [[ ${#selected[@]} -eq 0 ]]; then
    echo "No frameworks selected. Check INCLUDE_FRAMEWORKS/EXCLUDE_FRAMEWORKS values." >&2
    exit 1
  fi

  FRAMEWORKS=("${selected[@]}")
}

build_framework_list

echo ""
echo "========================================================================"
echo "  MIXED E-COMMERCE BENCHMARK (ALL FRAMEWORKS)"
echo "========================================================================"
echo ""
echo "Traffic profile: mixed homepage/search/cards/games/sellers"
echo "Target load:     ${TARGET_RPS} req/s"
echo "Duration:        ${DURATION_SECONDS} seconds (3 minutes)"
echo ""
echo "========================================================================"
echo ""

for i in "${!FRAMEWORKS[@]}"; do
  framework="${FRAMEWORKS[$i]}"
  idx=$((i + 1))
  total=${#FRAMEWORKS[@]}

  echo ""
  echo "------------------------------------------------------------------------"
  echo "Running ${framework} (${idx}/${total})"
  echo "------------------------------------------------------------------------"

  FRAMEWORK="$framework" \
  BENCH_PROFILE="mixed" \
  TARGET_RPS="$TARGET_RPS" \
  DURATION_SECONDS="$DURATION_SECONDS" \
  bash ./benchmark.sh

  if [[ "$idx" -lt "$total" ]]; then
    echo ""
    echo "Cooldown ${COOLDOWN_SECONDS}s before next framework..."
    sleep "$COOLDOWN_SECONDS"
  fi
done

echo ""
echo "========================================================================"
echo "All mixed benchmarks finished."
echo "Results are in: ./results"
echo "========================================================================"
