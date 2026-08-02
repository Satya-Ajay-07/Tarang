'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';

export default function SavedPage() {
  const [waves, setWaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBookmarks = async () => {
    setLoading(true);
    try {
      const res = await apiRequest('/waves/bookmarks');
      if (res.ok) {
        const data = await res.json();
        setWaves(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookmarks();
  }, []);

  const handleRefresh = () => {
    fetchBookmarks();
  };

  return (
    <MainAppLayout>
      <div className="flex flex-col h-full bg-transparent">
        {/* Sticky Header */}
        <header className="sticky top-0 z-20 flex flex-col border-b border-card-border bg-card-bg/70 backdrop-blur-md p-4">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-black tracking-tight text-text-primary">
              Saved Waves
            </h1>
          </div>
        </header>

        {/* Content stream area */}
        <div className="flex-1 p-4 md:p-6 space-y-6 pb-20 md:pb-6">
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="rounded-3xl border border-card-border bg-card-bg p-5 animate-pulse space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-slate-200 dark:bg-slate-800" />
                    <div className="space-y-2">
                      <div className="h-3 w-28 bg-slate-200 dark:bg-slate-800 rounded" />
                      <div className="h-2.5 w-16 bg-slate-200 dark:bg-slate-800 rounded" />
                    </div>
                  </div>
                  <div className="space-y-2 pl-13">
                    <div className="h-3.5 w-full bg-slate-200 dark:bg-slate-800 rounded" />
                    <div className="h-3.5 w-5/6 bg-slate-200 dark:bg-slate-800 rounded" />
                  </div>
                </div>
              ))}
            </div>
          ) : waves.length === 0 ? (
            <div className="text-center py-16 space-y-3">
              <div className="text-4xl">🔖</div>
              <h3 className="text-sm font-bold text-text-secondary">No bookmarks saved</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                Save waves to reference them later. Bookmarked waves will appear here.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {waves.map((wave) => (
                <WaveCard key={wave.id} wave={wave} onRefresh={handleRefresh} />
              ))}
            </div>
          )}
        </div>
      </div>
    </MainAppLayout>
  );
}
