import { NextRequest, NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';
import type { CardSearchParams } from '@/lib/types';


export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const q = searchParams.get('q');

  if (!q) {
    return NextResponse.json({ error: 'Search query required' }, { status: 400 });
  }

  const params: CardSearchParams = {
    q,
    page: parseInt(searchParams.get('page') || '1'),
    limit: parseInt(searchParams.get('limit') || '20'),
    sort: (searchParams.get('sort') as CardSearchParams['sort']) || undefined,
    order: (searchParams.get('order') as CardSearchParams['order']) || 'asc',
  };

  const result = await getCachedSearch(params);
  return NextResponse.json(result);
}

async function getCachedSearch(params: CardSearchParams) {
  'use cache';
  applyDailyCache(`api:search:${JSON.stringify(params)}`);
  return db.searchCards(params);
}
