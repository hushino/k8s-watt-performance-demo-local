# Local Framework Benchmark Demo

This repository runs local benchmarks for four frameworks:

- `next`
- `next-cachecomponents`
- `react-router`
- `tanstack`

No cloud, Kubernetes, Docker, PM2, or Watt runtime tooling is required.

## Prerequisites

- `npm`
- `curl`
- `fuser`
- Node.js (compatible with each framework package)

## Quick Start

From the repository root:

```sh
bash ./cleanup.sh
bash ./build.sh
bash ./benchmark-all.sh
```

## Run One Framework

```sh
FRAMEWORK=next bash ./benchmark.sh
FRAMEWORK=next-cachecomponents bash ./benchmark.sh
FRAMEWORK=react-router bash ./benchmark.sh
FRAMEWORK=tanstack bash ./benchmark.sh
```

## Run All Frameworks At 1,000 req/s For 3 Minutes

```sh
bash ./benchmark-all-mixed.sh
```

## Other way 
```sh
FRAMEWORK=next BENCH_PROFILE=mixed TARGET_RPS=1000 DURATION_SECONDS=180 bash benchmark.sh
```
Simple commands you can use

Run only next-cachecomponents:
FRAMEWORK=next-cachecomponents bash benchmark.sh

Run all frameworks (now includes next-cachecomponents):
bash benchmark-all.sh

Run all frameworks mixed 1000 req/s for 3 minutes:
bash benchmark-all-mixed.sh

Run all except one:
EXCLUDE_FRAMEWORKS=next-cachecomponents bash benchmark-all.sh
EXCLUDE_FRAMEWORKS=next-cachecomponents bash benchmark-all-mixed.sh

Run only selected frameworks:
INCLUDE_FRAMEWORKS=next-cachecomponents,react-router bash benchmark-all.sh
INCLUDE_FRAMEWORKS=next-cachecomponents,react-router bash benchmark-all-mixed.sh

## Run All Except One

Exclude one framework from all standard benchmarks:

```sh
EXCLUDE_FRAMEWORKS=next-cachecomponents bash ./benchmark-all.sh
```

Exclude one framework from mixed 1000 req/s benchmarks:

```sh
EXCLUDE_FRAMEWORKS=next-cachecomponents bash ./benchmark-all-mixed.sh
```

Run only selected frameworks:

```sh
INCLUDE_FRAMEWORKS=next-cachecomponents,react-router bash ./benchmark-all.sh
INCLUDE_FRAMEWORKS=next-cachecomponents,react-router bash ./benchmark-all-mixed.sh
```

This uses a mixed e-commerce traffic profile across:

- homepage (`/`)
- search (`/search?q=...`)
- card details (`/cards/:id`)
- game browsing (`/games` and `/games/:slug`)
- sellers (`/sellers` and `/sellers/:slug`)

Defaults in this mode:

- `TARGET_RPS=1000`
- `DURATION_SECONDS=180`

## What `benchmark.sh` Does

1. Installs dependencies for the selected framework
2. Builds the framework
3. Starts it on `127.0.0.1:3042`
4. Runs a built-in local smoke benchmark using repeated HTTP requests
5. Saves results to `results/<framework>-<timestamp>.log`

`benchmark-all-mixed.sh` runs the same lifecycle but uses a Node-based load generator for fixed-rate mixed traffic.

## Cleanup

```sh
./cleanup.sh
```

This stops local benchmark processes and frees port `3042`.
