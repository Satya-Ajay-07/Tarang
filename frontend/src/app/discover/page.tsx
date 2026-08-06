'use client';

import React, { useState, useEffect, useRef } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { useRouter } from 'next/navigation';
import { formatDistanceToNow } from 'date-fns';
import { Skeleton, Button, Card } from '@/components/ui';
import Link from 'next/link';

interface PersonResult {
  id: string;
  username: string;
  full_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  is_riding: boolean;
}

interface WaveResult {
  id: string;
  content: string | null;
  creator_id: string;
  created_at: string;
  ripples_count: number;
}

interface CircleResult {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  banner_url: string | null;
}

interface SuggestedRider {
  id: string;
  username: string;
  full_name: string | null;
  avatar_url: string | null;
  bio: string | null;
}

interface TrendingHashtag {
  tag: string;
  count: number;
}

export default function DiscoverPage() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<{
    people: PersonResult[];
    waves: WaveResult[];
    circles: CircleResult[];
  } | null>(null);
  
  const [suggestions, setSuggestions] = useState<SuggestedRider[]>([]);
  const [trendingTags, setTrendingTags] = useState<TrendingHashtag[]>([]);
  const [trendingWaves, setTrendingWaves] = useState<any[]>([]);
  
  const [searching, setSearching] = useState(false);
  const [loadingDefaults, setLoadingDefaults] = useState(true);
  const [tab, setTab] = useState<'all' | 'people' | 'waves' | 'circles'>('all');
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [tagSuggestions, setTagSuggestions] = useState<TrendingHashtag[]>([]);

  // Load defaults (suggested riders, trending tags, popular waves, and local recent searches)
  useEffect(() => {
    const loadDefaults = async () => {
      setLoadingDefaults(true);
      try {
        // Load recent searches from localStorage
        const stored = localStorage.getItem('tarang_recent_searches');
        if (stored) {
          try {
            setRecentSearches(JSON.parse(stored));
          } catch (_) {}
        }

        // Suggested riders
        const ridersRes = await apiRequest('/explore/suggested-riders?limit=5');
        if (ridersRes.ok) setSuggestions(await ridersRes.json());

        // Trending Hashtags
        const tagsRes = await apiRequest('/hashtags/trending?limit=5');
        if (tagsRes.ok) setTrendingTags(await tagsRes.json());

        // Popular waves
        const wavesRes = await apiRequest('/waves?limit=15');
        if (wavesRes.ok) {
          const wavesData = await wavesRes.json();
          // Sort by ripples count desc as a trending heuristic
          const sorted = [...wavesData].sort((a, b) => (b.ripples_count || 0) - (a.ripples_count || 0));
          setTrendingWaves(sorted.slice(0, 4));
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoadingDefaults(false);
      }
    };
    loadDefaults();
  }, []);

  // Search execution & suggestions
  useEffect(() => {
    if (!query.trim()) {
      setResults(null);
      setTagSuggestions([]);
      return;
    }

    const t = setTimeout(async () => {
      setSearching(true);
      try {
        // Fetch global search results
        const res = await apiRequest(`/explore?q=${encodeURIComponent(query)}&kind=${tab}`);
        if (res.ok) setResults(await res.json());

        // Fetch hashtag search suggestions in parallel
        const tagsRes = await apiRequest(`/hashtags/search?q=${encodeURIComponent(query)}&limit=3`);
        if (tagsRes.ok) setTagSuggestions(await tagsRes.json());
      } catch (err) {
        console.error(err);
      } finally {
        setSearching(false);
      }
    }, 350);

    return () => clearTimeout(t);
  }, [query, tab]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;

    // Add query to recent searches
    const updated = [query, ...recentSearches.filter(q => q !== query)].slice(0, 5);
    setRecentSearches(updated);
    localStorage.setItem('tarang_recent_searches', JSON.stringify(updated));
  };

  const handleClearRecent = (qToClear?: string) => {
    if (qToClear) {
      const updated = recentSearches.filter(q => q !== qToClear);
      setRecentSearches(updated);
      localStorage.setItem('tarang_recent_searches', JSON.stringify(updated));
    } else {
      setRecentSearches([]);
      localStorage.removeItem('tarang_recent_searches');
    }
  };

  const handleFollowSuggested = async (id: string) => {
    try {
      const res = await apiRequest(`/users/ride/${id}`, { method: 'POST' });
      if (res.ok) {
        setSuggestions(prev => prev.filter(s => s.id !== id));
      }
    } catch (err) {
      console.error(err);
    }
  };

  const hasResults = results && (
    results.people.length > 0 || results.waves.length > 0 || results.circles.length > 0
  );

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-8 font-body">
        {/* Sticky Header Navbar */}
        <header className="sticky top-16 z-20 flex flex-col border-b border-card-border bg-background/80 backdrop-blur-md p-4 sm:p-5 space-y-4">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-black bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent font-display select-none">
              Explore
            </h1>
          </div>

          {/* Search inputs */}
          <form onSubmit={handleSearchSubmit} className="relative w-full">
            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm select-none">🔍</span>
            <input
              id="discover-search"
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search hashtags, creators, circles..."
              className="w-full rounded-full border border-card-border bg-surface/30 py-2.5 pl-10 pr-10 text-xs outline-none focus:border-primary focus:bg-surface text-text-primary placeholder-text-muted transition-all duration-200"
              autoComplete="off"
            />
            {query && (
              <button
                type="button"
                onClick={() => setQuery('')}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-primary transition-colors text-xs font-bold"
              >
                ✕
              </button>
            )}
          </form>

          {/* Search Category filters */}
          {query && (
            <div className="flex gap-4 border-t border-card-border pt-3 text-xs font-black uppercase tracking-wider text-text-secondary select-none">
              {(['all', 'people', 'waves', 'circles'] as const).map((t) => (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  className={`pb-1 border-b-2 transition-all capitalize ${
                    tab === t
                      ? 'border-primary text-primary'
                      : 'border-transparent hover:text-text-primary'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          )}
        </header>

        {/* Main Feed Container */}
        <div className="p-4 sm:p-6 space-y-6">
          {/* Defaults view when query is empty */}
          {!query && (
            <>
              {/* Recent searches */}
              {recentSearches.length > 0 && (
                <section className="space-y-2">
                  <div className="flex justify-between items-center select-none">
                    <h3 className="text-[10px] font-black uppercase tracking-wider text-text-muted">Recent Searches</h3>
                    <button
                      onClick={() => handleClearRecent()}
                      className="text-[10px] font-bold text-primary hover:underline"
                    >
                      Clear All
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {recentSearches.map((q, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-2 rounded-full border border-card-border bg-surface/30 px-3.5 py-1.5 text-xs font-bold hover:bg-card-border/30 transition-all cursor-pointer"
                        onClick={() => setQuery(q)}
                      >
                        <span className="text-text-primary">{q}</span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleClearRecent(q);
                          }}
                          className="text-text-muted hover:text-danger text-[10px] font-bold"
                        >
                          ✕
                        </button>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Grid split for tags and suggestions */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Trending hashtags */}
                <Card className="space-y-4">
                  <h3 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none border-b border-card-border pb-2">🔥 Trending Hashtags</h3>
                  {loadingDefaults ? (
                    <div className="space-y-3">
                      {[1, 2, 3].map(i => (
                        <div key={i} className="flex justify-between">
                          <Skeleton variant="rect" width={90} height={12} />
                          <Skeleton variant="rect" width={40} height={10} />
                        </div>
                      ))}
                    </div>
                  ) : trendingTags.length === 0 ? (
                    <p className="text-xs text-text-muted font-bold select-none py-2">No hashtags are trending yet.</p>
                  ) : (
                    <div className="divide-y divide-card-border">
                      {trendingTags.map((tag) => (
                        <Link
                          key={tag.tag}
                          href={`/hashtags/${tag.tag.toLowerCase()}`}
                          className="flex justify-between items-center py-2.5 hover:bg-card-border/10 transition-colors first:pt-0 last:pb-0"
                        >
                          <span className="text-xs font-bold text-text-primary hover:text-primary transition-colors">#{tag.tag}</span>
                          <span className="text-[10px] text-text-muted font-bold">{tag.count} waves</span>
                        </Link>
                      ))}
                    </div>
                  )}
                </Card>

                {/* Trending users / suggested riders */}
                <Card className="space-y-4">
                  <h3 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none border-b border-card-border pb-2">👥 Suggested Riders</h3>
                  {loadingDefaults ? (
                    <div className="space-y-3">
                      {[1, 2, 3].map(i => (
                        <div key={i} className="flex items-center gap-3">
                          <Skeleton variant="circle" width={32} height={32} />
                          <Skeleton variant="rect" width={100} height={12} />
                        </div>
                      ))}
                    </div>
                  ) : suggestions.length === 0 ? (
                    <p className="text-xs text-text-muted font-bold select-none py-2">No suggested creators available.</p>
                  ) : (
                    <div className="divide-y divide-card-border">
                      {suggestions.map((rider) => (
                        <div
                          key={rider.id}
                          className="flex items-center justify-between py-2.5 first:pt-0 last:pb-0 gap-3"
                        >
                          <Link href={`/you/${rider.username}`} className="flex items-center gap-2.5 truncate group cursor-pointer">
                            <div className="h-8 w-8 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shrink-0 shadow-sm transition-transform duration-200 group-hover:scale-105">
                              {rider.avatar_url ? (
                                <img src={rider.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                              ) : (
                                rider.username[0].toUpperCase()
                              )}
                            </div>
                            <div className="truncate">
                              <p className="text-xs font-bold leading-none text-text-primary group-hover:underline truncate">{rider.full_name || rider.username}</p>
                              <p className="text-[10px] text-text-muted mt-0.5">@{rider.username}</p>
                            </div>
                          </Link>
                          <Button
                            variant="primary"
                            size="sm"
                            onClick={() => handleFollowSuggested(rider.id)}
                            className="rounded-full px-3.5 py-1 text-[10px] font-bold"
                          >
                            Ride
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </Card>
              </div>

              {/* Popular / Rising waves */}
              <section className="space-y-3">
                <h3 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none">🌊 Rising Waves</h3>
                {loadingDefaults ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[1, 2].map(i => (
                      <div key={i} className="rounded-card border border-card-border bg-card-bg p-4 space-y-3">
                        <Skeleton variant="rect" width="80%" height={12} />
                        <Skeleton variant="rect" width="50%" height={10} />
                      </div>
                    ))}
                  </div>
                ) : trendingWaves.length === 0 ? (
                  <p className="text-xs text-text-muted font-bold select-none py-4 border border-dashed border-card-border rounded-card text-center bg-card-bg/25">No rising waves at the moment.</p>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {trendingWaves.map((wave) => (
                      <Link
                        key={wave.id}
                        href={`/you/${wave.creator?.username || 'user'}`}
                        className="rounded-card border border-card-border bg-card-bg p-4 hover:shadow-md transition-all flex flex-col justify-between space-y-3 group cursor-pointer"
                      >
                        <p className="text-xs text-text-primary line-clamp-3 leading-relaxed font-semibold">{wave.content}</p>
                        <div className="flex justify-between items-center text-[9px] text-text-muted font-bold pt-2 border-t border-card-border">
                          <span className="group-hover:underline">@{wave.creator?.username || 'creator'}</span>
                          <span>💙 {wave.ripples_count} ripples</span>
                        </div>
                      </Link>
                    ))}
                  </div>
                )}
              </section>
            </>
          )}

          {/* Search Suggestions dropdown wrapper */}
          {query && tagSuggestions.length > 0 && (
            <Card className="p-3 space-y-2 border-primary/20 bg-primary/5 select-none animate-in fade-in slide-in-from-top-1 duration-200">
              <h4 className="text-[9px] font-black uppercase tracking-wider text-primary">Tag Suggestions</h4>
              <div className="flex flex-wrap gap-2">
                {tagSuggestions.map(tag => (
                  <Link
                    key={tag.tag}
                    href={`/hashtags/${tag.tag.toLowerCase()}`}
                    className="text-xs font-bold text-primary hover:underline bg-surface px-2.5 py-1 rounded-full border border-primary/10 shadow-sm"
                  >
                    #{tag.tag} ({tag.count})
                  </Link>
                ))}
              </div>
            </Card>
          )}

          {/* Search Indicator Spinner */}
          {query && searching && (
            <div className="text-center py-10">
              <svg className="animate-spin h-6 w-6 text-primary mx-auto" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            </div>
          )}

          {/* Empty Search results state */}
          {query && !searching && results && !hasResults && (
            <div className="text-center py-16 space-y-3.5 border border-dashed border-card-border rounded-card bg-card-bg/25 select-none animate-in fade-in duration-200">
              <div className="text-4xl animate-bounce">🌊</div>
              <h3 className="text-sm font-bold text-text-secondary font-display">Nothing matches "{query}"</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                No matching hashtags, creators, or wave content was found. Try searching for other currents.
              </p>
            </div>
          )}

          {/* Search Result panels */}
          {results && !searching && hasResults && (
            <div className="space-y-6 animate-in fade-in duration-250">
              {/* Matching People list */}
              {results.people.length > 0 && (tab === 'all' || tab === 'people') && (
                <section className="space-y-3">
                  <h2 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none">Creators</h2>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {results.people.map((p) => {
                      const [riding, setRiding] = useState(p.is_riding);
                      const [loadingFollow, setLoadingFollow] = useState(false);

                      const handleRideToggle = async (e: React.MouseEvent) => {
                        e.stopPropagation();
                        setLoadingFollow(true);
                        try {
                          const res = await apiRequest(`/users/ride/${p.id}`, { method: 'POST' });
                          if (res.ok) {
                            const data = await res.ok && await res.json();
                            setRiding(data.riding);
                          }
                        } finally {
                          setLoadingFollow(false);
                        }
                      };

                      return (
                        <Card key={p.id} className="flex items-center justify-between p-4 gap-3">
                          <Link href={`/you/${p.username}`} className="flex items-center gap-3 min-w-0 group cursor-pointer truncate">
                            <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-sm font-bold overflow-hidden shrink-0 shadow-sm">
                              {p.avatar_url ? (
                                <img src={p.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                              ) : (
                                p.username[0].toUpperCase()
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="text-xs font-bold leading-none group-hover:underline text-text-primary truncate">
                                {p.full_name || p.username}
                              </p>
                              <p className="text-[10px] text-text-muted mt-1 font-semibold truncate">@{p.username}</p>
                            </div>
                          </Link>
                          <Button
                            variant={riding ? 'secondary' : 'primary'}
                            size="sm"
                            loading={loadingFollow}
                            onClick={handleRideToggle}
                            className="rounded-full px-4 py-1 text-[10px] font-bold"
                          >
                            {riding ? 'Riding' : 'Ride'}
                          </Button>
                        </Card>
                      );
                    })}
                  </div>
                </section>
              )}

              {/* Matching Waves list */}
              {results.waves.length > 0 && (tab === 'all' || tab === 'waves') && (
                <section className="space-y-3">
                  <h2 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none">Waves</h2>
                  <div className="space-y-3">
                    {results.waves.map((w) => (
                      <Card key={w.id} className="space-y-2">
                        <p className="text-xs text-text-primary leading-relaxed font-semibold">{w.content}</p>
                        <div className="flex gap-4 text-[9px] text-text-muted font-bold pt-2 border-t border-card-border select-none">
                          <span>💙 {w.ripples_count} ripples</span>
                          <span>{formatDistanceToNow(new Date(w.created_at + "Z"), { addSuffix: true })}</span>
                        </div>
                      </Card>
                    ))}
                  </div>
                </section>
              )}

              {/* Matching Circles list */}
              {results.circles.length > 0 && (tab === 'all' || tab === 'circles') && (
                <section className="space-y-3">
                  <h2 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none">Circles</h2>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {results.circles.map((c) => (
                      <Card
                        key={c.id}
                        onClick={() => router.push(`/circles/${c.slug}`)}
                        className="flex items-center gap-3 p-4 cursor-pointer hover:shadow-md transition-all"
                      >
                        <div className="h-9 w-9 rounded-full bg-gradient-to-br from-secondary to-primary flex items-center justify-center text-white font-black text-sm shrink-0 shadow-sm select-none">
                          {c.name[0]}
                        </div>
                        <div className="min-w-0">
                          <p className="text-xs font-bold text-text-primary truncate">{c.name}</p>
                          {c.description && (
                            <p className="text-[10px] text-text-muted mt-0.5 line-clamp-1 font-semibold">{c.description}</p>
                          )}
                        </div>
                      </Card>
                    ))}
                  </div>
                </section>
              )}
            </div>
          )}
        </div>
      </div>
    </MainAppLayout>
  );
}
