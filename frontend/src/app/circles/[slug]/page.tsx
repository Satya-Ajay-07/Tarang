'use client';

import React, { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import MainAppLayout from '@/layouts/MainAppLayout';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { CreateWave } from '@/features/waves/components/CreateWave';
import { apiRequest } from '@/services/api';

interface CircleDetail {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  banner_url: string | null;
  members_count: number;
  joined_by_me: boolean;
  creator_id: string | null;
}

export default function CircleDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = use(params);
  const router = useRouter();
  const [circle, setCircle] = useState<CircleDetail | null>(null);
  const [waves, setWaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [joining, setJoining] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const [circleRes, wavesRes] = await Promise.all([
        apiRequest(`/circles/${slug}`),
        apiRequest(`/circles/${slug}/waves?skip=0&limit=20`),
      ]);
      if (!circleRes.ok) {
        router.push('/circles');
        return;
      }
      const circleData = await circleRes.json();
      setCircle(circleData);

      // Use dedicated circle waves endpoint (server-side filtered)
      if (wavesRes.ok) {
        const circleWaves = await wavesRes.json();
        setWaves(circleWaves);
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [slug]);

  const handleToggleJoin = async () => {
    if (!circle) return;
    setJoining(true);
    try {
      const res = await apiRequest(`/circles/${circle.slug}/join`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setCircle((c) => c ? {
          ...c,
          joined_by_me: data.joined,
          members_count: c.members_count + (data.joined ? 1 : -1),
        } : c);
      }
    } finally {
      setJoining(false);
    }
  };

  if (loading) {
    return (
      <MainAppLayout>
        <div className="flex h-screen items-center justify-center">
          <svg className="animate-spin h-8 w-8 text-aqua" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
        </div>
      </MainAppLayout>
    );
  }

  if (!circle) return null;

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-8">
        {/* Banner */}
        <div className="h-40 bg-gradient-to-br from-ocean to-aqua relative overflow-hidden">
          {circle.banner_url && (
            <img src={circle.banner_url} alt={circle.name} className="w-full h-full object-cover" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
          <button
            onClick={() => router.back()}
            className="absolute top-4 left-4 rounded-full bg-black/30 backdrop-blur p-2 text-white"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
        </div>

        {/* Circle info */}
        <div className="px-5 py-4 border-b border-slate-100 dark:border-slate-800/50 space-y-3">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h1 className="text-xl font-black">{circle.name}</h1>
              {circle.description && (
                <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">{circle.description}</p>
              )}
            </div>
            <button
              onClick={handleToggleJoin}
              disabled={joining}
              className={`shrink-0 rounded-full px-5 py-2 text-xs font-bold transition-all ${
                circle.joined_by_me
                  ? 'border border-slate-200 dark:border-slate-700 hover:bg-red-50 hover:text-red-500'
                  : 'bg-gradient-to-r from-ocean to-aqua text-white shadow-md hover:scale-[1.02]'
              }`}
            >
              {joining ? '…' : circle.joined_by_me ? 'Leave Circle' : 'Join Circle'}
            </button>
          </div>
          <div className="text-xs text-slate-400 font-semibold">
            {circle.members_count.toLocaleString()} Wave Riders
          </div>
        </div>

        {/* Wave Stream for this circle */}
        <div className="p-5 space-y-4">
          {circle.joined_by_me && (
            <CreateWave
              onWaveCreated={load}
              circleId={circle.id}
            />
          )}
          {waves.length === 0 ? (
            <div className="text-center py-12 space-y-2">
              <span className="text-3xl">🌊</span>
              <p className="text-sm text-slate-500">No waves yet in this circle.</p>
              {circle.joined_by_me && (
                <p className="text-xs text-slate-400">Be the first to release a wave!</p>
              )}
            </div>
          ) : (
            waves.map((w) => <WaveCard key={w.id} wave={w} onRefresh={load} />)
          )}
        </div>
      </div>
    </MainAppLayout>
  );
}
