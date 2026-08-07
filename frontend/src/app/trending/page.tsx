'use client';

import React, { useState, useEffect, useCallback } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { useRouter } from 'next/navigation';

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
  creator?: { username?: string; full_name?: string; avatar_url?: string | null };
  ripples_count?: number;
  spreads_count?: number;
  joins_count?: number;
  created_at?: string;
  trending_category?: string;
  trending_score?: number;
  hashtags?: { tag: string }[];
}

type Category = 'all' | 'trending_now' | 'rising' | 'popular_this_week';

const CATEGORIES: Record<Category, { label: string; icon: string; description: string }> = {
  all:                { label: 'All',           icon: '🌊', description: 'All trending topics' },
  trending_now:       { label: 'Trending Now',  icon: '🔥', description: 'Hot in the last 6 hours' },
  rising:             { label: 'Rising',        icon: '📈', description: 'Gaining momentum (< 48h)' },
  popular_this_week:  { label: 'This Week',     icon: '⭐', description: 'Popular this week' },
};

// ── Skeleton ──────────────────────────────────────────────────────────────────

function HashtagSkeleton() {
  return (
    <div className="animate-pulse grid grid-cols-2 sm:grid-cols-3 gap-3">
      {[...Array(9)].map((_, i) => (
        <div key={i} className="rounded-2xl border border-card-border p-4 space-y-2.5 bg-card-bg">
          <div className="h-4 w-16 rounded bg-text-muted/10" />
          <div className="h-3 w-10 rounded bg-text-muted/8" />
        </div>
      ))}
    </div>
  );
}

function WaveSkeleton() {
  return (
    <div className="animate-pulse space-y-3">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="rounded-2xl border border-card-border p-4 bg-card-bg space-y-3">
          <div className="flex items-center gap-2.5">
            <div className="h-9 w-9 rounded-full bg-text-muted/10" />
            <div className="space-y-1.5 flex-1">
              <div className="h-3 w-24 rounded bg-text-muted/10" />
              <div className="h-2.5 w-16 rounded bg-text-muted/8" />
            </div>
          </div>
          <div className="h-3 w-full rounded bg-text-muted/8" />
          <div className="h-3 w-3/4 rounded bg-text-muted/6" />
        </div>
      ))}
    </div>
  );
}

// ── Hashtag card ──────────────────────────────────────────────────────────────

function HashtagCard({ ht, rank, onClick }: { ht: TrendingHashtag; rank: number; onClick: () => void }) {
  const isHot = ht.category === 'trending_now';
  const isRising = ht.category === 'rising';

  return (
    <button
      onClick={onClick}
      className="group text-left w-full rounded-2xl border border-card-border bg-card-bg hover:border-primary/40 hover:shadow-lg hover:shadow-primary/5 transition-all duration-200 p-4 space-y-2.5 active:scale-95"
    >
      <div className="flex items-start justify-between gap-1">
        <span className="text-xl font-black text-text-muted/40">#{rank}</span>
        <div className="flex gap-1 items-center">
          {isHot && (
            <span className="text-[9px] bg-red-500/10 text-red-500 font-black px-1.5 py-0.5 rounded-full">
              🔥 HOT
            </span>
          )}
          {isRising && (
            <span className="text-[9px] bg-emerald-500/10 text-emerald-500 font-black px-1.5 py-0.5 rounded-full">
              📈 RISING
            </span>
          )}
        </div>
      </div>
      <div>
        <p className="text-sm font-black text-text-primary group-hover:text-primary transition-colors truncate">
          #{ht.tag}
        </p>
        <p className="text-[11px] text-text-muted mt-0.5">
          {ht.count} wave{ht.count !== 1 ? 's' : ''}
          {ht.ripples ? ` · ${ht.ripples} 💙` : ''}
        </p>
        {ht.score !== undefined && (
          <div className="mt-2 h-1 rounded-full bg-text-muted/10 overflow-hidden">
            <div
              className="h-full rounded-full bg-gradient-to-r from-primary to-secondary transition-all duration-500"
              style={{ width: `${Math.min(ht.score * 20, 100)}%` }}
            />
          </div>
        )}
      </div>
    </button>
  );
}

