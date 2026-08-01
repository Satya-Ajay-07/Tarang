'use client';

import Link from 'next/link';
import { Logo } from '@/components/ui/Logo';

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-tarang-bg-light text-center px-6 dark:bg-tarang-bg-dark space-y-6 select-none">
      <Logo size="lg" />
      <div className="space-y-2">
        <h1 className="text-6xl font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
          404
        </h1>
        <h2 className="text-lg font-bold text-slate-700 dark:text-slate-200">
          This Wave Doesn't Exist
        </h2>
        <p className="text-sm text-slate-400 max-w-xs mx-auto">
          The page you're looking for has drifted away. Head back to the Ocean.
        </p>
      </div>
      <Link
        href="/ocean"
        className="rounded-2xl bg-gradient-to-r from-ocean to-aqua px-6 py-3 text-sm font-bold text-white shadow-md hover:scale-[1.02] transition-all"
      >
        Return to Ocean
      </Link>
    </div>
  );
}
