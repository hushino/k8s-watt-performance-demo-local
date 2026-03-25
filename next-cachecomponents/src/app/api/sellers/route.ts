import { NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET() {
  const sellers = await getCachedSellers();
  return NextResponse.json(sellers);
}

async function getCachedSellers() {
  'use cache';
  applyDailyCache('api:sellers');
  return db.getSellers();
}
