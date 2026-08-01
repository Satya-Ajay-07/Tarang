'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';

function ResetPasswordForm() {
  const { resetPassword } = useAuth();
  const searchParams = useSearchParams();
  const router = useRouter();
  const [token, setToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const t = searchParams.get('token');
    if (t) setToken(t);
  }, [searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    
    if (!token) {
      setError('Verification token is missing. Please trigger a new request.');
      return;
    }
    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setLoading(true);
    try {
      await resetPassword(token, newPassword);
      setSuccess(true);
      setTimeout(() => {
        router.push('/login');
      }, 3000);
    } catch (err: any) {
      setError(err.message || 'Password update failed. Token might be expired.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="z-10 w-full max-w-md rounded-3xl border border-slate-200/60 bg-white/80 p-8 shadow-xl backdrop-blur-md dark:border-slate-800/40 dark:bg-slate-900/85">
      <div className="flex flex-col items-center mb-6">
        <Logo size="lg" className="mb-2" />
        <h2 className="text-xl font-semibold tracking-tight text-slate-800 dark:text-slate-200">
          Reset Password
        </h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Set a secure new key to enter the ocean
        </p>
      </div>

      {success ? (
        <div className="text-center py-6 space-y-4">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-teal-50 dark:bg-teal-950/30 text-teal-500 animate-bounce">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">Success!</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Your credentials have been updated. Redirecting to Login...
          </p>
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
              New Password
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none focus:border-aqua dark:border-slate-800 dark:bg-slate-950/50"
              placeholder="Min 6 characters"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
              Confirm New Password
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none focus:border-aqua dark:border-slate-800 dark:bg-slate-950/50"
              placeholder="Match new password"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-gradient-to-r from-ocean to-aqua py-3.5 font-bold text-white transition-all disabled:opacity-70"
          >
            {loading ? 'Updating...' : 'Update Password'}
          </button>
        </form>
      )}
    </div>
  );
}

export default function ResetPasswordPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-tarang-bg-light px-4 dark:bg-tarang-bg-dark">
      <Suspense fallback={<div>Loading form...</div>}>
        <ResetPasswordForm />
      </Suspense>
    </div>
  );
}
