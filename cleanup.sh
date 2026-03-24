#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
source "$PROJECT_ROOT/lib/common.sh"

PORTS=(3042)

cleanup_processes() {
	log "Cleaning up local benchmark processes..."

	pkill -f "next start" >/dev/null 2>&1 || true
	pkill -f "server.js" >/dev/null 2>&1 || true
	pkill -f ".output/server/index.mjs" >/dev/null 2>&1 || true
	pkill -f "npm run start:node" >/dev/null 2>&1 || true

	for p in "${PORTS[@]}"; do
		fuser -k "${p}/tcp" >/dev/null 2>&1 || true
	done

	success "Local cleanup completed"
}

main() {
	cleanup_processes
}

main "$@"
