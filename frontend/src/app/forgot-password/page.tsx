'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import Link from 'next/link';

export default function ForgotPasswordPage() {
  const { forgotPassword } = useAuth();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await forgotPassword(email);
      setSuccess(true);
    } catch (err: any) {
      setError(err.message || 'Unable to trigger password reset.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-tarang-bg-light px-4 dark:bg-tarang-bg-dark">
      <div className="z-10 w-full max-w-md rounded-3xl border border-slate-200/60 bg-white/80 p-8 shadow-xl backdrop-blur-md dark:border-slate-800/40 dark:bg-slate-900/85">
        <div className="flex flex-col items-center mb-6">
          <Logo size="lg" className="mb-2" />
          <h2 className="text-xl font-semibold tracking-tight text-slate-800 dark:text-slate-200">
            Restore Account Flow
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1 text-center">
            Enter your email to receive a password reset token link
          </p>
        </div>

        {success ? (
          <div className="text-center py-6 space-y-4">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-teal-50 dark:bg-teal-950/30 text-teal-500">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">Instructions Sent</h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              We have dispatched a reset link. Please check your inbox (or simulated logs).
            </p>
            <div className="pt-4">
              <Link href="/login" className="text-aqua font-bold hover:underline">
                Back to Login
              </Link>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="p-3 text-xs bg-red-50 dark:bg-red-950/20 text-red-500 border border-red-100 dark:border-red-900/20 rounded-xl">
                {error}
              </div>
            )}
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
                Registered Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3.5 text-sm outline-none transition-all focus:border-aqua dark:border-slate-800 dark:bg-slate-950/50"
                placeholder="e.g. ajay@tarang.in"
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-2xl bg-gradient-to-r from-ocean to-aqua py-3.5 font-bold text-white transition-all disabled:opacity-70"
            >
              {loading ? 'Sending link...' : 'Send Reset Link'}
            </button>
            
            <div className="text-center pt-2">
              <Link href="/login" className="text-xs text-slate-500 hover:text-aqua font-semibold">
                Cancel and return to Login
              </Link>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
