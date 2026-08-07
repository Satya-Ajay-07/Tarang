'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '@/services/api';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

// ── Types ─────────────────────────────────────────────────────────────────────

interface TrendingHashtag {
  tag: string;
  count: number;
  ripples?: number;
  score?: number;
  category?: 'trending_now' | 'rising' | 'popular_this_week';
}

interface TrendingWave {
  id: string;
  content: string | null;
  creator?: { username?: string };
  ripples_count?: number;
  spreads_count?: number;
  trending_category?: string;
  trending_score?: number;
}

type ActiveTab = 'trending_now' | 'rising' | 'popular_this_week';

// ── Category Metadata ─────────────────────────────────────────────────────────

const CATEGORIES: Record<ActiveTab, { label: string; icon: string; description: string }> = {
  trending_now:       { label: 'Trending Now',  icon: '🔥', description: 'Hot in the last 6 hours' },
  rising:             { label: 'Rising',        icon: '📈', description: 'Gaining momentum' },
  popular_this_week:  { label: 'This Week',     icon: '⭐', description: 'Popular this week' },
};

// ── Skeleton component ────────────────────────────────────────────────────────

function TrendingSkeleton() {
  return (
    <div className="space-y-3 animate-pulse">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="flex items-center gap-2.5">
          <div className="h-7 w-7 rounded-lg bg-text-muted/10 shrink-0" />
          <div className="flex-1 space-y-1.5">
            <div className="h-3 w-24 rounded bg-text-muted/10" />
            <div className="h-2.5 w-16 rounded bg-text-muted/8" />
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Main Widget ───────────────────────────────────────────────────────────────

export function TrendingWidget() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<ActiveTab>('trending_now');
  const [hashtags, setHashtags] = useState<TrendingHashtag[]>([]);
  const [waves, setWaves] = useState<TrendingWave[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const fetchTrending = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const [tagsRes, wavesRes] = await Promise.all([
        apiRequest('/hashtags/trending?limit=15'),
        apiRequest('/waves/trending?limit=8'),
      ]);

      if (tagsRes.ok) {
        const all: TrendingHashtag[] = await tagsRes.json();
        setHashtags(all);
      }
      if (wavesRes.ok) {
        const allWaves: TrendingWave[] = await wavesRes.json();
        setWaves(allWaves);
      }
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTrending();
  }, [fetchTrending]);

  // Filter hashtags by active tab — if no category field, show all in every tab
  const filteredTags = hashtags.filter(
    (h) => !h.category || h.category === activeTab
  );
  const filteredWaves = waves.filter(
    (w) => !w.trending_category || w.trending_category === activeTab
  );

  const catMeta = CATEGORIES[activeTab];

  return (
    <div className="rounded-card border border-card-border bg-card-bg shadow-sm overflow-hidden">
      {/* Header */}
      <div className="px-4 pt-4 pb-3 border-b border-card-border/60">
        <div className="flex items-center justify-between mb-3">
          <h4 className="text-xs font-bold uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
            <span>🔥</span> Trending
          </h4>
          <Link
            href="/trending"
            className="text-[10px] font-bold text-primary hover:underline"
          >
            See all →
          </Link>
        </div>

        {/* Tab pills */}
        <div className="flex gap-1.5">
          {(Object.entries(CATEGORIES) as [ActiveTab, typeof CATEGORIES[ActiveTab]][]).map(([key, meta]) => (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`
                px-2.5 py-1 rounded-full text-[10px] font-bold whitespace-nowrap transition-all
                ${activeTab === key
                  ? 'bg-primary text-white shadow-sm'
                  : 'bg-primary/8 text-text-secondary hover:bg-primary/15'
                }
              `}
            >
              {meta.icon} {meta.label}
            </button>
          ))}
        </div>
      </div>

      {/* Body */}
      <div className="p-4 space-y-5">
        {loading ? (
          <TrendingSkeleton />
        ) : error ? (
          <div className="text-center py-4">
            <p className="text-xs text-text-muted">Could not load trending topics.</p>
            <button
              onClick={fetchTrending}
              className="mt-2 text-[10px] text-primary hover:underline font-bold"
            >
              Retry
            </button>
          </div>
        ) : (
          <>
            {/* Trending Hashtags */}
            {filteredTags.length > 0 && (
              <div className="space-y-2.5">
                <p className="text-[10px] font-bold uppercase tracking-wider text-text-muted"># Hashtags</p>
                {filteredTags.slice(0, 5).map((ht, i) => (
                  <button
                    key={ht.tag}
                    onClick={() => router.push(`/hashtags/${ht.tag}`)}
                    className="w-full flex items-center gap-2.5 group text-left hover:bg-primary/4 rounded-xl p-1.5 -mx-1.5 transition-colors"
                  >
                    <div className="h-7 w-7 rounded-lg bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center text-[10px] font-black text-primary shrink-0">
                      #{i + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-bold text-text-primary group-hover:text-primary transition-colors truncate">
                        #{ht.tag}
                      </p>
                      <p className="text-[10px] text-text-muted">
                        {ht.count} wave{ht.count !== 1 ? 's' : ''}
                        {ht.ripples ? ` · ${ht.ripples} 💙` : ''}
                      </p>
                    </div>
                    {ht.category === 'trending_now' && (
                      <span className="text-[9px] bg-red-500/10 text-red-500 font-black px-1.5 py-0.5 rounded-full shrink-0">
                        HOT
                      </span>
                    )}
                    {ht.category === 'rising' && (
                      <span className="text-[9px] bg-green-500/10 text-green-500 font-black px-1.5 py-0.5 rounded-full shrink-0">
                        ↑
                      </span>
                    )}
                  </button>
                ))}
              </div>
            )}

            {/* Trending Waves */}
            {filteredWaves.length > 0 && (
              <div className="space-y-2.5">
                <p className="text-[10px] font-bold uppercase tracking-wider text-text-muted">🌊 Trending Waves</p>
                {filteredWaves.slice(0, 3).map((wave) => (
                  <div
                    key={wave.id}
                    className="space-y-1 border-b border-card-border/40 pb-2.5 last:border-none last:pb-0"
                  >
                    <p className="text-xs text-text-secondary line-clamp-2 leading-relaxed font-medium">
                      {wave.content}
                    </p>
                    <div className="flex items-center justify-between text-[9px] text-text-muted font-bold">
                      <span>@{wave.creator?.username || 'user'}</span>
                      <span>💙 {wave.ripples_count || 0} · 🔁 {wave.spreads_count || 0}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Empty state */}
            {filteredTags.length === 0 && filteredWaves.length === 0 && (
              <div className="text-center py-6 space-y-2">
                <div className="text-3xl">{catMeta.icon}</div>
                <p className="text-xs font-bold text-text-muted">Nothing trending here yet.</p>
                <p className="text-[10px] text-text-muted">{catMeta.description}</p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

