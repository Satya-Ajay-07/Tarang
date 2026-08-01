'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { Logo } from '@/components/ui/Logo';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Global error boundary caught:', error);
  }, [error]);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-tarang-bg-light text-center px-6 dark:bg-tarang-bg-dark space-y-6 select-none">
      <Logo size="lg" />
      <div className="space-y-2">
        <h1 className="text-4xl font-black text-slate-700 dark:text-slate-200">Something drifted</h1>
        <p className="text-sm text-slate-400 max-w-sm mx-auto">
          An unexpected current disrupted the ocean. Try refreshing the wave — if the problem persists, the tide will settle soon.
        </p>
      </div>
      <div className="flex gap-3">
        <button
          onClick={reset}
          className="rounded-2xl bg-gradient-to-r from-ocean to-aqua px-6 py-2.5 text-sm font-bold text-white shadow-md hover:scale-[1.02] transition-all"
        >
          Try Again
        </button>
        <Link
          href="/ocean"
          className="rounded-2xl border border-slate-200 px-6 py-2.5 text-sm font-bold hover:bg-slate-50 transition-all dark:border-slate-700 dark:hover:bg-slate-800"
        >
          Return to Ocean
        </Link>
      </div>
    </div>
  );
}
