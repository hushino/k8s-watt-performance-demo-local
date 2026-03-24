#!/bin/bash

# Run all frameworks with a fixed mixed traffic profile:
# 1000 req/s for 3 minutes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

FRAMEWORKS=("next" "react-router" "tanstack")
TARGET_RPS=1000
DURATION_SECONDS=180
COOLDOWN_SECONDS=20

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
  ./benchmark.sh

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
