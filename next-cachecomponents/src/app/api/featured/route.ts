import { NextResponse } from 'next/server';
import { applyDailyCache } from '@/lib/cache';
import { db } from '@/lib/db';


export async function GET() {
  const featuredData = await getCachedFeatured();

  return NextResponse.json(featuredData);
}

async function getCachedFeatured() {
  'use cache';
  applyDailyCache('api:featured');

  const [featured, trendingCards, newReleases, games] = await Promise.all([
    db.getFeatured(),
    db.getTrendingCards(12),
    db.getNewReleaseSets(5),
    db.getGames(),
  ]);

  return {
    ...featured,
    trendingCardsData: trendingCards,
    newReleasesData: newReleases,
    popularGamesData: games,
  };
}
