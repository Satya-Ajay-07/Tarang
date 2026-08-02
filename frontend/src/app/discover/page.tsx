'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { useRouter } from 'next/navigation';
import { formatDistanceToNow } from 'date-fns';
import { Avatar, Button } from '@/components/ui';
import Link from 'next/link';

// ─── Types ────────────────────────────────────────────────────────────────────

interface SearchResults {
  query: string;
  people: PersonResult[];
  waves: WaveResult[];
  circles: CircleResult[];
}

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

// ─── Search Highlight ─────────────────────────────────────────────────────────

/**
 * Highlight wraps occurrences of `term` inside `text` with a <mark> element.
 * Escapes the term to avoid regex injection, splits case-insensitively.
 */
function Highlight({ text, term }: { text: string; term: string }) {
  if (!term || !text) return <>{text}</>;
  const escapedTerm = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const regex = new RegExp(`(${escapedTerm})`, 'gi');
  const parts = text.split(regex);
  return (
    <>
      {parts.map((part, i) =>
        part.toLowerCase() === term.toLowerCase() ? (
          <mark
            key={i}
            className="bg-aqua/20 text-aqua rounded px-0.5 font-semibold not-italic"
          >
            {part}
          </mark>
        ) : (
          <span key={i}>{part}</span>
        )
      )}
    </>
  );
}

// ─── Person Card ──────────────────────────────────────────────────────────────

