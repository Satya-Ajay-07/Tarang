'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import { apiRequest } from '@/services/api';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

export default function MainAppLayout({ children }: { children: React.ReactNode }) {
  const { user, logout } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const [unreadAlerts, setUnreadAlerts] = useState(0);
  const [risingWaves, setRisingWaves] = useState<any[]>([]);
  const [suggestedRiders, setSuggestedRiders] = useState<any[]>([]);
  const [isDarkMode, setIsDarkMode] = useState(true);

  // Poll alerts count and suggestions
  useEffect(() => {
    if (!user) return;

    const fetchSidebarData = async () => {
      try {
        // Fetch unread alerts
        const alertsRes = await apiRequest('/alerts');
        if (alertsRes.ok) {
          const alertsData = await alertsRes.json();
          setUnreadAlerts(alertsData.filter((a: any) => !a.is_read).length);
        }

        // Fetch rising waves
        const risingRes = await apiRequest('/waves/rising?limit=3');
        if (risingRes.ok) {
          const risingData = await risingRes.json();
          setRisingWaves(risingData);
        }

        // Fetch suggested riders
        const suggestionRes = await apiRequest('/explore/suggested-riders?limit=4');
        if (suggestionRes.ok) {
          const suggestions = await suggestionRes.json();
          setSuggestedRiders(suggestions);
        } else {
          // API unavailable — show nothing rather than fake data
          console.error(`[Tarang] Suggested Riders fetch failed: HTTP ${suggestionRes.status}`);
          setSuggestedRiders([]);
        }
      } catch (err) {
        console.error(err);
      }
    };

    fetchSidebarData();
    const interval = setInterval(fetchSidebarData, 20000);
    return () => clearInterval(interval);
  }, [user]);

  // Load persisted theme on mount
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme');
    const root = document.documentElement;
    if (savedTheme === 'light') {
      root.classList.remove('dark');
      setIsDarkMode(false);
    } else {
      root.classList.add('dark');
      setIsDarkMode(true);
    }
  }, []);

  // Dark/Light toggle handler
  const toggleTheme = () => {
    const root = document.documentElement;
    if (isDarkMode) {
      root.classList.remove('dark');
      setIsDarkMode(false);
      localStorage.setItem('theme', 'light');
    } else {
      root.classList.add('dark');
      setIsDarkMode(true);
      localStorage.setItem('theme', 'dark');
    }
  };

  const handleFollowRider = async (riderId: string) => {
    try {
      const res = await apiRequest(`/users/ride/${riderId}`, { method: 'POST' });
      if (res.ok) {
        setSuggestedRiders(prev => prev.filter(r => r.id !== riderId));
      }
    } catch (err) {
      console.error(err);
    }
  };

  const navItems = [
    { name: 'Ocean', path: '/ocean', icon: '🌊' },
    { name: 'Discover', path: '/discover', icon: '🔍' },
    { name: 'Wave Alerts', path: '/alerts', icon: '🔔', badge: unreadAlerts },
    { name: 'Messages', path: '/messages', icon: '💬' },
    { name: 'Wave Circles', path: '/circles', icon: '🎯' },
    { name: 'Saved', path: '/saved', icon: '🔖' },
    { name: 'You', path: '/you', icon: '👤' },
  ];

  if (!user) return null;

  return (
    <div className="flex min-h-screen bg-[var(--background)] text-[var(--text-primary)] transition-colors duration-200">
      {/* Sidebar Navigation */}
      <aside className="sticky top-0 h-screen w-64 border-r border-card-border bg-card-bg px-5 py-6 flex flex-col justify-between hidden md:flex shadow-[2px_0_12px_rgba(0,0,0,0.01)]">
        <div className="space-y-8">
          <div className="flex items-center pl-3">
            <Logo size="md" />
          </div>
          
          <nav className="space-y-1.5">
            {navItems.map((item) => {
              const isActive = pathname.startsWith(item.path);
              return (
                <Link
                  key={item.name}
                  href={item.path}
                  className={`flex items-center justify-between rounded-xl px-4 py-2.5 text-sm font-bold tracking-wide transition-all ${
                    isActive
                      ? 'bg-[#E0F7FA] text-[#0891B2] dark:bg-aqua/10 dark:text-foam shadow-[0_2px_4px_rgba(8,145,178,0.05)]'
                      : 'text-[#334155] hover:bg-[#F1F5F9] hover:text-[#0F172A] dark:text-[#A0AEC0] dark:hover:bg-slate-800/40 dark:hover:text-slate-200'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className={`text-lg transition-colors ${isActive ? 'text-[#0891B2] dark:text-foam' : 'text-[#475569] dark:text-[#A0AEC0]'}`}>
                      {item.icon}
                    </span>
                    <span>{item.name}</span>
                  </div>
                  {item.badge ? (
                    <span className="rounded-full bg-aqua px-2 py-0.5 text-xs text-white font-extrabold shadow-sm">
                      {item.badge}
                    </span>
                  ) : null}
                </Link>
              );
            })}
          </nav>
        </div>

        {/* User Card info & Theme toggle */}
        <div className="border-t border-card-border pt-4 space-y-4">
          <button
            onClick={toggleTheme}
            className="flex w-full items-center justify-between rounded-xl px-4 py-2.5 text-xs font-bold uppercase tracking-wider text-[#475569] dark:text-slate-400 hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40"
          >
            <span>Theme Mode</span>
            <span className="text-[#0F172A] dark:text-white font-extrabold">{isDarkMode ? '🌙 Dark' : '☀️ Light'}</span>
          </button>

          <div className="flex items-center justify-between p-2 rounded-2xl border border-card-border bg-card-bg hover:bg-[#F8FAFC] dark:hover:bg-slate-900/40 transition-colors shadow-sm">
            <Link href="/you" className="flex items-center gap-3 group">
              <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white font-bold overflow-hidden shadow-sm shrink-0">
                {user.avatar_url ? (
                  <img src={user.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                ) : (
                  user.username[0].toUpperCase()
                )}
              </div>
              <div className="text-left leading-tight">
                <p className="text-sm font-bold truncate w-24 text-[#0F172A] dark:text-white group-hover:underline">
                  {user.full_name || user.username}
                </p>
                <p className="text-xs text-[#64748B] dark:text-slate-450 truncate w-24">@{user.username}</p>
              </div>
            </Link>
            <button
              onClick={logout}
              className="p-2 text-[#475569] hover:text-red-500 transition-colors"
              title="Logout"
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
            </button>
          </div>
        </div>
      </aside>

      {/* Main Central Content Area */}
      <main className="flex-1 border-r border-slate-200/50 dark:border-slate-850 max-w-4xl min-h-screen">
        {children}
      </main>

      {/* Right Sidebar - Rising Waves & Suggested Riders */}
      <aside className="sticky top-0 h-screen w-80 p-6 hidden lg:block overflow-y-auto space-y-6">
        {/* Suggested Riders */}
        <div className="rounded-3xl border border-card-border bg-card-bg p-5 shadow-[0_2px_8px_rgba(0,0,0,0.02)]">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-secondary mb-4">
            Suggested Riders
          </h3>
          <div className="space-y-4">
            {suggestedRiders.map((rider) => (
              <div key={rider.username} className="flex items-center justify-between">
                <Link href={`/you/${rider.username}`} className="flex items-center gap-3 group cursor-pointer">
                  <div className="h-8 w-8 rounded-full bg-gradient-to-br from-aqua to-ocean flex items-center justify-center text-white text-xs font-bold overflow-hidden">
                    {rider.avatar_url ? (
                      <img src={rider.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                    ) : (
                      rider.username[0].toUpperCase()
                    )}
                  </div>
                  <div>
                    <h4 className="text-xs font-bold leading-none group-hover:underline text-text-primary">{rider.full_name || rider.username}</h4>
                    <span className="text-[10px] text-text-secondary">@{rider.username}</span>
                  </div>
                </Link>
                <button
                  onClick={() => handleFollowRider(rider.id)}
                  className="rounded-full bg-aqua/10 px-3 py-1 text-xs font-bold text-aqua hover:bg-aqua hover:text-white transition-all"
                >
                  Ride
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Rising Waves */}
        <div className="rounded-3xl border border-card-border bg-card-bg p-5 shadow-[0_2px_8px_rgba(0,0,0,0.02)]">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-secondary mb-4">
            🌊 Rising Waves
          </h3>
          <div className="space-y-4">
            {risingWaves.map((wave) => (
              <div
                key={wave.id}
                className="cursor-pointer space-y-1 hover:opacity-80 transition-opacity"
                onClick={() => router.push(`/ocean`)}
              >
                <p className="text-xs text-text-secondary font-semibold">@{wave.creator.username}</p>
                <p className="text-xs line-clamp-2 text-text-primary">{wave.content}</p>
                <div className="flex gap-4 text-[10px] text-text-secondary">
                  <span>💙 {wave.ripples_count} Ripples</span>
                  <span>💬 {wave.joins_count} Joins</span>
                </div>
              </div>
            ))}
            {risingWaves.length === 0 && (
              <p className="text-xs text-text-secondary">The ocean is calm right now.</p>
            )}
          </div>
        </div>
      </aside>

      {/* Mobile Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-30 flex items-center justify-around border-t border-slate-200/50 bg-white/80 py-2 backdrop-blur-lg dark:border-slate-850 dark:bg-slate-900/80 md:hidden">
        {navItems.slice(0, 4).map((item) => {
          const isActive = pathname.startsWith(item.path);
          return (
            <Link key={item.name} href={item.path} className="flex flex-col items-center p-2 relative">
              <span className="text-xl">{item.icon}</span>
              <span className={`text-[10px] ${isActive ? 'text-aqua font-bold' : 'text-slate-400'}`}>
                {item.name.split(' ')[0]}
              </span>
              {item.badge ? (
                <span className="absolute top-1 right-2 rounded-full bg-aqua px-1.5 py-0.5 text-[8px] text-white font-bold">
                  {item.badge}
                </span>
              ) : null}
            </Link>
          );
        })}
        <Link href="/you" className="flex flex-col items-center p-2">
          <div className="h-5 w-5 rounded-full bg-slate-300 dark:bg-slate-600 flex items-center justify-center text-[10px] font-bold text-white">
            {user.username[0].toUpperCase()}
          </div>
          <span className="text-[10px] text-slate-400">You</span>
        </Link>
      </nav>
    </div>
  );
}
