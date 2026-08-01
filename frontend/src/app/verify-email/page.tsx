'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';

function VerifyEmailForm() {
  const { verifyEmail } = useAuth();
  const searchParams = useSearchParams();
  const router = useRouter();
  
  const [token, setToken] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const isPending = searchParams.get('pending');
    const t = searchParams.get('token');
    
    if (isPending === 'true') {
      setPending(true);
    } else if (t) {
      setToken(t);
      verifyToken(t);
    }
  }, [searchParams]);

  const verifyToken = async (tokenStr: string) => {
    setLoading(true);
    setError(null);
    try {
      await verifyEmail(tokenStr);
      setSuccess(true);
      setTimeout(() => {
        router.push('/login');
      }, 3000);
    } catch (err: any) {
      setError(err.message || 'Verification token is invalid or has expired.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="z-10 w-full max-w-md rounded-3xl border border-slate-200/60 bg-white/80 p-8 shadow-xl backdrop-blur-md dark:border-slate-800/40 dark:bg-slate-900/85">
      <div className="flex flex-col items-center mb-6">
        <Logo size="lg" className="mb-2" />
        <h2 className="text-xl font-semibold tracking-tight text-slate-800 dark:text-slate-200">
          Email Verification
        </h2>
      </div>

      {pending ? (
        <div className="text-center py-4 space-y-4">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-50 dark:bg-blue-950/30 text-blue-500 animate-pulse">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">Verification Pending</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            A verification link has been sent to your email. Please check your inbox (or simulated logs if in development mode) to activate your account.
          </p>
          <div className="pt-4">
            <Link href="/login" className="text-aqua font-bold hover:underline">
              Return to Login
            </Link>
          </div>
        </div>
      ) : loading ? (
        <div className="text-center py-8 space-y-4">
          <svg className="animate-spin h-10 w-10 text-aqua mx-auto" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <p className="text-sm text-slate-500 dark:text-slate-400">Validating verification token with backend servers...</p>
        </div>
      ) : success ? (
        <div className="text-center py-6 space-y-4">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-teal-50 dark:bg-teal-950/30 text-teal-500 animate-bounce">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">Email Verified!</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Your verification was successful. Redirecting to Login...
          </p>
        </div>
      ) : (
        <div className="text-center py-6 space-y-4">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 dark:bg-red-950/30 text-red-500">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">Verification Failed</h3>
          <p className="text-sm text-red-500">{error}</p>
          <div className="pt-4">
            <Link href="/login" className="text-aqua font-bold hover:underline">
              Back to Login
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-tarang-bg-light px-4 dark:bg-tarang-bg-dark">
      <Suspense fallback={<div>Loading verification...</div>}>
        <VerifyEmailForm />
      </Suspense>
    </div>
  );
}
