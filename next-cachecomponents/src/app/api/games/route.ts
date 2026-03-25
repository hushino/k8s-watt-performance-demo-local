import { NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET() {
  const games = await getCachedGames();
  return NextResponse.json(games);
}

async function getCachedGames() {
  'use cache';
  applyDailyCache('api:games');
  return db.getGames();
}
