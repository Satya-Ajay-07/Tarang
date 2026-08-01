'use client';

import React, { useState } from 'react';
import { apiRequest } from '@/services/api';
import { formatDistanceToNow } from 'date-fns';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface WaveCardProps {
  wave: any;
  onRefresh?: () => void;
}

export const WaveCard: React.FC<WaveCardProps> = ({ wave, onRefresh }) => {
  const router = useRouter();
  const [rippled, setRippled] = useState(wave.rippled_by_me);
  const [ripplesCount, setRipplesCount] = useState(wave.ripples_count);
  const [spreadsCount, setSpreadsCount] = useState(wave.spreads_count);
  const [showJoinForm, setShowJoinForm] = useState(false);
  const [joinContent, setJoinContent] = useState('');
  const [submittingJoin, setSubmittingJoin] = useState(false);
  const [joinsList, setJoinsList] = useState<any[]>([]);
  const [loadedJoins, setLoadedJoins] = useState(false);

  const handleRipple = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const res = await apiRequest(`/waves/${wave.id}/ripple`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setRippled(data.rippled);
        setRipplesCount(data.ripples_count);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleSpread = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const res = await apiRequest(`/waves/${wave.id}/spread`, { method: 'POST' });
      if (res.ok) {
        setSpreadsCount((prev: number) => prev + 1);
        if (onRefresh) onRefresh();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const fetchJoins = async () => {
    try {
      const res = await apiRequest(`/waves/${wave.id}/joins`);
      if (res.ok) {
        const data = await res.json();
        setJoinsList(data);
        setLoadedJoins(true);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleToggleJoin = (e: React.MouseEvent) => {
    e.stopPropagation();
    setShowJoinForm(!showJoinForm);
    if (!loadedJoins) {
      fetchJoins();
    }
  };

  const handleJoinSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!joinContent.trim()) return;

    setSubmittingJoin(true);
    try {
      const res = await apiRequest('/waves', {
        method: 'POST',
        body: JSON.stringify({
          content: joinContent,
          parent_wave_id: wave.id
        })
      });

      if (res.ok) {
        setJoinContent('');
        fetchJoins();
        if (onRefresh) onRefresh();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setSubmittingJoin(false);
    }
  };

  const isSpreadWave = wave.spread_from_id !== null && wave.spread_from !== null;
  const activeWaveData = isSpreadWave ? wave.spread_from : wave;

  const dateStr = activeWaveData.created_at;
  const parsedDate = typeof dateStr === 'string' && !dateStr.endsWith('Z') && !dateStr.includes('+') 
    ? new Date(dateStr + 'Z') 
    : new Date(dateStr);

  const timeAgo = formatDistanceToNow(parsedDate, { addSuffix: true })
    .replace('about ', '')
    .replace('less than a minute ago', 'just now');

  return (
    <div className="rounded-3xl border border-card-border bg-card-bg p-5 shadow-[0_2px_8px_rgba(0,0,0,0.04)] transition-all hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)] space-y-4">
      {/* Spread header if applicable */}
      {isSpreadWave && (
        <div className="flex items-center gap-2 text-xs font-semibold text-text-secondary">
          <span>🔁</span>
          <span>@{wave.creator.username} spread this wave</span>
        </div>
      )}

      {/* Main card header */}
      <div className="flex items-center justify-between">
        <Link href={`/you/${activeWaveData.creator.username}`} className="flex items-center gap-3 group">
          <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white font-bold select-none overflow-hidden shrink-0">
            {activeWaveData.creator.avatar_url ? (
              <img src={activeWaveData.creator.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
            ) : (
              activeWaveData.creator.username[0].toUpperCase()
            )}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h4 className="text-sm font-bold leading-none group-hover:underline text-text-primary">{activeWaveData.creator.full_name || activeWaveData.creator.username}</h4>
              <span className="text-xs text-text-secondary">@{activeWaveData.creator.username}</span>
            </div>
            <span className="text-[10px] text-text-secondary">{timeAgo}</span>
          </div>
        </Link>
      </div>

      {/* Content */}
      <div className="pl-13 text-sm leading-relaxed text-text-primary">
        <p className="whitespace-pre-wrap">{activeWaveData.content}</p>
        
        {activeWaveData.media_url && (
          <div className="mt-3 overflow-hidden rounded-2xl border border-slate-100 dark:border-slate-800">
            {activeWaveData.media_type === 'video' ? (
              <video src={activeWaveData.media_url} controls className="w-full max-h-96 object-cover" />
            ) : (
              <img src={activeWaveData.media_url} alt="Wave attachment" className="w-full max-h-96 object-cover" />
            )}
          </div>
        )}
      </div>

      {/* Actions row */}
      <div className="flex justify-around items-center pt-2 border-t border-card-border text-xs text-text-secondary font-semibold select-none">
        {/* Ripple action */}
        <button
          onClick={handleRipple}
          className={`flex items-center gap-2 py-1 px-3 rounded-full transition-colors ${
            rippled ? 'text-aqua bg-aqua/5' : 'hover:text-aqua hover:bg-aqua/5'
          }`}
        >
          <span>{rippled ? '💙' : '🤍'}</span>
          <span>{ripplesCount} Ripples</span>
        </button>

        {/* Join action */}
        <button
          onClick={handleToggleJoin}
          className="flex items-center gap-2 py-1 px-3 rounded-full hover:text-ocean hover:bg-ocean/5 dark:hover:text-foam dark:hover:bg-foam/5 transition-colors"
        >
          <span>💬</span>
          <span>{wave.joins_count} Joins</span>
        </button>

        {/* Spread action */}
        <button
          onClick={handleSpread}
          className="flex items-center gap-2 py-1 px-3 rounded-full hover:text-teal-500 hover:bg-teal-500/5 transition-colors"
        >
          <span>🔁</span>
          <span>{spreadsCount} Spread</span>
        </button>
      </div>

      {/* Join comments form section */}
      {showJoinForm && (
        <div className="pt-4 border-t border-card-border space-y-4">
          <form onSubmit={handleJoinSubmit} className="flex gap-2">
            <input
              type="text"
              value={joinContent}
              onChange={(e) => setJoinContent(e.target.value)}
              placeholder="Join this wave..."
              className="flex-1 rounded-2xl border border-card-border bg-background px-4 py-2 text-xs outline-none focus:border-aqua text-text-primary placeholder-slate-400"
              required
              disabled={submittingJoin}
            />
            <button
              type="submit"
              disabled={submittingJoin}
              className="rounded-2xl bg-aqua px-4 py-2 text-xs font-bold text-white hover:bg-ocean transition-all disabled:opacity-50"
            >
              Join
            </button>
          </form>

          {/* Subjoins list */}
          <div className="space-y-3 pl-6 border-l-2 border-slate-100 dark:border-slate-800/60 max-h-60 overflow-y-auto">
            {joinsList.map((join) => (
              <div key={join.id} className="text-xs space-y-1">
                <div className="flex items-center gap-2">
                  <span className="font-bold">@{join.creator.username}</span>
                  <span className="text-[9px] text-slate-400">
                    {formatDistanceToNow(new Date(join.created_at), { addSuffix: true })}
                  </span>
                </div>
                <p className="text-slate-600 dark:text-slate-300">{join.content}</p>
              </div>
            ))}
            {joinsList.length === 0 && loadedJoins && (
              <p className="text-[10px] text-slate-400">No joins yet. Be the first to start the ripple.</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
