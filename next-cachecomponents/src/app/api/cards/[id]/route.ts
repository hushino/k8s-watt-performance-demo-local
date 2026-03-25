import { NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const card = await getCachedCard(id);

  if (!card) {
    return NextResponse.json({ error: 'Card not found' }, { status: 404 });
  }

  return NextResponse.json(card);
}

async function getCachedCard(id: string) {
  'use cache';
  applyDailyCache(`api:card:${id}`);
  return db.getCardWithListings(id);
}
