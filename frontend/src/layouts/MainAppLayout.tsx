'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import { apiRequest } from '@/services/api';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

// Module-level caching for sidebar requests to eliminate duplicate/redundant fetches on page navigations
let lastFetchedTime = 0;
let cachedSidebarData: { unreadAlerts: number; risingWaves: any[]; suggestedRiders: any[] } | null = null;

export default function MainAppLayout({ children }: { children: React.ReactNode }) {
  const { user, logout } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const [unreadAlerts, setUnreadAlerts] = useState(0);
  const [risingWaves, setRisingWaves] = useState<any[]>([]);
  const [suggestedRiders, setSuggestedRiders] = useState<any[]>([]);
  const [isDarkMode, setIsDarkMode] = useState(true);

  // Poll alerts count and suggestions with memory caching
  useEffect(() => {
    if (!user) return;

    const fetchSidebarData = async () => {
      const now = Date.now();
      // If cached data is fresh (fetched within the last 15 seconds), reuse it to avoid duplicate API calls
      if (cachedSidebarData && (now - lastFetchedTime < 15000)) {
        setUnreadAlerts(cachedSidebarData.unreadAlerts);
        setRisingWaves(cachedSidebarData.risingWaves);
        setSuggestedRiders(cachedSidebarData.suggestedRiders);
        return;
      }

      try {
        // Fetch unread alerts
        const alertsRes = await apiRequest('/alerts');
        let unread = 0;
        if (alertsRes.ok) {
          const alertsData = await alertsRes.json();
          unread = alertsData.filter((a: any) => !a.is_read).length;
          setUnreadAlerts(unread);
        }

        // Fetch rising waves
        let rising: any[] = [];
        const risingRes = await apiRequest('/waves/rising?limit=3');
        if (risingRes.ok) {
          rising = await risingRes.json();
          setRisingWaves(rising);
        }

        // Fetch suggested riders
        let riders: any[] = [];
        const suggestionRes = await apiRequest('/explore/suggested-riders?limit=4');
        if (suggestionRes.ok) {
          riders = await suggestionRes.json();
          setSuggestedRiders(riders);
        }

        // Save to cache
        lastFetchedTime = Date.now();
        cachedSidebarData = { unreadAlerts: unread, risingWaves: rising, suggestedRiders: riders };
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
        // Invalidate cache immediately on action
        cachedSidebarData = null;
        lastFetchedTime = 0;
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
    { name: 'Settings', path: '/settings', icon: '⚙️' },
  ];

  if (!user) return null;

  return (
    <div className="min-h-screen bg-background text-text-primary transition-colors duration-200">
      {/* Sticky Top Navbar with Glassmorphism */}
      <header className="sticky top-0 z-40 w-full border-b border-card-border bg-background/80 backdrop-blur-md shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between gap-4">
          {/* Logo */}
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => router.push('/ocean')}>
            <Logo size="sm" />
            <span className="hidden sm:inline font-display font-black text-lg bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent select-none">
              Tarang
            </span>
          </div>

          {/* Search Box */}
          <div className="flex-1 max-w-md hidden md:block">
            <div className="relative">
              <input
                type="text"
                placeholder="Search waves, riders, hashtags..."
                className="w-full bg-surface/50 border border-card-border rounded-full pl-10 pr-4 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary focus:bg-surface transition-all duration-200"
                onClick={() => router.push('/discover')}
                readOnly
              />
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-xs pointer-events-none">🔍</span>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3">
            {/* Compose Button */}
            <Link href="/ocean" prefetch={true}>
              <button className="hidden sm:flex items-center gap-2 rounded-full bg-gradient-to-r from-secondary to-primary hover:opacity-95 text-white px-4 py-1.5 text-xs font-bold shadow-sm transition-all active:scale-95">
                <span>✍️</span>
                <span>Compose</span>
              </button>
            </Link>

            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 rounded-full border border-card-border hover:bg-card-border/30 text-text-secondary hover:text-text-primary transition-all duration-200"
              title="Toggle Theme"
            >
              {isDarkMode ? '🌙' : '☀️'}
            </button>

            {/* Notification Bell */}
            <Link href="/alerts" prefetch={true} className="relative p-2 rounded-full border border-card-border hover:bg-card-border/30 text-text-secondary hover:text-text-primary transition-all">
              <span className="text-sm">🔔</span>
              {unreadAlerts > 0 && (
                <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-danger text-[9px] font-extrabold text-white animate-pulse">
                  {unreadAlerts}
                </span>
              )}
            </Link>

            {/* Profile Avatar */}
            <div className="relative flex items-center gap-2 pl-2 border-l border-card-border">
              <Link href="/you" prefetch={true} className="h-8 w-8 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shadow-sm shrink-0 hover:scale-105 transition-transform">
                {user.avatar_url ? (
                  <img src={user.avatar_url} alt="Avatar" className="h-full w-full object-cover" loading="lazy" />
                ) : (
                  user.username[0].toUpperCase()
                )}
              </Link>
              
              <button
                onClick={logout}
                className="p-1 text-text-secondary hover:text-danger transition-colors hidden sm:block"
                title="Logout"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Page Grid Container */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 flex gap-6">
        {/* Left Sidebar */}
        <aside className="hidden md:flex flex-col justify-between w-64 shrink-0 py-6 sticky top-16 h-[calc(100vh-64px)]">
          {/* Navigation Items */}
          <nav className="space-y-1">
            {navItems.map((item) => {
              const isActive = pathname.startsWith(item.path);
              return (
                <Link
                  key={item.name}
                  href={item.path}
                  prefetch={true}
                  className={`flex items-center justify-between rounded-xl px-4 py-2.5 text-sm font-bold transition-all duration-200 group ${
                    isActive
                      ? 'bg-primary/10 text-primary shadow-sm'
                      : 'text-text-secondary hover:bg-card-border/20 hover:text-text-primary'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className={`text-lg transition-transform group-hover:scale-110 ${isActive ? 'text-primary' : 'text-text-muted group-hover:text-text-primary'}`}>
                      {item.icon}
                    </span>
                    <span>{item.name}</span>
                  </div>
                  {item.badge ? (
                    <span className="rounded-full bg-primary px-2 py-0.5 text-xs text-white font-extrabold shadow-sm animate-pulse">
                      {item.badge}
                    </span>
                  ) : null}
                </Link>
              );
            })}
          </nav>

          {/* User footer profile details */}
          <div className="border-t border-card-border pt-4">
            <div className="p-3 rounded-xl bg-surface/30 border border-card-border flex items-center justify-between shadow-sm">
              <div className="flex items-center gap-3 overflow-hidden">
                <div className="h-8 w-8 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shrink-0 shadow-inner">
                  {user.avatar_url ? (
                    <img src={user.avatar_url} alt="Avatar" className="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    user.username[0].toUpperCase()
                  )}
                </div>
                <div className="text-left leading-tight truncate">
                  <p className="text-xs font-bold truncate text-text-primary">
                    {user.full_name || user.username}
                  </p>
                  <p className="text-[10px] text-text-muted truncate">@{user.username}</p>
                </div>
              </div>
              <button
                onClick={logout}
                className="p-1.5 rounded-lg hover:bg-danger/10 text-text-secondary hover:text-danger transition-colors shrink-0"
                title="Logout"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 16l4-4m0 0l-4-4m4 4H7" />
                </svg>
              </button>
            </div>
          </div>
        </aside>

        {/* Center Main Stream Feed */}
        <main className="flex-1 min-h-[calc(100vh-64px)] border-x border-card-border py-6 max-w-2xl px-4 sm:px-6">
          {children}
        </main>

        {/* Right Sidebar - Analytics & Discover tools */}
        <aside className="hidden lg:block w-80 shrink-0 py-6 space-y-6 sticky top-16 h-[calc(100vh-64px)] overflow-y-auto pr-1">
          {/* Announcements Section */}
          <div className="rounded-card border border-card-border bg-surface/30 p-5 shadow-sm space-y-2">
            <h4 className="text-xs font-bold uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
              <span>📢</span> Announcements
            </h4>
            <div className="p-3.5 rounded-xl bg-primary/5 border border-primary/10 text-xs text-text-secondary font-medium leading-relaxed">
              Welcome to the redesigned Tarang! Enjoy responsiveness across all desktop, tablet, and mobile views.
            </div>
          </div>

          {/* Who to Follow - Suggested Riders */}
          <div className="rounded-card border border-card-border bg-card-bg p-5 shadow-sm space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
              <span>👥</span> Who to Follow
            </h4>
            <div className="space-y-3.5">
              {suggestedRiders.map((rider) => (
                <div key={rider.username} className="flex items-center justify-between gap-2">
                  <Link href={`/you/${rider.username}`} prefetch={true} className="flex items-center gap-2.5 group cursor-pointer truncate">
                    <div className="h-8 w-8 rounded-full bg-gradient-to-br from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shrink-0">
                      {rider.avatar_url ? (
                        <img src={rider.avatar_url} alt="Avatar" className="h-full w-full object-cover" loading="lazy" />
                      ) : (
                        rider.username[0].toUpperCase()
                      )}
                    </div>
                    <div className="truncate">
                      <h4 className="text-xs font-bold leading-none group-hover:underline text-text-primary truncate">{rider.full_name || rider.username}</h4>
                      <span className="text-[10px] text-text-muted">@{rider.username}</span>
                    </div>
                  </Link>
                  <button
                    onClick={() => handleFollowRider(rider.id)}
                    className="rounded-full bg-primary/10 px-3.5 py-1 text-[10px] font-bold text-primary hover:bg-primary hover:text-white transition-all active:scale-95 shrink-0"
                  >
                    Ride
                  </button>
                </div>
              ))}
              {suggestedRiders.length === 0 && (
                <p className="text-xs text-text-muted font-bold select-none py-1">No additional suggestions.</p>
              )}
            </div>
          </div>

          {/* Recent Activity - Rising Waves */}
          <div className="rounded-card border border-card-border bg-card-bg p-5 shadow-sm space-y-4">
            <h4 className="text-xs font-bold uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
              <span>🌊</span> Recent Activity
            </h4>
            <div className="space-y-3.5">
              {risingWaves.map((wave) => (
                <div key={wave.id} className="space-y-1.5 border-b border-card-border/40 pb-3 last:border-none last:pb-0">
                  <p className="text-xs text-text-secondary line-clamp-2 leading-relaxed font-medium">
                    {wave.content}
                  </p>
                  <div className="flex justify-between items-center text-[9px] text-text-muted font-bold">
                    <span>@{wave.creator?.username || 'user'}</span>
                    <span>💙 {wave.ripples_count}</span>
                  </div>
                </div>
              ))}
              {risingWaves.length === 0 && (
                <p className="text-xs text-text-muted font-bold select-none py-1">No recent waves.</p>
              )}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
