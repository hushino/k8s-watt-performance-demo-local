#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
source "$PROJECT_ROOT/lib/common.sh"

FRAMEWORK="${FRAMEWORK:-next}"
FRAMEWORK_DIR="$PROJECT_ROOT/$FRAMEWORK"

BENCH_PROFILE="${BENCH_PROFILE:-smoke}"
TARGET_RPS="${TARGET_RPS:-1000}"
DURATION_SECONDS="${DURATION_SECONDS:-180}"

# Local-only hardcoded defaults
HOST="127.0.0.1"
APP_PORT=3042

RESULTS_DIR="$PROJECT_ROOT/results"
LOGS_DIR="$PROJECT_ROOT/.logs"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_FILE="$RESULTS_DIR/${FRAMEWORK}-${TIMESTAMP}.log"
APP_LOG="$LOGS_DIR/${FRAMEWORK}-app-${TIMESTAMP}.log"

APP_PID=""

validate_framework() {
	if [[ ! -d "$FRAMEWORK_DIR" ]]; then
		error "Framework directory not found: $FRAMEWORK_DIR"
		error "Valid values: next, next-cachecomponents, react-router, tanstack"
		return 1
	fi

	return 0
}

validate_local_tools() {
	log "Validating local tools..."

	local tools=("npm" "curl" "fuser" "node")
	for tool in "${tools[@]}"; do
		if ! check_tool "$tool"; then
			return 1
		fi
	done

	success "Local tools validated"
	return 0
}

cleanup_local_processes() {
	set +e

	if [[ -n "$APP_PID" ]]; then
		kill "$APP_PID" >/dev/null 2>&1 || true
	fi
	fuser -k "${APP_PORT}/tcp" >/dev/null 2>&1 || true

	set -e
}

trap cleanup_local_processes EXIT INT TERM

install_and_build_framework() {
	log "Installing dependencies for $FRAMEWORK..."
	cd "$FRAMEWORK_DIR"
	npm install

	log "Building $FRAMEWORK..."
	npm run build

	success "$FRAMEWORK build complete"
}

start_framework_server() {
	log "Starting local server on $HOST:$APP_PORT"
	cd "$FRAMEWORK_DIR"
	PORT="$APP_PORT" HOSTNAME="$HOST" npm run start:node >"$APP_LOG" 2>&1 &
	APP_PID=$!

	wait_for_http "$HOST" "$APP_PORT" 60 2
	success "Server is ready"
}

run_local_benchmark() {
	log "Running built-in local smoke benchmark for $FRAMEWORK"
	mkdir -p "$RESULTS_DIR"

	local samples=30
	local timeout=5
	local ok=0
	local failed=0

	local summary
	summary=$(for i in $(seq 1 "$samples"); do
		curl -s -o /dev/null -w "%{http_code} %{time_total}\n" --connect-timeout "$timeout" --max-time "$timeout" "http://$HOST:$APP_PORT/" || echo "000 0"
	done | awk '
	{
		code=$1
		time_ms=$2*1000
		if (code == "200") {
			ok++
			sum_ms += time_ms
			if (min_ms == 0 || time_ms < min_ms) min_ms = time_ms
			if (time_ms > max_ms) max_ms = time_ms
		} else {
			failed++
		}
	}
	END {
		avg_ms = ok > 0 ? sum_ms / ok : 0
		printf "samples=%d\nok=%d\nfailed=%d\navg_ms=%.2f\nmin_ms=%.2f\nmax_ms=%.2f\n", NR, ok, failed, avg_ms, min_ms, max_ms
	}')

	{
		echo "========================================================================"
		echo "LOCAL SMOKE BENCHMARK RESULT"
		echo "========================================================================"
		echo "framework=$FRAMEWORK"
		echo "target=http://$HOST:$APP_PORT"
		echo "$summary"
		echo "========================================================================"
	} | tee "$RESULT_FILE"

	success "Benchmark summary saved to $RESULT_FILE"
}

run_mixed_highload_benchmark() {
	log "Running mixed e-commerce benchmark for $FRAMEWORK (${TARGET_RPS} req/s for ${DURATION_SECONDS}s)"
	mkdir -p "$RESULTS_DIR"

	TARGET_BASE_URL="http://$HOST:$APP_PORT" \
	FRAMEWORK="$FRAMEWORK" \
	DATA_DIR="$FRAMEWORK_DIR/data" \
	REQUEST_RATE="$TARGET_RPS" \
	DURATION_SECONDS="$DURATION_SECONDS" \
	node "$PROJECT_ROOT/lib/mixed-load-benchmark.mjs" | tee "$RESULT_FILE"

	success "Benchmark summary saved to $RESULT_FILE"
}

run_benchmark() {
	case "$BENCH_PROFILE" in
		smoke)
			run_local_benchmark
			;;
		mixed-1000rps|mixed)
			run_mixed_highload_benchmark
			;;
		*)
			error "Unknown BENCH_PROFILE: $BENCH_PROFILE"
			error "Valid values: smoke, mixed (or mixed-1000rps)"
			return 1
			;;
	esac
}

show_log_hint_on_failure() {
	error "Server log: $APP_LOG"
}

main() {
	log "########################################################################"
	log "LOCAL CASUAL BENCHMARK"
	log "Framework: $FRAMEWORK"
	log "Profile: $BENCH_PROFILE"
	log "Started at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
	log "########################################################################"

	mkdir -p "$RESULTS_DIR" "$LOGS_DIR"

	validate_framework
	validate_local_tools

	if ! install_and_build_framework; then
		show_log_hint_on_failure
		exit 1
	fi

	if ! start_framework_server; then
		show_log_hint_on_failure
		exit 1
	fi

	run_benchmark

	log "########################################################################"
	log "LOCAL BENCHMARK COMPLETED"
	log "Finished at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
	log "########################################################################"
}

main "$@"
