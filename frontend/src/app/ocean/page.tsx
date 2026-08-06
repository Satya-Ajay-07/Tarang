'use client';

import React, { useState, useEffect, useRef } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { CreateWave } from '@/features/waves/components/CreateWave';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';
import { Skeleton, Button } from '@/components/ui';

export default function OceanPage() {
  const [waves, setWaves] = useState<any[]>([]);
  const [streamType, setStreamType] = useState<'all' | 'riding'>('all');
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [skip, setSkip] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const LIMIT = 10;
  
  const creatorRef = useRef<HTMLDivElement>(null);

  const fetchWaves = async (reset = false) => {
    if (reset) {
      setLoading(true);
      setSkip(0);
    } else {
      setLoadingMore(true);
    }
    
    const currentSkip = reset ? 0 : skip;

    try {
      const res = await apiRequest(`/waves?stream_type=${streamType}&skip=${currentSkip}&limit=${LIMIT}`);
      if (res.ok) {
        const data = await res.json();
        if (reset) {
          setWaves(data);
        } else {
          setWaves((prev) => [...prev, ...data]);
        }
        
        if (data.length < LIMIT) {
          setHasMore(false);
        } else {
          setHasMore(true);
          setSkip(currentSkip + LIMIT);
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchWaves(true);
  }, [streamType]);

  // Infinite scrolling handler
  useEffect(() => {
    const handleScroll = () => {
      if (typeof window === 'undefined') return;
      
      const threshold = 150;
      const reachedBottom =
        window.innerHeight + document.documentElement.scrollTop >=
        document.documentElement.offsetHeight - threshold;

      if (reachedBottom && hasMore && !loadingMore && !loading) {
        fetchWaves(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [hasMore, loadingMore, loading, skip]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await fetchWaves(true);
  };

  const handleScrollToCompose = () => {
    if (creatorRef.current) {
      creatorRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
      // Find the textarea inside creatorRef and focus it
      const textarea = creatorRef.current.querySelector('textarea');
      if (textarea) textarea.focus();
    }
  };

  return (
    <MainAppLayout>
      <div className="flex flex-col h-full bg-transparent relative">
        {/* Sticky Header with ocean indicators */}
        <header className="sticky top-16 z-20 flex flex-col border-b border-card-border bg-background/80 backdrop-blur-md p-4 sm:p-5">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-black tracking-tight bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent font-display select-none">
              Ocean
            </h1>
            <button
              onClick={handleRefresh}
              disabled={isRefreshing}
              className={`p-2 rounded-full border border-card-border hover:bg-card-border/30 text-text-secondary hover:text-text-primary transition-all duration-200 ${
                isRefreshing ? 'animate-spin opacity-50' : ''
              }`}
              title="Refresh feed"
            >
              🔄
            </button>
          </div>

          {/* Ocean Stream Selection Tabs */}
          <div className="flex gap-4 mt-4 border-t border-card-border pt-3 text-xs font-bold uppercase tracking-wider text-text-secondary select-none">
            <button
              onClick={() => setStreamType('all')}
              className={`pb-2 border-b-2 transition-all duration-200 ${
                streamType === 'all'
                  ? 'border-primary text-primary'
                  : 'border-transparent hover:text-text-primary'
              }`}
            >
              Wave Stream
            </button>
            <button
              onClick={() => setStreamType('riding')}
              className={`pb-2 border-b-2 transition-all duration-200 ${
                streamType === 'riding'
                  ? 'border-primary text-primary'
                  : 'border-transparent hover:text-text-primary'
              }`}
            >
              Riding Currents
            </button>
          </div>
        </header>

        {/* Content stream area */}
        <div className="flex-1 p-4 sm:p-6 space-y-6 pb-24 md:pb-6">
          <div ref={creatorRef}>
            <CreateWave onWaveCreated={handleRefresh} />
          </div>

          {/* Listing */}
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="rounded-card border border-card-border bg-card-bg p-5 shadow-sm space-y-4 animate-pulse">
                  <div className="flex items-center gap-3">
                    <Skeleton variant="circle" width={40} height={40} />
                    <div className="space-y-2 flex-1">
                      <Skeleton variant="rect" width={120} height={14} />
                      <Skeleton variant="rect" width={80} height={10} />
                    </div>
                  </div>
                  <div className="space-y-2.5">
                    <Skeleton variant="rect" width="100%" height={16} />
                    <Skeleton variant="rect" width="90%" height={16} />
                  </div>
                </div>
              ))}
            </div>
          ) : waves.length === 0 ? (
            <div className="text-center py-16 space-y-3.5 border border-dashed border-card-border rounded-card bg-card-bg/25">
              <div className="text-4xl animate-bounce">🌊</div>
              <h3 className="text-sm font-bold text-text-secondary font-display">The Stream is Calm</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                No waves have been released on this current. Release a wave above or start riding with other creators.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {waves.map((wave) => (
                <WaveCard key={wave.id} wave={wave} onRefresh={handleRefresh} />
              ))}
              
              {loadingMore && (
                <div className="space-y-4 pt-2">
                  <div className="rounded-card border border-card-border bg-card-bg p-5 shadow-sm space-y-4 animate-pulse">
                    <div className="flex items-center gap-3">
                      <Skeleton variant="circle" width={40} height={40} />
                      <div className="space-y-2 flex-1">
                        <Skeleton variant="rect" width={120} height={14} />
                        <Skeleton variant="rect" width={80} height={10} />
                      </div>
                    </div>
                    <div className="space-y-2.5">
                      <Skeleton variant="rect" width="100%" height={16} />
                    </div>
                  </div>
                </div>
              )}

              {!hasMore && (
                <div className="text-center text-xs text-text-muted font-semibold py-6 select-none">
                  🌊 You have caught up with all rolling currents.
                </div>
              )}
            </div>
          )}
        </div>

        {/* Floating Action Compose Button */}
        <button
          onClick={handleScrollToCompose}
          className="fixed bottom-20 right-6 md:bottom-8 z-40 p-4 rounded-full bg-gradient-to-r from-secondary to-primary hover:scale-105 active:scale-95 shadow-lg text-white font-bold transition-all duration-200"
          title="Compose new wave"
        >
          ✍️
        </button>
      </div>
    </MainAppLayout>
  );
}
