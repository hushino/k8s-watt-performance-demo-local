#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
source "$PROJECT_ROOT/lib/common.sh"

FRAMEWORK="${FRAMEWORK:-all}"
EXCLUDE_FRAMEWORKS="${EXCLUDE_FRAMEWORKS:-}"

ALL_FRAMEWORKS=("next" "next-cachecomponents" "react-router" "tanstack")

is_excluded() {
	local item="$1"
	local raw=",${EXCLUDE_FRAMEWORKS// /},"
	[[ "$raw" == *",$item,"* ]]
}

build_framework() {
	local name="$1"
	local dir="$PROJECT_ROOT/$name"

	if [[ ! -d "$dir" ]]; then
		error "Framework directory not found: $dir"
		return 1
	fi

	log "Installing dependencies: $name"
	cd "$dir"
	npm install

	log "Building: $name"
	npm run build

	success "Build complete: $name"
}

main() {
	if ! validate_common_tools; then
		error "Tool validation failed"
		exit 1
	fi

	if ! check_tool "npm"; then
		exit 1
	fi

	case "$FRAMEWORK" in
		all)
			for fw in "${ALL_FRAMEWORKS[@]}"; do
				if is_excluded "$fw"; then
					warning "Skipping excluded framework: $fw"
					continue
				fi
				build_framework "$fw"
			done
			;;
		next|next-cachecomponents|react-router|tanstack)
			build_framework "$FRAMEWORK"
			;;
		*)
			error "Invalid FRAMEWORK: $FRAMEWORK"
			error "Valid values: all, next, next-cachecomponents, react-router, tanstack"
			exit 1
			;;
	esac

	echo ""
	success "Local build complete"
	echo "Run benchmark with: FRAMEWORK=<name> bash ./benchmark.sh"
	echo "Run all smoke benchmarks with: bash ./benchmark-all.sh"
	echo "Run all mixed benchmarks with: bash ./benchmark-all-mixed.sh"
}

main "$@"
