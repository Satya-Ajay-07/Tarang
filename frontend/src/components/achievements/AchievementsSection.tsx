'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '@/services/api';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface Achievement {
  id: string;
  name: string;
  icon: string;
  description: string;
  category: string;
  unlocked: boolean;
  unlocked_at: string | null;
}

// ── Category colours ──────────────────────────────────────────────────────────

const CATEGORY_STYLE: Record<string, { bg: string; border: string; label: string }> = {
  creator:    { bg: 'from-violet-500/20 to-indigo-500/10',  border: 'border-violet-500/30',   label: 'Creator'    },
  social:     { bg: 'from-pink-500/20 to-rose-500/10',      border: 'border-pink-500/30',     label: 'Social'     },
  influence:  { bg: 'from-amber-500/20 to-yellow-500/10',   border: 'border-amber-500/30',    label: 'Influence'  },
  dedication: { bg: 'from-emerald-500/20 to-teal-500/10',   border: 'border-emerald-500/30',  label: 'Dedication' },
  special:    { bg: 'from-sky-500/20 to-cyan-500/10',       border: 'border-sky-500/30',      label: 'Special'    },
};

// ── Celebration Animation ─────────────────────────────────────────────────────

function ConfettiParticle({ delay }: { delay: number }) {
  const colors = ['#6366f1', '#ec4899', '#f59e0b', '#10b981', '#06b6d4'];
  const color = colors[Math.floor(Math.random() * colors.length)];
  const left = Math.random() * 100;
  const animDuration = 1.2 + Math.random() * 0.8;

  return (
    <div
      className="absolute w-2 h-2 rounded-sm opacity-0"
      style={{
        left: `${left}%`,
        top: '-8px',
        background: color,
        animation: `confettiFall ${animDuration}s ${delay}s ease-in forwards`,
      }}
    />
  );
}

// ── Achievement Badge ─────────────────────────────────────────────────────────

