#!/bin/bash

# Benchmark all frameworks locally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"; }
warning() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"; }

ALL_FRAMEWORKS=("next" "next-cachecomponents" "react-router" "tanstack")
INCLUDE_FRAMEWORKS="${INCLUDE_FRAMEWORKS:-}"
EXCLUDE_FRAMEWORKS="${EXCLUDE_FRAMEWORKS:-}"
COOLDOWN_BETWEEN_BENCHMARKS=20

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
		error "No frameworks selected. Check INCLUDE_FRAMEWORKS/EXCLUDE_FRAMEWORKS values."
		exit 1
	fi

	FRAMEWORKS=("${selected[@]}")
}

build_framework_list

declare -A RESULTS
FAILED_FRAMEWORKS=()

echo ""
echo "========================================================================"
echo "  LOCAL BENCHMARK ALL FRAMEWORKS"
echo "========================================================================"
echo ""
echo "Frameworks:  ${FRAMEWORKS[*]}"
echo ""
echo "This runs all benchmarks sequentially on localhost."
echo "No cloud resources are used."
echo ""
echo "========================================================================"
echo ""

for i in "${!FRAMEWORKS[@]}"; do
	framework="${FRAMEWORKS[$i]}"
	framework_num=$((i + 1))
	total_frameworks=${#FRAMEWORKS[@]}

	echo ""
	echo "========================================================================"
	echo "  FRAMEWORK ${framework_num}/${total_frameworks}: ${framework^^}"
	echo "========================================================================"
	echo ""

	log "Starting local benchmark for $framework..."

	START_TIME=$(date +%s)

	if FRAMEWORK="$framework" bash ./benchmark.sh; then
		END_TIME=$(date +%s)
		DURATION=$((END_TIME - START_TIME))
		DURATION_MIN=$((DURATION / 60))
		DURATION_SEC=$((DURATION % 60))

		success "$framework benchmark completed in ${DURATION_MIN}m ${DURATION_SEC}s"
		RESULTS[$framework]="SUCCESS (${DURATION_MIN}m ${DURATION_SEC}s)"
	else
		END_TIME=$(date +%s)
		DURATION=$((END_TIME - START_TIME))
		DURATION_MIN=$((DURATION / 60))
		DURATION_SEC=$((DURATION % 60))

		error "$framework benchmark FAILED after ${DURATION_MIN}m ${DURATION_SEC}s"
		RESULTS[$framework]="FAILED (${DURATION_MIN}m ${DURATION_SEC}s)"
		FAILED_FRAMEWORKS+=("$framework")
	fi

	if [ "$framework_num" -lt "$total_frameworks" ]; then
		log "Cooldown: waiting ${COOLDOWN_BETWEEN_BENCHMARKS}s before next benchmark..."
		sleep "$COOLDOWN_BETWEEN_BENCHMARKS"
	fi
done

echo ""
echo "========================================================================"
echo "  BENCHMARK SUMMARY"
echo "========================================================================"
echo ""

for framework in "${FRAMEWORKS[@]}"; do
	status="${RESULTS[$framework]}"
	if [[ "$status" == SUCCESS* ]]; then
		success "$framework: $status"
	else
		error "$framework: $status"
	fi
done

echo ""
log "Latest result files:"
echo ""
for framework in "${FRAMEWORKS[@]}"; do
	latest_result=$(ls -t results/${framework}-*.log 2>/dev/null | head -1)
	if [ -n "$latest_result" ]; then
		success "$framework: $latest_result"
	else
		warning "$framework: No result file found"
	fi
done

echo ""
echo "========================================================================"

if [ ${#FAILED_FRAMEWORKS[@]} -gt 0 ]; then
	error "The following frameworks failed: ${FAILED_FRAMEWORKS[*]}"
	exit 1
fi

success "All local benchmarks completed successfully!"