function PersonCard({ person, query }: { person: PersonResult; query: string }) {
  const [riding, setRiding] = useState(person.is_riding);
  const [loading, setLoading] = useState(false);

  const toggle = async () => {
    setLoading(true);
    try {
      const res = await apiRequest(`/users/ride/${person.id}`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setRiding(data.riding);
      }
    } finally {
      setLoading(false);
    }
  };

  const displayName = person.full_name || person.username;

  return (
    <div className="flex items-center justify-between rounded-2xl border border-card-border bg-card-bg p-4">
      <Link href={`/you/${person.username}`} className="flex items-center gap-3 min-w-0 group cursor-pointer">
        <Avatar username={person.username} avatar_url={person.avatar_url} size="md" />
        <div className="min-w-0">
          <p className="text-sm font-bold leading-none truncate group-hover:underline text-text-primary">
            <Highlight text={displayName} term={query} />
          </p>
          <p className="text-xs text-text-secondary mt-0.5">
            @<Highlight text={person.username} term={query} />
          </p>
          {person.bio && (
            <p className="text-xs text-text-muted mt-0.5 line-clamp-1">
              <Highlight text={person.bio} term={query} />
            </p>
          )}
        </div>
      </Link>
      <Button
        variant={riding ? 'secondary' : 'primary'}
        size="sm"
        loading={loading}
        onClick={toggle}
        className="ml-3 shrink-0"
      >
        {riding ? 'Riding' : 'Ride'}
      </Button>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function DiscoverPage() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResults | null>(null);
  const [suggestions, setSuggestions] = useState<SuggestedRider[]>([]);
  const [searching, setSearching] = useState(false);
  const [tab, setTab] = useState<'all' | 'people' | 'waves' | 'circles'>('all');

  // Load suggested riders on mount
  useEffect(() => {
    const load = async () => {
      const res = await apiRequest('/explore/suggested-riders?limit=6');
      if (res.ok) setSuggestions(await res.json());
    };
    load();
  }, []);

  // Debounced search
  useEffect(() => {
    if (!query.trim()) {
      setResults(null);
      return;
    }
    const t = setTimeout(async () => {
      setSearching(true);
      try {
        const res = await apiRequest(
          `/explore?q=${encodeURIComponent(query)}&kind=${tab}`
        );
        if (res.ok) setResults(await res.json());
      } finally {
        setSearching(false);
      }
    }, 350);
    return () => clearTimeout(t);
  }, [query, tab]);

  // The active query echoed back by the API (prevents stale highlights during debounce)
  const activeQuery = results?.query ?? query;

  const hasResults = results && (
    results.people.length > 0 || results.waves.length > 0 || results.circles.length > 0
  );

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-8">
        {/* Header */}
        <header className="sticky top-0 z-20 border-b border-slate-200/50 bg-white/70 backdrop-blur dark:border-slate-800/50 dark:bg-slate-900/70 px-5 py-4 space-y-3">
          <h1 className="text-xl font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
            Discover
          </h1>

          {/* Search bar */}
          <div className="relative">
            <svg
              className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              autoFocus
              id="discover-search"
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search people, waves, circles…"
              className="w-full rounded-2xl border border-slate-200 bg-slate-50 py-2.5 pl-10 pr-4 text-sm outline-none focus:border-aqua dark:border-slate-700 dark:bg-slate-800"
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                aria-label="Clear search"
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
          </div>

          {/* Filter tabs */}
          {query && (
            <div className="flex gap-4 text-xs font-bold uppercase tracking-wider text-slate-500" role="tablist">
              {(['all', 'people', 'waves', 'circles'] as const).map((t) => (
                <button
                  key={t}
                  role="tab"
                  aria-selected={tab === t}
                  onClick={() => setTab(t)}
                  className={`pb-1 border-b-2 transition-all capitalize ${
                    tab === t
                      ? 'border-aqua text-aqua'
                      : 'border-transparent hover:text-slate-700 dark:hover:text-slate-200'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          )}
        </header>

        <div className="p-5 space-y-6">
          {/* ── No search → show suggested riders ───────────────────────────── */}
          {!query && (
            <section>
              <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
                Suggested Riders
              </h2>
              <div className="space-y-2">
                {suggestions.length === 0 && (
                  <p className="text-xs text-slate-400">No suggestions available right now.</p>
                )}
                {suggestions.map((s) => (
                  <div
                    key={s.id}
                    className="flex items-center justify-between rounded-2xl border border-slate-100 bg-white p-4 dark:border-slate-800/50 dark:bg-slate-900/40"
                  >
                    <div className="flex items-center gap-3">
                      <Avatar username={s.username} avatar_url={s.avatar_url} size="md" />
                      <div>
                        <p className="text-sm font-bold leading-none">{s.full_name || s.username}</p>
                        <p className="text-xs text-slate-400">@{s.username}</p>
                      </div>
                    </div>
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={async () => {
                        await apiRequest(`/users/ride/${s.id}`, { method: 'POST' });
                        setSuggestions((prev) => prev.filter((r) => r.id !== s.id));
                      }}
                    >
                      Ride
                    </Button>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* ── Searching indicator ──────────────────────────────────────── */}
          {query && searching && (
            <div className="text-center py-8">
              <svg className="animate-spin h-6 w-6 text-aqua mx-auto" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            </div>
          )}

          {/* ── No results ───────────────────────────────────────────────── */}
          {query && !searching && results && !hasResults && (
            <div className="text-center py-14 space-y-2">
              <span className="text-4xl">🌊</span>
              <h3 className="text-sm font-bold text-slate-500">Nothing found for "{query}"</h3>
              <p className="text-xs text-slate-400">Try different keywords or explore Wave Circles.</p>
            </div>
          )}

          {/* ── Results ──────────────────────────────────────────────────── */}
          {results && !searching && (
            <div className="space-y-6">
              {/* People */}
              {results.people.length > 0 && (tab === 'all' || tab === 'people') && (
                <section>
                  <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">People</h2>
                  <div className="space-y-2">
                    {results.people.map((p) => (
                      <PersonCard key={p.id} person={p} query={activeQuery} />
                    ))}
                  </div>
                </section>
              )}

              {/* Waves */}
              {results.waves.length > 0 && (tab === 'all' || tab === 'waves') && (
                <section>
                  <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">Waves</h2>
                  <div className="space-y-2">
                    {results.waves.map((w) => (
                      <div
                        key={w.id}
                        className="rounded-2xl border border-slate-100 bg-white p-4 dark:border-slate-800/50 dark:bg-slate-900/40 space-y-2"
                      >
                        <p className="text-sm line-clamp-3">
                          {w.content && <Highlight text={w.content} term={activeQuery} />}
                        </p>
                        <div className="flex gap-4 text-[10px] text-slate-400 font-semibold">
                          <span>💙 {w.ripples_count} Ripples</span>
                          <span>
                            {formatDistanceToNow(new Date(w.created_at + "Z"), { addSuffix: true })}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Circles */}
              {results.circles.length > 0 && (tab === 'all' || tab === 'circles') && (
                <section>
                  <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">Wave Circles</h2>
                  <div className="space-y-2">
                    {results.circles.map((c) => (
                      <div
                        key={c.id}
                        onClick={() => router.push(`/circles/${c.slug}`)}
                        className="flex items-center gap-3 rounded-2xl border border-slate-100 bg-white p-4 cursor-pointer hover:shadow-sm transition-all dark:border-slate-800/50 dark:bg-slate-900/40"
                      >
                        <div className="h-10 w-10 rounded-full bg-gradient-to-br from-ocean/80 to-aqua/60 flex items-center justify-center text-white font-bold text-sm shrink-0">
                          {c.name[0]}
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-bold truncate">
                            <Highlight text={c.name} term={activeQuery} />
                          </p>
                          {c.description && (
                            <p className="text-xs text-slate-400 line-clamp-1">
                              <Highlight text={c.description} term={activeQuery} />
                            </p>
                          )}
                        </div>
                      </div>
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