function AchievementBadge({
  achievement,
  onJustUnlocked,
}: {
  achievement: Achievement;
  onJustUnlocked?: boolean;
}) {
  const [showCelebration, setShowCelebration] = useState(false);
  const catStyle = CATEGORY_STYLE[achievement.category] ?? CATEGORY_STYLE['special'];

  useEffect(() => {
    if (onJustUnlocked) {
      setShowCelebration(true);
      const t = setTimeout(() => setShowCelebration(false), 2500);
      return () => clearTimeout(t);
    }
  }, [onJustUnlocked]);

  return (
    <div
      title={achievement.description}
      className={`
        relative group flex flex-col items-center gap-2 p-3 rounded-2xl border transition-all duration-300
        ${achievement.unlocked
          ? `bg-gradient-to-br ${catStyle.bg} ${catStyle.border} shadow-sm hover:shadow-md hover:scale-105 cursor-default`
          : 'bg-card-bg/50 border-card-border/30 opacity-40 grayscale hover:opacity-60 hover:grayscale-0 transition-all cursor-default'
        }
        ${showCelebration ? 'ring-2 ring-offset-2 ring-primary animate-pulse' : ''}
      `}
    >
      {/* Confetti burst */}
      {showCelebration && (
        <div className="absolute inset-0 overflow-hidden rounded-2xl pointer-events-none">
          {[...Array(12)].map((_, i) => (
            <ConfettiParticle key={i} delay={i * 0.08} />
          ))}
        </div>
      )}

      {/* Icon */}
      <div className={`text-3xl leading-none transition-transform ${achievement.unlocked ? 'group-hover:scale-110' : ''}`}>
        {achievement.icon}
      </div>

      {/* Name */}
      <p className={`text-[10px] font-black text-center leading-tight ${achievement.unlocked ? 'text-text-primary' : 'text-text-muted'}`}>
        {achievement.name}
      </p>

      {/* Unlock date */}
      {achievement.unlocked && achievement.unlocked_at && (
        <p className="text-[9px] text-text-muted text-center">
          {new Date(achievement.unlocked_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
        </p>
      )}

      {/* Lock icon overlay */}
      {!achievement.unlocked && (
        <span className="absolute top-1.5 right-1.5 text-[10px] text-text-muted/60">🔒</span>
      )}

      {/* Tooltip */}
      <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 w-44 z-20 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
        <div className="bg-slate-900 dark:bg-slate-800 text-white text-[10px] rounded-xl p-2.5 shadow-xl text-center leading-relaxed">
          <p className="font-bold mb-0.5">{achievement.name}</p>
          <p className="text-slate-300">{achievement.description}</p>
          {!achievement.unlocked && (
            <p className="text-slate-400 mt-1 italic">Not yet unlocked</p>
          )}
        </div>
        <div className="w-2 h-2 bg-slate-900 dark:bg-slate-800 rotate-45 mx-auto -mt-1" />
      </div>
    </div>
  );
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

function AchievementSkeleton() {
  return (
    <div className="animate-pulse grid grid-cols-4 sm:grid-cols-5 gap-3">
      {[...Array(9)].map((_, i) => (
        <div key={i} className="flex flex-col items-center gap-2 p-3 rounded-2xl border border-card-border bg-card-bg">
          <div className="w-8 h-8 rounded-full bg-text-muted/10" />
          <div className="w-12 h-2.5 rounded bg-text-muted/10" />
        </div>
      ))}
    </div>
  );
}

// ── Main Section ──────────────────────────────────────────────────────────────

interface AchievementsSectionProps {
  /** Username whose achievements to load. If null/undefined → /achievements/me */
  username?: string;
  /** If true, the section runs /achievements/check on mount (own profile only) */
  triggerCheck?: boolean;
}

export function AchievementsSection({ username, triggerCheck }: AchievementsSectionProps) {
  const [achievements, setAchievements] = useState<Achievement[]>([]);
  const [loading, setLoading] = useState(true);
  const [newlyUnlocked, setNewlyUnlocked] = useState<Set<string>>(new Set());
  const [toast, setToast] = useState<Achievement | null>(null);

  const fetchAndCheck = useCallback(async () => {
    setLoading(true);
    try {
      // If own profile, optionally trigger a re-check first
      if (triggerCheck) {
        try {
          const checkRes = await apiRequest('/achievements/check', { method: 'POST' });
          if (checkRes.ok) {
            const { newly_unlocked } = await checkRes.json();
            if (newly_unlocked?.length) {
              const ids = new Set<string>(newly_unlocked.map((a: Achievement) => a.id));
              setNewlyUnlocked(ids);
              // Show a toast for the first newly unlocked achievement
              setToast(newly_unlocked[0]);
            }
          }
        } catch { /* non-critical */ }
      }

      // Fetch the full list
      const endpoint = username ? `/achievements/${username}` : '/achievements/me';
      const res = await apiRequest(endpoint);
      if (res.ok) {
        setAchievements(await res.json());
      }
    } finally {
      setLoading(false);
    }
  }, [username, triggerCheck]);

  useEffect(() => { fetchAndCheck(); }, [fetchAndCheck]);

  // Auto-dismiss toast after 5s
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 5000);
    return () => clearTimeout(t);
  }, [toast]);

  const earned = achievements.filter((a) => a.unlocked);
  const locked = achievements.filter((a) => !a.unlocked);

  return (
    <>
      {/* ── Achievement Unlock Toast ── */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 rounded-2xl border border-primary/30 bg-card-bg px-5 py-4 shadow-2xl shadow-primary/10 backdrop-blur-md animate-in slide-in-from-bottom-4 duration-300">
          <div className="text-3xl animate-bounce">{toast.icon}</div>
          <div>
            <p className="text-xs font-black text-text-primary">Achievement Unlocked!</p>
            <p className="text-xs font-bold text-primary">{toast.name}</p>
            <p className="text-[10px] text-text-muted mt-0.5">{toast.description}</p>
          </div>
          <button
            onClick={() => setToast(null)}
            className="ml-2 text-text-muted hover:text-text-primary text-xs"
          >
            ✕
          </button>
        </div>
      )}

      {/* ── Section Content ── */}
      <div className="px-6 pb-8 space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-black uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
            <span>🏆</span> Achievements
            {!loading && (
              <span className="ml-1 text-[10px] bg-primary/10 text-primary px-1.5 py-0.5 rounded-full font-bold">
                {earned.length}/{achievements.length}
              </span>
            )}
          </h3>
        </div>

        {loading ? (
          <AchievementSkeleton />
        ) : achievements.length === 0 ? (
          <div className="text-center py-8 text-text-muted text-xs font-bold">
            No achievements found.
          </div>
        ) : (
          <>
            {/* Earned */}
            {earned.length > 0 && (
              <div className="space-y-2">
                <p className="text-[10px] font-bold uppercase tracking-wider text-text-muted">
                  ✅ Earned ({earned.length})
                </p>
                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
                  {earned.map((a) => (
                    <AchievementBadge
                      key={a.id}
                      achievement={a}
                      onJustUnlocked={newlyUnlocked.has(a.id)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Locked */}
            {locked.length > 0 && (
              <div className="space-y-2">
                <p className="text-[10px] font-bold uppercase tracking-wider text-text-muted">
                  🔒 Locked ({locked.length})
                </p>
                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
                  {locked.map((a) => (
                    <AchievementBadge key={a.id} achievement={a} />
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </div>

      <style jsx global>{`
        @keyframes confettiFall {
          0%   { transform: translateY(0) rotate(0deg); opacity: 1; }
          100% { transform: translateY(120px) rotate(720deg); opacity: 0; }
        }
      `}</style>
    </>
  );
}
