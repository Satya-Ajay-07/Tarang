'use client';

import React, { useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { Logo } from '@/components/ui/Logo';

export default function LandingPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading) {
      if (user) {
        // Logged in: redirect to Ocean Feed
        router.push('/ocean');
      } else {
        // Not logged in: go to login
        router.push('/login');
      }
    }
  }, [user, loading, router]);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-tarang-bg-light dark:bg-tarang-bg-dark">
      {/* Splash Screen Minimal Animation */}
      <div className="relative flex flex-col items-center select-none">
        {/* Animated Ripple circles */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 rounded-full border-2 border-aqua/30 animate-ping duration-1000" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 rounded-full border border-ocean/20 animate-ping duration-2000" />

        <div className="z-10 flex flex-col items-center text-center">
          <Logo size="xl" className="mb-4" />
          <h2 className="text-xl font-bold tracking-wider text-ocean dark:text-foam animate-pulse">
            TARANG
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-2 font-medium">
            Every Voice Creates a Wave
          </p>
        </div>
      </div>
    </div>
  );
}
