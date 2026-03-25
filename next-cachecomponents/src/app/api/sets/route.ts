import { NextRequest, NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const gameSlug = searchParams.get('game');

  let gameId: string | undefined;
  if (gameSlug) {
    const game = await db.getGameBySlug(gameSlug);
    gameId = game?.id;
  }

  const sets = await getCachedSets(gameId);
  return NextResponse.json(sets);
}

async function getCachedSets(gameId?: string) {
  'use cache';
  applyDailyCache(`api:sets:${gameId || 'all'}`);
  return db.getSets(gameId);
}
