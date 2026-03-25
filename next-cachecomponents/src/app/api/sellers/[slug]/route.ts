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

  const seller = await getCachedSeller(slug, page, limit);

  if (!seller) {
    return NextResponse.json({ error: 'Seller not found' }, { status: 404 });
  }

  return NextResponse.json(seller);
}

async function getCachedSeller(slug: string, page: number, limit: number) {
  'use cache';
  applyDailyCache(`api:seller:${slug}:${page}:${limit}`);
  return db.getSellerWithListings(slug, page, limit);
}