// ── Wave card (minimal trending version) ─────────────────────────────────────

function TrendingWaveCard({ wave, rank }: { wave: TrendingWave; rank: number }) {
  const router = useRouter();
  const isHot = wave.trending_category === 'trending_now';
  const isRising = wave.trending_category === 'rising';
  const avatar = wave.creator?.avatar_url;
  const handle = wave.creator?.username || 'user';
  const displayName = wave.creator?.full_name || handle;

  return (
    <div className="rounded-2xl border border-card-border bg-card-bg hover:border-primary/30 transition-all duration-200 p-4 space-y-3">
      {/* Meta row */}
      <div className="flex items-start gap-3">
        <div className="h-9 w-9 rounded-full bg-gradient-to-br from-secondary to-primary flex items-center justify-center text-white text-sm font-bold overflow-hidden shrink-0">
          {avatar ? (
            <img src={avatar} alt={handle} className="h-full w-full object-cover" loading="lazy" />
          ) : (
            handle[0]?.toUpperCase()
          )}
        </div>
        <div className="flex-1 min-w-0">
          <button
            onClick={() => router.push(`/you/${handle}`)}
            className="text-xs font-bold text-text-primary hover:text-primary transition-colors truncate block"
          >
            {displayName}
          </button>
          <span className="text-[10px] text-text-muted">@{handle}</span>
        </div>
        <div className="flex gap-1 shrink-0">
          <span className="text-[9px] bg-text-muted/10 text-text-muted font-black px-1.5 py-0.5 rounded-full">
            #{rank}
          </span>
          {isHot && (
            <span className="text-[9px] bg-red-500/10 text-red-500 font-black px-1.5 py-0.5 rounded-full">🔥</span>
          )}
          {isRising && (
            <span className="text-[9px] bg-emerald-500/10 text-emerald-500 font-black px-1.5 py-0.5 rounded-full">📈</span>
          )}
        </div>
      </div>

      {/* Content */}
      {wave.content && (
        <p className="text-sm text-text-secondary leading-relaxed line-clamp-3">
          {wave.content}
        </p>
      )}

      {/* Hashtags */}
      {wave.hashtags && wave.hashtags.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {wave.hashtags.slice(0, 4).map((h) => (
            <button
              key={h.tag}
              onClick={() => router.push(`/hashtags/${h.tag}`)}
              className="text-[10px] font-bold text-primary hover:underline"
            >
              #{h.tag}
            </button>
          ))}
        </div>
      )}

      {/* Stats */}
      <div className="flex items-center gap-4 text-[10px] text-text-muted font-bold pt-0.5">
        <span>💙 {wave.ripples_count || 0}</span>
        <span>🔁 {wave.spreads_count || 0}</span>
        <span>💬 {wave.joins_count || 0}</span>
        {wave.trending_score !== undefined && (
          <span className="ml-auto text-primary/60">⚡ {wave.trending_score.toFixed(2)}</span>
        )}
      </div>
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function TrendingPage() {
  const router = useRouter();
  const [activeCategory, setActiveCategory] = useState<Category>('all');
  const [hashtags, setHashtags] = useState<TrendingHashtag[]>([]);
  const [waves, setWaves] = useState<TrendingWave[]>([]);
  const [loadingTags, setLoadingTags] = useState(true);
  const [loadingWaves, setLoadingWaves] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoadingTags(true);
    setLoadingWaves(true);
    setError(null);
    try {
      const [tagsRes, wavesRes] = await Promise.all([
        apiRequest('/hashtags/trending?limit=30'),
        apiRequest('/waves/trending?limit=20'),
      ]);

      if (tagsRes.ok) {
        setHashtags(await tagsRes.json());
      } else {
        setError('Could not load trending hashtags.');
      }
      setLoadingTags(false);

      if (wavesRes.ok) {
        setWaves(await wavesRes.json());
      } else {
        setError((prev) => prev ?? 'Could not load trending waves.');
      }
      setLoadingWaves(false);
    } catch {
      setError('Network error. Please try again.');
      setLoadingTags(false);
      setLoadingWaves(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Filter by active category
  const filteredTags = activeCategory === 'all'
    ? hashtags
    : hashtags.filter((h) => h.category === activeCategory);

  const filteredWaves = activeCategory === 'all'
    ? waves
    : waves.filter((w) => w.trending_category === activeCategory);

  return (
    <MainAppLayout>
      <div className="space-y-6 pb-12">
        {/* Page Header */}
        <div className="space-y-1">
          <h1 className="text-2xl font-black text-text-primary flex items-center gap-2">
            🔥 Trending
          </h1>
          <p className="text-sm text-text-muted">
            What's making waves right now across Tarang
          </p>
        </div>

        {/* Category Tabs */}
        <div className="flex gap-2 overflow-x-auto scrollbar-none pb-0.5">
          {(Object.entries(CATEGORIES) as [Category, typeof CATEGORIES[Category]][]).map(([key, meta]) => (
            <button
              key={key}
              onClick={() => setActiveCategory(key)}
              className={`
                px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all duration-200
                ${activeCategory === key
                  ? 'bg-primary text-white shadow-md shadow-primary/20'
                  : 'bg-card-bg border border-card-border text-text-secondary hover:border-primary/40 hover:text-primary'
                }
              `}
            >
              {meta.icon} {meta.label}
            </button>
          ))}
        </div>

        {/* Error Banner */}
        {error && (
          <div className="rounded-2xl border border-red-500/20 bg-red-500/5 p-4 flex items-center justify-between">
            <p className="text-sm text-red-500 font-medium">{error}</p>
            <button
              onClick={fetchData}
              className="text-xs font-bold text-red-500 hover:underline ml-4 shrink-0"
            >
              Retry
            </button>
          </div>
        )}

        {/* Trending Hashtags Section */}
        <section className="space-y-3">
          <h2 className="text-sm font-black uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
            <span>#</span> Trending Hashtags
          </h2>
          {loadingTags ? (
            <HashtagSkeleton />
          ) : filteredTags.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {filteredTags.map((ht, i) => (
                <HashtagCard
                  key={ht.tag}
                  ht={ht}
                  rank={i + 1}
                  onClick={() => router.push(`/discover?q=${encodeURIComponent('#' + ht.tag)}`)}
                />
              ))}
            </div>
          ) : (
            <div className="rounded-2xl border border-dashed border-card-border p-10 text-center space-y-2">
              <div className="text-3xl">🔍</div>
              <p className="text-sm font-bold text-text-muted">No trending hashtags found</p>
              <p className="text-xs text-text-muted">
                {CATEGORIES[activeCategory].description}
              </p>
            </div>
          )}
        </section>

        {/* Trending Waves Section */}
        <section className="space-y-3">
          <h2 className="text-sm font-black uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
            <span>🌊</span> Trending Waves
          </h2>
          {loadingWaves ? (
            <WaveSkeleton />
          ) : filteredWaves.length > 0 ? (
            <div className="space-y-3">
              {filteredWaves.map((wave, i) => (
                <TrendingWaveCard key={wave.id} wave={wave} rank={i + 1} />
              ))}
            </div>
          ) : (
            <div className="rounded-2xl border border-dashed border-card-border p-10 text-center space-y-2">
              <div className="text-3xl">🌊</div>
              <p className="text-sm font-bold text-text-muted">No trending waves found</p>
              <p className="text-xs text-text-muted">
                {CATEGORIES[activeCategory].description}
              </p>
            </div>
          )}
        </section>
      </div>
    </MainAppLayout>
  );
}

