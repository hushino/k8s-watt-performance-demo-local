import { NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET(
  _request: Request,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const game = await getCachedGame(slug);

  if (!game) {
    return NextResponse.json({ error: 'Game not found' }, { status: 404 });
  }

  return NextResponse.json(game);
}

async function getCachedGame(slug: string) {
  'use cache';
  applyDailyCache(`api:game:${slug}`);
  return db.getGameWithSets(slug);
}
