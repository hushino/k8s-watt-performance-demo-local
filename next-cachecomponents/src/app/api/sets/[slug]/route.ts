import { NextRequest, NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const searchParams = request.nextUrl.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');

  const set = await getCachedSet(slug, page, limit);

  if (!set) {
    return NextResponse.json({ error: 'Set not found' }, { status: 404 });
  }

  return NextResponse.json(set);
}

async function getCachedSet(slug: string, page: number, limit: number) {
  'use cache';
  applyDailyCache(`api:set:${slug}:${page}:${limit}`);
  return db.getSetWithCards(slug, page, limit);
}
