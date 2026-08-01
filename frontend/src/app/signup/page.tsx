'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Logo } from '@/components/ui/Logo';
import Link from 'next/link';

// Simple ISO Country List
const countries = [
  { code: 'IN', name: 'India', dial_code: '+91' },
  { code: 'US', name: 'United States', dial_code: '+1' },
  { code: 'GB', name: 'United Kingdom', dial_code: '+44' },
  { code: 'CA', name: 'Canada', dial_code: '+1' },
  { code: 'AU', name: 'Australia', dial_code: '+61' },
  { code: 'DE', name: 'Germany', dial_code: '+49' },
  { code: 'FR', name: 'France', dial_code: '+33' },
  { code: 'AE', name: 'United Arab Emirates', dial_code: '+971' },
  { code: 'SG', name: 'Singapore', dial_code: '+65' }
];

export default function SignupPage() {
  const { register, loading } = useAuth();
  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [country, setCountry] = useState('India');
  const [countrySearch, setCountrySearch] = useState('');
  const [showCountryDropdown, setShowCountryDropdown] = useState(false);
  const [dialCode, setDialCode] = useState('+91');
  const [phoneRaw, setPhoneRaw] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, text: 'Very Weak', color: 'bg-red-500' });
  const [showToast, setShowToast] = useState(false);

  // Dynamic Password Strength check
  useEffect(() => {
    if (!password) {
      setPasswordStrength({ score: 0, text: 'Very Weak', color: 'bg-red-500' });
      return;
    }
    let score = 0;
    if (password.length >= 8) score += 1;
    if (/[A-Z]/.test(password)) score += 1;
    if (/[0-9]/.test(password)) score += 1;
    if (/[^A-Za-z0-9]/.test(password)) score += 1;

    let text = 'Very Weak';
    let color = 'bg-red-500';

    if (score === 2) {
      text = 'Weak';
      color = 'bg-orange-500';
    } else if (score === 3) {
      text = 'Medium';
      color = 'bg-yellow-500';
    } else if (score === 4) {
      text = 'Strong';
      color = 'bg-emerald-500';
    }

    setPasswordStrength({ score, text, color });
  }, [password]);

  const handleCountrySelect = (cName: string, dCode: string) => {
    setCountry(cName);
    setDialCode(dCode);
    setShowCountryDropdown(false);
  };

  const filteredCountries = countries.filter(c => 
    c.name.toLowerCase().includes(countrySearch.toLowerCase())
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (username.length < 3) {
      setError('Username must be at least 3 characters.');
      return;
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }

    const cleanedPhone = phoneRaw.replace(/\D/g, '');
    if (cleanedPhone.length < 8 || cleanedPhone.length > 15) {
      setError('Please enter a valid phone number (8-15 digits).');
      return;
    }

    const fullPhoneNumber = `${dialCode} ${phoneRaw.trim()}`;

    try {
      await register(email, username, password, fullName, country, fullPhoneNumber);
      setShowToast(true);
    } catch (err: any) {
      setError(err.message || 'Registration failed. Try a different username/email.');
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--background)] px-4 py-12 transition-colors duration-200">
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-20 dark:opacity-10">
        <svg className="absolute w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M0 50 C 40 30, 60 70, 100 50 L 100 100 L 0 100 Z" fill="url(#wave-grad)" />
          <defs>
            <linearGradient id="wave-grad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#14B8A6" />
              <stop offset="100%" stopColor="#0F4C81" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      {showToast && (
        <div className="fixed top-6 right-6 z-50 rounded-2xl bg-emerald-500 text-white px-6 py-4 shadow-xl flex items-center gap-3 animate-slide-in">
          <span className="text-xl">🎉</span>
          <div>
            <p className="font-bold">Welcome aboard!</p>
            <p className="text-xs opacity-90">Registration successful. Check email for validation link.</p>
          </div>
        </div>
      )}

      <div className="z-10 w-full max-w-lg rounded-3xl border border-slate-200/60 bg-white/80 p-8 shadow-xl backdrop-blur-md transition-all duration-300 dark:border-slate-800/40 dark:bg-slate-900/85">
        <div className="flex flex-col items-center mb-8">
          <Logo size="lg" className="mb-2" />
          <h2 className="text-xl font-semibold tracking-tight text-slate-800 dark:text-slate-200">
            Create your Wave Circle Identity
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Every Voice Creates a Wave
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

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Full Name
              </label>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:focus:border-aqua dark:text-slate-200"
                placeholder="Enter your name"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Username
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:focus:border-aqua dark:text-slate-200"
                placeholder="Choose a username"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email Address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:focus:border-aqua dark:text-slate-200"
                placeholder="Enter your email address"
                required
              />
            </div>

            <div className="relative">
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Country
              </label>
              <button
                type="button"
                onClick={() => setShowCountryDropdown(!showCountryDropdown)}
                className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm text-left outline-none transition-all focus:border-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:text-slate-200 flex justify-between items-center"
              >
                <span>{country}</span>
                <span className="text-slate-400 text-xs">▼</span>
              </button>

              {showCountryDropdown && (
                <div className="absolute z-20 top-full left-0 right-0 mt-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl p-2 max-h-52 overflow-y-auto">
                  <input
                    type="text"
                    value={countrySearch}
                    onChange={(e) => setCountrySearch(e.target.value)}
                    placeholder="Search country..."
                    className="w-full px-3 py-2 text-xs border border-slate-200 dark:border-slate-800 rounded-xl mb-2 outline-none dark:bg-slate-950 dark:text-slate-200 focus:border-aqua"
                  />
                  {filteredCountries.map((c) => (
                    <button
                      key={c.code}
                      type="button"
                      onClick={() => handleCountrySelect(c.name, c.dial_code)}
                      className="w-full text-left px-3 py-2 text-xs rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 dark:text-slate-200"
                    >
                      {c.name} ({c.dial_code})
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Phone Number
              </label>
              <div className="flex gap-2">
                <span className="flex items-center justify-center rounded-2xl border border-slate-200 bg-slate-50/50 px-3 text-sm dark:border-slate-800 dark:bg-slate-950/50 dark:text-slate-300 font-bold select-none min-w-[56px]">
                  {dialCode}
                </span>
                <input
                  type="text"
                  value={phoneRaw}
                  onChange={(e) => setPhoneRaw(e.target.value.replace(/[^0-9\s-]/g, ''))}
                  className="w-full rounded-2xl border border-slate-200 bg-white/50 px-4 py-3 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:focus:border-aqua dark:text-slate-200"
                  placeholder="Enter your phone number"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200 bg-white/50 pl-4 pr-10 py-3 text-sm outline-none transition-all focus:border-aqua focus:ring-1 focus:ring-aqua dark:border-slate-800 dark:bg-slate-950/50 dark:focus:border-aqua dark:text-slate-200"
                  placeholder="Min 8 characters"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                >
                  {showPassword ? '🙈' : '👁️'}
                </button>
              </div>

              {password && (
                <div className="mt-2 space-y-1">
                  <div className="flex justify-between text-[10px] font-bold text-slate-500 dark:text-slate-400">
                    <span>Strength: {passwordStrength.text}</span>
                    <span>{passwordStrength.score}/4</span>
                  </div>
                  <div className="h-1 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div 
                      className={`h-full ${passwordStrength.color} transition-all duration-300`} 
                      style={{ width: `${(passwordStrength.score / 4) * 100}%` }}
                    />
                  </div>
                </div>
              )}
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-gradient-to-r from-ocean to-aqua py-3.5 mt-2 font-bold text-white shadow-lg shadow-aqua/20 transition-all hover:scale-[1.01] hover:shadow-xl active:scale-[0.99] disabled:opacity-75"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Launching Wave Account...
              </span>
            ) : (
              'Join the Ocean'
            )}
          </button>
        </form>

        <div className="text-center mt-6 text-xs font-semibold text-slate-500 dark:text-slate-400">
          Already registered?{' '}
          <Link href="/login" className="text-aqua hover:underline">
            Sign In
          </Link>
        </div>
      </div>
    </div>
  );
}

