'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { useRouter } from 'next/navigation';

interface Circle {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  banner_url: string | null;
  members_count: number;
  joined_by_me: boolean;
}

function CircleCard({
  circle,
  onToggle,
}: {
  circle: Circle;
  onToggle: (slug: string, joined: boolean) => void;
}) {
  const router = useRouter();
  const [joining, setJoining] = useState(false);
  const [joined, setJoined] = useState(circle.joined_by_me);
  const [members, setMembers] = useState(circle.members_count);

  const handleToggle = async (e: React.MouseEvent) => {
    e.stopPropagation();
    setJoining(true);
    try {
      const res = await apiRequest(`/circles/${circle.slug}/join`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setJoined(data.joined);
        setMembers((m) => (data.joined ? m + 1 : m - 1));
        onToggle(circle.slug, data.joined);
      }
    } finally {
      setJoining(false);
    }
  };

  return (
    <div
      onClick={() => router.push(`/circles/${circle.slug}`)}
      className="group cursor-pointer rounded-3xl border border-slate-200/60 bg-white p-5 shadow-sm transition-all hover:shadow-md hover:-translate-y-0.5 dark:border-slate-800/50 dark:bg-slate-900/40 flex flex-col gap-3"
    >
      {/* Banner / icon */}
      <div className="h-20 rounded-2xl bg-gradient-to-br from-ocean/80 to-aqua/60 overflow-hidden flex items-center justify-center text-3xl font-bold text-white select-none">
        {circle.banner_url ? (
          <img src={circle.banner_url} alt={circle.name} className="w-full h-full object-cover" />
        ) : (
          circle.name[0].toUpperCase()
        )}
      </div>

      <div className="flex-1">
        <h3 className="text-sm font-bold leading-tight">{circle.name}</h3>
        {circle.description && (
          <p className="text-xs text-slate-400 mt-1 line-clamp-2">{circle.description}</p>
        )}
      </div>

      <div className="flex items-center justify-between text-xs text-slate-400 pt-2 border-t border-slate-100 dark:border-slate-800/40">
        <span>{members.toLocaleString()} riders</span>
        <button
          onClick={handleToggle}
          disabled={joining}
          className={`rounded-full px-4 py-1.5 text-xs font-bold transition-all ${
            joined
              ? 'bg-slate-100 text-slate-500 dark:bg-slate-800 hover:bg-red-50 hover:text-red-500'
              : 'bg-gradient-to-r from-ocean to-aqua text-white hover:scale-[1.02] shadow-sm'
          }`}
        >
          {joining ? '…' : joined ? 'Leave' : 'Join Circle'}
        </button>
      </div>
    </div>
  );
}

function CreateCircleModal({ onClose, onCreate }: { onClose: () => void; onCreate: () => void }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (name.trim().length < 2) {
      setError('Circle name must be at least 2 characters.');
      return;
    }
    setLoading(true);
    try {
      const res = await apiRequest('/circles', {
        method: 'POST',
        body: JSON.stringify({ name: name.trim(), description: description.trim() || null }),
      });
      if (!res.ok) {
        const d = await res.json();
        throw new Error(d?.error?.message || 'Failed to create circle');
      }
      onCreate();
      onClose();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="w-full max-w-md rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-800 dark:bg-slate-900/95 space-y-5">
        <h3 className="text-lg font-bold">Create a Wave Circle</h3>
        {error && (
          <p className="text-xs text-red-500 bg-red-50 dark:bg-red-950/20 rounded-xl p-3">{error}</p>
        )}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
              Circle Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Indie Developers"
              className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm outline-none focus:border-aqua dark:border-slate-700 dark:bg-slate-800"
              required
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
              Description <span className="text-slate-400 normal-case">(optional)</span>
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="What is this circle about?"
              rows={3}
              maxLength={240}
              className="w-full resize-none rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm outline-none focus:border-aqua dark:border-slate-700 dark:bg-slate-800"
            />
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={onClose}
              className="rounded-full border border-slate-200 px-4 py-2 text-xs font-bold hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="rounded-full bg-gradient-to-r from-ocean to-aqua px-5 py-2 text-xs font-bold text-white disabled:opacity-60"
            >
              {loading ? 'Creating…' : 'Create Circle'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function CirclesPage() {
  const [circles, setCircles] = useState<Circle[]>([]);
  const [myCircles, setMyCircles] = useState<Circle[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [tab, setTab] = useState<'discover' | 'mine'>('discover');

  const load = async (q = '') => {
    setLoading(true);
    try {
      const [allRes, mineRes] = await Promise.all([
        apiRequest(`/circles?search=${encodeURIComponent(q)}`),
        apiRequest('/circles/mine'),
      ]);
      if (allRes.ok) setCircles(await allRes.json());
      if (mineRes.ok) setMyCircles(await mineRes.json());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  // Debounce search
  useEffect(() => {
    const t = setTimeout(() => load(search), 350);
    return () => clearTimeout(t);
  }, [search]);

  const displayed = tab === 'mine' ? myCircles : circles;

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-8">
        {/* Header */}
        <header className="sticky top-0 z-20 border-b border-slate-200/50 bg-white/70 backdrop-blur dark:border-slate-800/50 dark:bg-slate-900/70 px-5 py-4 space-y-3">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
              Wave Circles
            </h1>
            <button
              onClick={() => setShowCreate(true)}
              className="rounded-full bg-gradient-to-r from-ocean to-aqua px-4 py-2 text-xs font-bold text-white shadow-md hover:scale-[1.02] transition-all"
            >
              + New Circle
            </button>
          </div>

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
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search Wave Circles…"
              className="w-full rounded-2xl border border-slate-200 bg-slate-50 py-2.5 pl-10 pr-4 text-sm outline-none focus:border-aqua dark:border-slate-700 dark:bg-slate-800"
            />
          </div>

          {/* Tabs */}
          <div className="flex gap-4 text-xs font-bold uppercase tracking-wider text-slate-500">
            {(['discover', 'mine'] as const).map((t) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`pb-1 border-b-2 transition-all ${
                  tab === t ? 'border-aqua text-aqua' : 'border-transparent hover:text-slate-700 dark:hover:text-slate-200'
                }`}
              >
                {t === 'discover' ? 'Discover' : 'My Circles'}
              </button>
            ))}
          </div>
        </header>

        {/* Grid */}
        <div className="p-5">
          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="h-44 rounded-3xl bg-slate-100 dark:bg-slate-800/30 animate-pulse" />
              ))}
            </div>
          ) : displayed.length === 0 ? (
            <div className="text-center py-16 space-y-2">
              <span className="text-4xl">🎯</span>
              <h3 className="text-sm font-bold text-slate-500">
                {tab === 'mine' ? "You haven't joined any circles yet" : 'No circles found'}
              </h3>
              <p className="text-xs text-slate-400">
                {tab === 'mine'
                  ? 'Discover and join Wave Circles to connect with your community.'
                  : 'Try a different search term or create your own circle.'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {displayed.map((c) => (
                <CircleCard key={c.id} circle={c} onToggle={() => load(search)} />
              ))}
            </div>
          )}
        </div>
      </div>

      {showCreate && (
        <CreateCircleModal onClose={() => setShowCreate(false)} onCreate={() => load(search)} />
      )}
    </MainAppLayout>
  );
}
