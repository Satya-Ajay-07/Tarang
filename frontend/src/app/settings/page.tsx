'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { useAuth } from '@/context/AuthContext';
import { apiRequest } from '@/services/api';
import { Button, Modal, Card, Input } from '@/components/ui';

type SettingsSection = 'profile' | 'account' | 'security' | 'privacy' | 'appearance' | 'notifications' | 'support' | 'about';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const [activeSection, setActiveSection] = useState<SettingsSection>('profile');
  const [profileData, setProfileData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Profile Form States
  const [fullName, setFullName] = useState('');
  const [bio, setBio] = useState('');
  const [location, setLocation] = useState('');
  const [country, setCountry] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [website, setWebsite] = useState('');
  const [twitterUrl, setTwitterUrl] = useState('');
  const [githubUrl, setGithubUrl] = useState('');
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [coverFile, setCoverFile] = useState<File | null>(null);

  // Security Form States
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');

  // Deactivate Form States
  const [deactivatePassword, setDeactivatePassword] = useState('');
  const [showDeactivateConfirm, setShowDeactivateConfirm] = useState(false);

  // Delete Form States
  const [deletePassword, setDeletePassword] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Mocked/Saved Local settings states
  const [theme, setTheme] = useState<'light' | 'dark'>('dark');
  const [privateAccount, setPrivateAccount] = useState(false);
  const [circleOnlyComments, setCircleOnlyComments] = useState(false);
  const [emailAlerts, setEmailAlerts] = useState(true);
  const [pushRipples, setPushRipples] = useState(true);
  const [pushJoins, setPushJoins] = useState(true);

  // Load user profile details
  const fetchProfile = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const res = await apiRequest(`/users/profile/${user.username}`);
      if (res.ok) {
        const data = await res.json();
        setProfileData(data);
        setFullName(data.full_name || '');
        setBio(data.bio || '');
        setLocation(data.location || '');
        setCountry(data.country || '');
        setPhoneNumber(data.phone_number || '');
        setWebsite(data.website || '');
        setTwitterUrl(data.twitter_url || '');
        setGithubUrl(data.github_url || '');
        setAvatarPreview(data.avatar_url || null);
        setCoverPreview(data.cover_url || null);
      }
      
      // Load stored theme preference
      if (typeof window !== 'undefined') {
        const isDark = document.documentElement.classList.contains('dark');
        setTheme(isDark ? 'dark' : 'light');
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, [user]);

  const triggerToast = (msg: string, isError = false) => {
    if (isError) {
      setErrorMsg(msg);
      setTimeout(() => setErrorMsg(null), 3000);
    } else {
      setToastMsg(msg);
      setTimeout(() => setToastMsg(null), 3000);
    }
  };

  const handleImageUpload = async (file: File): Promise<string> => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await apiRequest('/media/upload', {
      method: 'POST',
      body: formData
    });
    if (!res.ok) throw new Error('Image upload failed');
    const data = await res.json();
    return data.url;
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      let finalAvatarUrl = avatarPreview;
      let finalCoverUrl = coverPreview;

      if (avatarFile) {
        finalAvatarUrl = await handleImageUpload(avatarFile);
      }
      if (coverFile) {
        finalCoverUrl = await handleImageUpload(coverFile);
      }

      const res = await apiRequest('/users/me', {
        method: 'PUT',
        body: JSON.stringify({
          full_name: fullName,
          bio,
          location,
          country,
          phone_number: phoneNumber,
          website,
          twitter_url: twitterUrl,
          github_url: githubUrl,
          avatar_url: finalAvatarUrl,
          cover_url: finalCoverUrl
        })
      });
      if (res.ok) {
        setAvatarFile(null);
        setCoverFile(null);
        triggerToast("Profile settings updated successfully!");
        fetchProfile();
      } else {
        const data = await res.json();
        triggerToast(data.detail || 'Failed to update profile.', true);
      }
    } catch (err: any) {
      console.error(err);
      triggerToast(err.message || 'Image upload failed. Please try again.', true);
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmNewPassword) {
      triggerToast('New passwords do not match.', true);
      return;
    }
    if (newPassword.length < 8) {
      triggerToast('New password must be at least 8 characters.', true);
      return;
    }
    setSaving(true);
    try {
      const res = await apiRequest('/users/change-password', {
        method: 'POST',
        body: JSON.stringify({
          current_password: currentPassword,
          new_password: newPassword
        })
      });
      if (res.ok) {
        triggerToast('Password changed successfully.');
        setCurrentPassword('');
        setNewPassword('');
        setConfirmNewPassword('');
      } else {
        const data = await res.json();
        triggerToast(data?.error?.message || 'Failed to change password.', true);
      }
    } catch (err) {
      triggerToast('Failed to change password.', true);
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivateAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await apiRequest('/users/deactivate', {
        method: 'POST',
        body: JSON.stringify({ password: deactivatePassword })
      });
      if (res.ok) {
        setShowDeactivateConfirm(false);
        await logout();
      } else {
        const data = await res.json();
        triggerToast(data?.error?.message || 'Incorrect password.', true);
      }
    } catch (err) {
      triggerToast('Failed to deactivate account.', true);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await apiRequest('/users/me', {
        method: 'DELETE',
        body: JSON.stringify({ password: deletePassword })
      });
      if (res.ok) {
        setShowDeleteConfirm(false);
        await logout();
      } else {
        const data = await res.json();
        triggerToast(data?.error?.message || 'Incorrect password.', true);
      }
    } catch (err) {
      triggerToast('Failed to delete account.', true);
    } finally {
      setSaving(false);
    }
  };

  const toggleTheme = (selectedTheme: 'light' | 'dark') => {
    setTheme(selectedTheme);
    if (typeof window !== 'undefined') {
      if (selectedTheme === 'dark') {
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme', 'dark');
      } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('theme', 'light');
      }
    }
    triggerToast(`Theme switched to ${selectedTheme} mode.`);
  };

  if (loading || !profileData) {
    return (
      <MainAppLayout>
        <div className="flex h-screen items-center justify-center">
          <svg className="animate-spin h-8 w-8 text-primary" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
        </div>
      </MainAppLayout>
    );
  }

  const sectionsList: { id: SettingsSection; label: string; icon: string }[] = [
    { id: 'profile', label: 'Edit Profile', icon: '👤' },
    { id: 'account', label: 'Account Info', icon: '🔑' },
    { id: 'security', label: 'Security & Password', icon: '🛡️' },
    { id: 'privacy', label: 'Privacy Settings', icon: '🔒' },
    { id: 'appearance', label: 'Appearance', icon: '🎨' },
    { id: 'notifications', label: 'Notifications', icon: '🔔' },
    { id: 'support', label: 'Help & Support', icon: '💬' },
    { id: 'about', label: 'About Tarang', icon: '⚙️' },
  ];

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6 font-body relative">
        {/* Floating toast notification panel */}
        {(toastMsg || errorMsg) && (
          <div className={`fixed top-20 left-1/2 transform -translate-x-1/2 z-50 text-white text-xs font-bold px-5 py-2.5 rounded-full shadow-lg ${
            errorMsg ? 'bg-danger' : 'bg-success'
          }`}>
            {toastMsg || errorMsg}
          </div>
        )}

        {/* Header */}
        <header className="sticky top-16 z-20 flex flex-col border-b border-card-border bg-background/80 backdrop-blur-md p-4 sm:p-5">
          <h1 className="text-xl font-black bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent font-display select-none">
            Settings
          </h1>
        </header>

        {/* Double Column Settings Panel layout */}
        <div className="p-4 sm:p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Left Navigation pane */}
          <div className="flex flex-col gap-1.5 md:col-span-1 select-none">
            {sectionsList.map((sec) => (
              <button
                key={sec.id}
                onClick={() => setActiveSection(sec.id)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl border text-xs font-black uppercase tracking-wider transition-all duration-200 ${
                  activeSection === sec.id
                    ? 'border-primary bg-primary/10 text-primary shadow-sm'
                    : 'border-card-border bg-card-bg/40 text-text-secondary hover:bg-card-border/30'
                }`}
              >
                <span>{sec.icon}</span>
                <span>{sec.label}</span>
              </button>
            ))}
          </div>

          {/* Right Form content pane */}
          <Card className="md:col-span-2 p-5 sm:p-6 space-y-6">
            {/* Section 1: Edit Profile */}
            {activeSection === 'profile' && (
              <form onSubmit={handleUpdateProfile} className="space-y-4 text-xs font-bold text-text-secondary">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display select-none">👤 Edit Profile Settings</h2>
                
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <span className="block uppercase tracking-wider text-text-muted">Avatar Upload</span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) {
                          setAvatarFile(file);
                          setAvatarPreview(URL.createObjectURL(file));
                        }
                      }}
                      className="text-[10px]"
                    />
                  </div>
                  <div className="space-y-2">
                    <span className="block uppercase tracking-wider text-text-muted">Cover Banner</span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) {
                          setCoverFile(file);
                          setCoverPreview(URL.createObjectURL(file));
                        }
                      }}
                      className="text-[10px]"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 pt-2 border-t border-card-border">
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Display Name</label>
                    <input
                      type="text"
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Location</label>
                    <input
                      type="text"
                      value={location}
                      onChange={(e) => setLocation(e.target.value)}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Country</label>
                    <input
                      type="text"
                      value={country}
                      onChange={(e) => setCountry(e.target.value)}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Phone Number</label>
                    <input
                      type="text"
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                  <div className="space-y-1 col-span-2">
                    <label className="uppercase tracking-wider text-text-muted">Website</label>
                    <input
                      type="text"
                      value={website}
                      onChange={(e) => setWebsite(e.target.value)}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                      placeholder="https://example.com"
                    />
                  </div>
                  <div className="space-y-1 col-span-2">
                    <label className="uppercase tracking-wider text-text-muted">Bio Details</label>
                    <textarea
                      value={bio}
                      onChange={(e) => setBio(e.target.value)}
                      rows={3}
                      maxLength={160}
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary resize-none"
                    />
                  </div>
                </div>

                <div className="flex justify-end pt-3">
                  <Button type="submit" disabled={saving} className="rounded-full px-6">
                    {saving ? 'Saving...' : 'Save Settings'}
                  </Button>
                </div>
              </form>
            )}

            {/* Section 2: Account Info */}
            {activeSection === 'account' && (
              <div className="space-y-4">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display select-none">🔑 Account Information</h2>
                <div className="space-y-3 font-semibold text-xs text-text-secondary select-text">
                  <div className="flex justify-between py-2 border-b border-card-border/40">
                    <span className="text-text-muted font-bold">Username</span>
                    <span className="text-text-primary">@{profileData.username}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-card-border/40">
                    <span className="text-text-muted font-bold">Email Address</span>
                    <span className="text-text-primary">{profileData.email || 'Not verified'}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-card-border/40">
                    <span className="text-text-muted font-bold">Joined Date</span>
                    <span className="text-text-primary">{new Date(profileData.created_at).toLocaleDateString()}</span>
                  </div>
                </div>

                {/* Account Actions */}
                <div className="pt-6 space-y-3 border-t border-card-border select-none">
                  <span className="block text-[10px] font-black uppercase tracking-wider text-text-muted">Account Management</span>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <button
                      onClick={() => setShowDeactivateConfirm(true)}
                      className="rounded-xl border border-warning/30 bg-warning/5 p-4 text-left hover:bg-warning/10 transition-colors"
                    >
                      <h4 className="text-xs font-bold text-warning">Deactivate Account</h4>
                      <p className="text-[10px] text-text-muted mt-1 leading-tight font-semibold">Temporarily disable your profile, waves, and activity.</p>
                    </button>
                    <button
                      onClick={() => setShowDeleteConfirm(true)}
                      className="rounded-xl border border-danger/30 bg-danger/5 p-4 text-left hover:bg-danger/10 transition-colors"
                    >
                      <h4 className="text-xs font-bold text-danger">Delete Account</h4>
                      <p className="text-[10px] text-text-muted mt-1 leading-tight font-semibold">Permanently purge your account data from Tarang servers.</p>
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Section 3: Security */}
            {activeSection === 'security' && (
              <form onSubmit={handleChangePassword} className="space-y-4 text-xs font-bold text-text-secondary">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display select-none">🛡️ Password & Security</h2>
                
                <div className="space-y-3">
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Current Password</label>
                    <input
                      type="password"
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      required
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">New Password</label>
                    <input
                      type="password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      required
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                      placeholder="Minimum 8 characters"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="uppercase tracking-wider text-text-muted">Confirm New Password</label>
                    <input
                      type="password"
                      value={confirmNewPassword}
                      onChange={(e) => setConfirmNewPassword(e.target.value)}
                      required
                      className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                    />
                  </div>
                </div>

                <div className="flex justify-end pt-3">
                  <Button type="submit" disabled={saving} className="rounded-full px-6">
                    {saving ? 'Updating...' : 'Update Password'}
                  </Button>
                </div>
              </form>
            )}

            {/* Section 4: Privacy */}
            {activeSection === 'privacy' && (
              <div className="space-y-4 select-none">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display">🔒 Privacy Settings</h2>
                
                <div className="space-y-4">
                  <label className="flex items-start justify-between gap-4 cursor-pointer">
                    <div className="max-w-[80%]">
                      <h4 className="text-xs font-bold text-text-primary">Private Account</h4>
                      <p className="text-[10px] text-text-muted font-bold leading-tight mt-0.5">Only approved riders can see your waves and timeline activity streams.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={privateAccount}
                      onChange={(e) => {
                        setPrivateAccount(e.target.checked);
                        triggerToast("Privacy settings updated.");
                      }}
                      className="h-4 w-4 rounded border-card-border text-primary focus:ring-primary/40 shrink-0 mt-1"
                    />
                  </label>

                  <label className="flex items-start justify-between gap-4 cursor-pointer pt-3 border-t border-card-border/40">
                    <div className="max-w-[80%]">
                      <h4 className="text-xs font-bold text-text-primary">Limit Circles Interaction</h4>
                      <p className="text-[10px] text-text-muted font-bold leading-tight mt-0.5">Only circle members can reply or join waves published in circle boards.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={circleOnlyComments}
                      onChange={(e) => {
                        setCircleOnlyComments(e.target.checked);
                        triggerToast("Interactions settings updated.");
                      }}
                      className="h-4 w-4 rounded border-card-border text-primary focus:ring-primary/40 shrink-0 mt-1"
                    />
                  </label>
                </div>
              </div>
            )}

            {/* Section 5: Appearance */}
            {activeSection === 'appearance' && (
              <div className="space-y-4 select-none">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display">🎨 Theme & Appearance</h2>
                
                <div className="grid grid-cols-2 gap-4">
                  <button
                    onClick={() => toggleTheme('light')}
                    className={`p-4 rounded-xl border flex flex-col items-center gap-2 transition-all ${
                      theme === 'light'
                        ? 'border-primary bg-primary/10 text-primary shadow-sm font-extrabold'
                        : 'border-card-border bg-card-bg/40 text-text-secondary hover:bg-card-border/30 font-bold'
                    }`}
                  >
                    <span className="text-2xl">☀️</span>
                    <span className="text-xs">Light Theme</span>
                  </button>
                  <button
                    onClick={() => toggleTheme('dark')}
                    className={`p-4 rounded-xl border flex flex-col items-center gap-2 transition-all ${
                      theme === 'dark'
                        ? 'border-primary bg-primary/10 text-primary shadow-sm font-extrabold'
                        : 'border-card-border bg-card-bg/40 text-text-secondary hover:bg-card-border/30 font-bold'
                    }`}
                  >
                    <span className="text-2xl">🌙</span>
                    <span className="text-xs">Dark Theme</span>
                  </button>
                </div>
              </div>
            )}

            {/* Section 6: Notifications */}
            {activeSection === 'notifications' && (
              <div className="space-y-4 select-none">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display">🔔 Notification Settings</h2>
                
                <div className="space-y-4">
                  <label className="flex items-start justify-between gap-4 cursor-pointer">
                    <div>
                      <h4 className="text-xs font-bold text-text-primary">Email Notifications</h4>
                      <p className="text-[10px] text-text-muted font-bold leading-tight mt-0.5">Receive digests and recap updates in your inbox.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={emailAlerts}
                      onChange={(e) => {
                        setEmailAlerts(e.target.checked);
                        triggerToast("Notification preferences updated.");
                      }}
                      className="h-4 w-4 rounded border-card-border text-primary focus:ring-primary/40 shrink-0 mt-1"
                    />
                  </label>

                  <label className="flex items-start justify-between gap-4 cursor-pointer pt-3 border-t border-card-border/40">
                    <div>
                      <h4 className="text-xs font-bold text-text-primary">Wave Ripples</h4>
                      <p className="text-[10px] text-text-muted font-bold leading-tight mt-0.5">Receive alerts when creators ripple (like) your waves.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={pushRipples}
                      onChange={(e) => {
                        setPushRipples(e.target.checked);
                        triggerToast("Notification preferences updated.");
                      }}
                      className="h-4 w-4 rounded border-card-border text-primary focus:ring-primary/40 shrink-0 mt-1"
                    />
                  </label>

                  <label className="flex items-start justify-between gap-4 cursor-pointer pt-3 border-t border-card-border/40">
                    <div>
                      <h4 className="text-xs font-bold text-text-primary">Wave Joins</h4>
                      <p className="text-[10px] text-text-muted font-bold leading-tight mt-0.5">Receive alerts when creators join (reply to) your waves.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={pushJoins}
                      onChange={(e) => {
                        setPushJoins(e.target.checked);
                        triggerToast("Notification preferences updated.");
                      }}
                      className="h-4 w-4 rounded border-card-border text-primary focus:ring-primary/40 shrink-0 mt-1"
                    />
                  </label>
                </div>
              </div>
            )}

            {/* Section 7: Support */}
            {activeSection === 'support' && (
              <div className="space-y-4">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display select-none">💬 Help & Support</h2>
                <div className="space-y-3 text-xs text-text-secondary leading-relaxed font-semibold">
                  <p>Have issues riding waves or configuring circles? Contact our team or explore documentation resources.</p>
                  <div className="p-4 rounded-xl border border-card-border bg-surface/30 space-y-2">
                    <p className="font-bold text-text-primary">📧 Support Email</p>
                    <p className="text-primary font-bold">support@tarangnetwork.com</p>
                  </div>
                  <div className="p-4 rounded-xl border border-card-border bg-surface/30 space-y-2">
                    <p className="font-bold text-text-primary">📖 Creator Guide</p>
                    <p className="text-text-muted text-[10px] font-bold">Learn the protocols for casting waves and joining ripples on the ocean board.</p>
                  </div>
                </div>
              </div>
            )}

            {/* Section 8: About */}
            {activeSection === 'about' && (
              <div className="space-y-4 select-none">
                <h2 className="text-sm font-black text-text-primary border-b border-card-border pb-2.5 font-display">⚙️ About Tarang</h2>
                <div className="space-y-3 text-xs text-text-secondary leading-relaxed font-semibold">
                  <div className="flex justify-between items-center py-2 border-b border-card-border/40">
                    <span className="text-text-muted font-bold">App Version</span>
                    <span className="text-text-primary font-bold">v1.2.0-stable</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-card-border/40">
                    <span className="text-text-muted font-bold">Backend Status</span>
                    <span className="text-success font-bold">Online</span>
                  </div>
                  <p className="text-[10px] text-text-muted pt-2 leading-normal">
                    Tarang is a decentralized interest-based wave networking protocol designed to link creators, circles, and discussions in real-time. Built with Next.js, FastAPI, and Tailwind CSS.
                  </p>
                </div>
              </div>
            )}
          </Card>
        </div>

        {/* Deactivate Confirm Dialog */}
        <Modal
          open={showDeactivateConfirm}
          onClose={() => setShowDeactivateConfirm(false)}
          title="Deactivate Account"
        >
          <p className="text-xs text-text-secondary mb-4 leading-relaxed font-semibold">
            Are you sure you want to deactivate your account? This will hide your profile, waves, and joins until you log in again.
          </p>

          <form onSubmit={handleDeactivateAccount} className="space-y-4 font-body text-xs font-bold text-text-secondary">
            <div className="space-y-1">
              <label className="uppercase tracking-wider text-text-muted">Confirm Password</label>
              <input
                type="password"
                value={deactivatePassword}
                onChange={(e) => setDeactivatePassword(e.target.value)}
                required
                className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                placeholder="Enter password"
              />
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-card-border">
              <Button
                type="button"
                variant="ghost"
                onClick={() => setShowDeactivateConfirm(false)}
                className="rounded-full"
              >
                Cancel
              </Button>
              <button
                type="submit"
                disabled={saving}
                className="rounded-full bg-warning px-5 py-2 text-xs font-bold text-white shadow-sm hover:opacity-90 transition-all"
              >
                {saving ? 'Deactivating...' : 'Confirm Deactivation'}
              </button>
            </div>
          </form>
        </Modal>

        {/* Delete Confirm Dialog */}
        <Modal
          open={showDeleteConfirm}
          onClose={() => setShowDeleteConfirm(false)}
          title="Delete Account"
        >
          <p className="text-xs text-danger mb-4 leading-relaxed font-bold">
            ⚠️ WARNING: This will permanently delete your account, waves, circles, DMs, and bookmarks. This action cannot be undone.
          </p>

          <form onSubmit={handleDeleteAccount} className="space-y-4 font-body text-xs font-bold text-text-secondary">
            <div className="space-y-1">
              <label className="uppercase tracking-wider text-text-muted">Confirm Password</label>
              <input
                type="password"
                value={deletePassword}
                onChange={(e) => setDeletePassword(e.target.value)}
                required
                className="w-full text-sm rounded-xl border border-card-border bg-surface/30 px-4 py-2 outline-none text-text-primary"
                placeholder="Enter password"
              />
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-card-border">
              <Button
                type="button"
                variant="ghost"
                onClick={() => setShowDeleteConfirm(false)}
                className="rounded-full"
              >
                Cancel
              </Button>
              <button
                type="submit"
                disabled={saving}
                className="rounded-full bg-danger px-5 py-2 text-xs font-bold text-white shadow-sm hover:opacity-90 transition-all"
              >
                {saving ? 'Deleting...' : 'Permanently Delete'}
              </button>
            </div>
          </form>
        </Modal>
      </div>
    </MainAppLayout>
  );
}
