#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'

const targetBaseUrl = process.env.TARGET_BASE_URL || 'http://127.0.0.1:3042'
const framework = process.env.FRAMEWORK || 'unknown'
const dataDir = process.env.DATA_DIR || ''
const requestRate = Number.parseInt(process.env.REQUEST_RATE || '1000', 10)
const durationSeconds = Number.parseInt(process.env.DURATION_SECONDS || '180', 10)
const maxInFlight = Number.parseInt(process.env.MAX_IN_FLIGHT || '2000', 10)

if (!Number.isFinite(requestRate) || requestRate <= 0) {
  console.error('REQUEST_RATE must be a positive integer')
  process.exit(1)
}

if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
  console.error('DURATION_SECONDS must be a positive integer')
  process.exit(1)
}

const readJson = (fileName) => {
  if (!dataDir) return []
  try {
    const full = path.join(dataDir, fileName)
    return JSON.parse(fs.readFileSync(full, 'utf8'))
  } catch {
    return []
  }
}

const pickRandom = (arr, fallback) => {
  if (!Array.isArray(arr) || arr.length === 0) return fallback
  return arr[Math.floor(Math.random() * arr.length)]
}

const cards = readJson('cards.json')
const games = readJson('games.json')
const sellers = readJson('sellers.json')

const randomCardId = () => String(pickRandom(cards, { id: 1 }).id || 1)
const randomGameSlug = () => String(pickRandom(games, { slug: 'games' }).slug || 'games')
const randomSellerSlug = () => String(pickRandom(sellers, { slug: 'seller' }).slug || 'seller')

const routeDefinitions = [
  { key: 'homepage', weight: 0.25, path: () => '/' },
  { key: 'search', weight: 0.2, path: () => `/search?q=${encodeURIComponent(pickRandom(['pokemon', 'rare', 'booster', 'vintage'], 'pokemon'))}` },
  { key: 'card_details', weight: 0.2, path: () => `/cards/${encodeURIComponent(randomCardId())}` },
  { key: 'game_browsing', weight: 0.2, path: () => (Math.random() < 0.5 ? '/games' : `/games/${encodeURIComponent(randomGameSlug())}`) },
  { key: 'sellers', weight: 0.15, path: () => (Math.random() < 0.6 ? '/sellers' : `/sellers/${encodeURIComponent(randomSellerSlug())}`) },
]

const cumulativeRoutes = []
let cumulative = 0
for (const route of routeDefinitions) {
  cumulative += route.weight
  cumulativeRoutes.push({ ...route, cumulative })
}

const pickRoute = () => {
  const r = Math.random()
  for (const route of cumulativeRoutes) {
    if (r <= route.cumulative) return route
  }
  return cumulativeRoutes[cumulativeRoutes.length - 1]
}

const stats = {
  sent: 0,
  completed: 0,
  success: 0,
  failed: 0,
  dropped: 0,
  minMs: Number.POSITIVE_INFINITY,
  maxMs: 0,
  totalMs: 0,
  byRoute: Object.fromEntries(routeDefinitions.map((r) => [r.key, { sent: 0, success: 0, failed: 0 }])),
  byStatus: {},
}

let inFlight = 0
const pending = new Set()
const startedAt = Date.now()
const endsAt = startedAt + durationSeconds * 1000

const updateLatency = (ms) => {
  if (ms < stats.minMs) stats.minMs = ms
  if (ms > stats.maxMs) stats.maxMs = ms
  stats.totalMs += ms
}

const sendRequest = async (routeKey, routePath) => {
  const url = `${targetBaseUrl}${routePath}`
  const start = performance.now()

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'cache-control': 'no-cache',
      },
    })

    const elapsedMs = performance.now() - start
    updateLatency(elapsedMs)

    const code = String(res.status)
    stats.byStatus[code] = (stats.byStatus[code] || 0) + 1

    if (res.status >= 200 && res.status < 400) {
      stats.success += 1
      stats.byRoute[routeKey].success += 1
    } else {
      stats.failed += 1
      stats.byRoute[routeKey].failed += 1
    }
  } catch {
    const elapsedMs = performance.now() - start
    updateLatency(elapsedMs)
    stats.failed += 1
    stats.byRoute[routeKey].failed += 1
    stats.byStatus['ERR'] = (stats.byStatus['ERR'] || 0) + 1
  } finally {
    stats.completed += 1
  }
}

const launch = (routeKey, routePath) => {
  inFlight += 1
  const p = sendRequest(routeKey, routePath)
    .finally(() => {
      inFlight -= 1
      pending.delete(p)
    })
  pending.add(p)
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

const run = async () => {
  const tickMs = 100
  const targetPerTick = (requestRate * tickMs) / 1000
  let carry = 0

  while (Date.now() < endsAt) {
    let dispatch = targetPerTick + carry
    const whole = Math.floor(dispatch)
    carry = dispatch - whole

    for (let i = 0; i < whole; i += 1) {
      const route = pickRoute()
      const routePath = route.path()
      if (inFlight >= maxInFlight) {
        stats.dropped += 1
        continue
      }

      stats.sent += 1
      stats.byRoute[route.key].sent += 1
      launch(route.key, routePath)
    }

    await sleep(tickMs)
  }

  // Wait for outstanding requests to finish.
  await Promise.allSettled([...pending])

  const wallClockSeconds = (Date.now() - startedAt) / 1000
  const avgMs = stats.completed > 0 ? stats.totalMs / stats.completed : 0
  const achievedRps = wallClockSeconds > 0 ? stats.completed / wallClockSeconds : 0

  console.log('========================================================================')
  console.log('MIXED LOCAL BENCHMARK RESULT')
  console.log('========================================================================')
  console.log(`framework=${framework}`)
  console.log(`target=${targetBaseUrl}`)
  console.log(`traffic_profile=mixed_ecommerce`) 
  console.log(`target_rps=${requestRate}`)
  console.log(`duration_seconds=${durationSeconds}`)
  console.log(`wall_clock_seconds=${wallClockSeconds.toFixed(2)}`)
  console.log(`sent=${stats.sent}`)
  console.log(`completed=${stats.completed}`)
  console.log(`success=${stats.success}`)
  console.log(`failed=${stats.failed}`)
  console.log(`dropped=${stats.dropped}`)
  console.log(`achieved_rps=${achievedRps.toFixed(2)}`)
  console.log(`avg_ms=${avgMs.toFixed(2)}`)
  console.log(`min_ms=${Number.isFinite(stats.minMs) ? stats.minMs.toFixed(2) : '0.00'}`)
  console.log(`max_ms=${stats.maxMs.toFixed(2)}`)

  console.log('status_codes=')
  for (const code of Object.keys(stats.byStatus).sort()) {
    console.log(`  ${code}: ${stats.byStatus[code]}`)
  }

  console.log('route_mix=')
  for (const route of routeDefinitions) {
    const routeStat = stats.byRoute[route.key]
    console.log(
      `  ${route.key}: sent=${routeStat.sent} success=${routeStat.success} failed=${routeStat.failed} weight=${route.weight}`,
    )
  }
  console.log('========================================================================')
}

run().catch((err) => {
  console.error(err)
  process.exit(1)
})
