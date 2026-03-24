#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
source "$PROJECT_ROOT/lib/common.sh"

FRAMEWORK="${FRAMEWORK:-all}"

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
			build_framework "next"
			build_framework "react-router"
			build_framework "tanstack"
			;;
		next|react-router|tanstack)
			build_framework "$FRAMEWORK"
			;;
		*)
			error "Invalid FRAMEWORK: $FRAMEWORK"
			error "Valid values: all, next, react-router, tanstack"
			exit 1
			;;
	esac

	echo ""
	success "Local build complete"
	echo "Run benchmark with: ./benchmark.sh"
	echo "Or all frameworks with: ./benchmark-all.sh"
}

main "$@"
