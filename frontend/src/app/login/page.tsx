'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import Link from 'next/link';

export default function LoginPage() {
  const { login, loading } = useAuth();
  const [usernameOrEmail, setUsernameOrEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!usernameOrEmail || !password) {
      setError('Please fill in all credentials.');
      return;
    }

    try {
      await login(usernameOrEmail, password, rememberMe);
    } catch (err: any) {
      setError(err.message || 'Unable to sign in. Please verify your inputs.');
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--background)] px-4">
      {/* Background soft light waves (ambient decor) */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-20 dark:opacity-10">
        <svg className="absolute w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M0 40 C 30 50, 70 30, 100 40 L 100 100 L 0 100 Z" fill="url(#wave-grad)" />
          <defs>
            <linearGradient id="wave-grad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#14B8A6" />
              <stop offset="100%" stopColor="#0F4C81" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      <div className="z-10 w-full max-w-md rounded-3xl border border-card-border bg-card-bg p-8 shadow-xl backdrop-blur-md transition-all duration-300">
        <div className="flex flex-col items-center mb-8">
          <Logo size="lg" className="mb-2" />
          <h2 className="text-xl font-semibold tracking-tight text-text-primary">
            Welcome back to the Current
          </h2>
          <p className="text-sm text-text-secondary mt-1">
            Sign in to start spreading your waves
          </p>
        </div>

        {error && (
          <div className="mb-6 rounded-2xl bg-red-50/50 p-4 border border-red-100 dark:bg-red-950/20 dark:border-red-900/30 text-sm text-red-600 dark:text-red-400 flex items-center gap-2 animate-shake">
            <svg className="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-text-secondary mb-2">
              Username or Email
            </label>
            <input
              type="text"
              value={usernameOrEmail}
              onChange={(e) => setUsernameOrEmail(e.target.value)}
              className="w-full rounded-2xl border border-card-border bg-background px-4 py-3.5 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua text-text-primary placeholder-text-muted"
              placeholder="Enter Correct Mail"
              required
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="block text-xs font-semibold uppercase tracking-wider text-text-secondary">
                Password
              </label>
              <Link
                href="/forgot-password"
                className="text-xs font-semibold text-aqua hover:text-ocean dark:hover:text-foam transition-colors"
              >
                Forgot?
              </Link>
            </div>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-2xl border border-card-border bg-background pl-4 pr-12 py-3.5 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua text-text-primary placeholder-text-muted"
                placeholder="••••••••"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-text-primary transition-colors"
              >
                {showPassword ? (
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                )}
              </button>
            </div>
          </div>

          <div className="flex items-center">
            <input
              id="remember-me"
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="h-4.5 w-4.5 rounded border-card-border text-aqua focus:ring-aqua dark:bg-slate-950"
            />
            <label htmlFor="remember-me" className="ml-2 text-xs text-text-secondary font-medium cursor-pointer">
              Remember my session
            </label>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-gradient-to-r from-ocean to-aqua py-4 font-bold text-white shadow-lg shadow-aqua/20 transition-all hover:scale-[1.01] hover:shadow-xl active:scale-[0.99] disabled:opacity-75"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Tuning in...
              </span>
            ) : (
              'Enter the Ocean'
            )}
          </button>
        </form>

        <div className="text-center mt-8 text-xs font-semibold text-text-secondary">
          New rider?{' '}
          <Link href="/signup" className="text-aqua hover:underline">
            Create a Wave account
          </Link>
        </div>
      </div>
    </div>
  );
}
