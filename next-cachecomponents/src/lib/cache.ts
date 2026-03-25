import { cacheLife, cacheTag } from 'next/cache';

export function applyDailyCache(tag: string): void {
    cacheTag(tag);
    cacheLife({
        stale: 86_400,
        revalidate: 86_400,
        expire: 172_800,
    });
}
