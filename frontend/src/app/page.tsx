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

  // Loading screen: Show only the Tarang logo and one loading spinner
  if (loading) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-tarang-bg-light dark:bg-tarang-bg-dark">
        <div className="relative flex flex-col items-center select-none gap-6">
          <Logo size="xl" />
          <svg className="animate-spin h-10 w-10 text-aqua" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
        </div>
      </div>
    );
  }

  // Fallback splash/landing content before redirect completes
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-tarang-bg-light dark:bg-tarang-bg-dark">
      <div className="relative flex flex-col items-center select-none">
        {/* Animated Ripple circles */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 rounded-full border-2 border-aqua/30 animate-ping duration-1000" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 rounded-full border border-ocean/20 animate-ping duration-2000" />

        <div className="z-10 flex flex-col items-center text-center">
          <Logo size="xl" />
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-4 font-medium">
            Every Voice Creates a Wave
          </p>
        </div>
      </div>
    </div>
  );
}
