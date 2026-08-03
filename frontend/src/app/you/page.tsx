'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { useAuth } from '@/context/AuthContext';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';
import Link from 'next/link';

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileData, setProfileData] = useState<any>(null);
  const [myWaves, setMyWaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showEditModal, setShowEditModal] = useState(false);
  const [fullName, setFullName] = useState('');
  const [bio, setBio] = useState('');
  const [location, setLocation] = useState('');
  const [country, setCountry] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [website, setWebsite] = useState('');
  const [twitterUrl, setTwitterUrl] = useState('');
  const [githubUrl, setGithubUrl] = useState('');
  
  // Image Upload states
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [updatingImages, setUpdatingImages] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  // Follow Dialog states
  const [showFollowModal, setShowFollowModal] = useState(false);
  const [followModalType, setFollowModalType] = useState<'riding' | 'riders'>('riding');
  const [followList, setFollowList] = useState<any[]>([]);
  const [followLoading, setFollowLoading] = useState(false);

  const handleShowFollowModal = async (type: 'riding' | 'riders') => {
    if (!user) return;
    setFollowModalType(type);
    setShowFollowModal(true);
    setFollowLoading(true);
    try {
      const endpoint = `/users/${user.id}/${type}`;
      const res = await apiRequest(endpoint);
      if (res.ok) {
        setFollowList(await res.json());
      }
    } catch (err) {
      console.error(err);
    } finally {
      setFollowLoading(false);
    }
  };

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

      // Fetch user's waves
      const wavesRes = await apiRequest('/waves');
      if (wavesRes.ok) {
        const wavesData = await wavesRes.json();
        setMyWaves(wavesData.filter((w: any) => w.creator_id === user.id));
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

  // Account Management states
  const { logout } = useAuth();
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deletePassword, setDeletePassword] = useState('');
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [deactivating, setDeactivating] = useState(false);

  const [showDeactivateConfirm, setShowDeactivateConfirm] = useState(false);
  const [deactivatePassword, setDeactivatePassword] = useState('');
  const [deactivateError, setDeactivateError] = useState<string | null>(null);
  const [deactivatingAccount, setDeactivatingAccount] = useState(false);

  const [showChangePasswordModal, setShowChangePasswordModal] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');
  const [changePasswordError, setChangePasswordError] = useState<string | null>(null);
  const [changePasswordSuccess, setChangePasswordSuccess] = useState<string | null>(null);
  const [changingPassword, setChangingPassword] = useState(false);

  const handleDeactivateAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    setDeactivateError(null);
    setDeactivatingAccount(true);
    try {
      const res = await apiRequest('/users/deactivate', {
        method: 'POST',
        body: JSON.stringify({ password: deactivatePassword })
      });
      if (res.ok) {
        setShowDeactivateConfirm(false);
        setShowEditModal(false);
        await logout();
      } else {
        const data = await res.json();
        setDeactivateError(data?.error?.message || 'Incorrect password.');
      }
    } catch (err) {
      setDeactivateError('Failed to deactivate account. Please try again.');
    } finally {
      setDeactivatingAccount(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setChangePasswordError(null);
    setChangePasswordSuccess(null);
    if (newPassword !== confirmNewPassword) {
      setChangePasswordError('New passwords do not match.');
      return;
    }
    if (newPassword.length < 8) {
      setChangePasswordError('New password must be at least 8 characters.');
      return;
    }
    setChangingPassword(true);
    try {
      const res = await apiRequest('/users/change-password', {
        method: 'POST',
        body: JSON.stringify({
          current_password: currentPassword,
          new_password: newPassword
        })
      });
      if (res.ok) {
        setChangePasswordSuccess('Password changed successfully.');
        setCurrentPassword('');
        setNewPassword('');
        setConfirmNewPassword('');
        setTimeout(() => {
          setShowChangePasswordModal(false);
          setChangePasswordSuccess(null);
        }, 1500);
      } else {
        const data = await res.json();
        setChangePasswordError(data?.error?.message || 'Failed to change password.');
      }
    } catch (err) {
      setChangePasswordError('Failed to change password. Please try again.');
    } finally {
      setChangingPassword(false);
    }
  };

  const handleDeleteAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    setDeleteError(null);
    setDeactivating(true);
    try {
      const res = await apiRequest('/users/me', {
        method: 'DELETE',
        body: JSON.stringify({ password: deletePassword })
      });
      if (res.ok) {
        setShowDeleteConfirm(false);
        setShowEditModal(false);
        await logout();
      } else {
        const data = await res.json();
        setDeleteError(data?.error?.message || 'Incorrect password.');
      }
    } catch (err) {
      setDeleteError('Failed to delete account. Please try again.');
    } finally {
      setDeactivating(false);
    }
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setUpdatingImages(true);
    setUpdateError(null);
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
        setShowEditModal(false);
        setAvatarFile(null);
        setCoverFile(null);
        fetchProfile();
      } else {
        const data = await res.json();
        setUpdateError(data.detail || 'Failed to update profile settings.');
      }
    } catch (err: any) {
      console.error(err);
      setUpdateError(err.message || 'Image upload failed. Please try again.');
    } finally {
      setUpdatingImages(false);
    }
  };

  if (loading || !profileData) {
    return (
      <MainAppLayout>
        <div className="flex h-screen items-center justify-center">
          <svg className="animate-spin h-8 w-8 text-aqua" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
        </div>
      </MainAppLayout>
    );
  }

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6">
        {/* Cover Photo */}
        <div className="h-44 bg-gradient-to-r from-ocean to-aqua relative">
          {coverPreview ? (
            <img src={coverPreview} alt="Cover" className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-800 dark:to-slate-900" />
          )}
        </div>

        {/* Profile Card details wrapper */}
        <div className="px-6 relative -mt-16 space-y-4">
          <div className="flex justify-between items-end">
            <div className="h-28 w-28 rounded-full border-4 border-white dark:border-tarang-bg-dark bg-slate-200 dark:bg-slate-800 flex items-center justify-center text-4xl font-bold overflow-hidden select-none">
              {avatarPreview ? (
                <img src={avatarPreview} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-tr from-ocean to-aqua text-white flex items-center justify-center font-extrabold text-3xl">
                  {profileData.username[0].toUpperCase()}
                </div>
              )}
            </div>

            <button
              onClick={() => setShowEditModal(true)}
              className="rounded-full border border-slate-200 bg-white/70 px-4 py-2 text-xs font-bold hover:bg-slate-50 transition-colors dark:border-slate-850 dark:bg-slate-900/50"
            >
              Edit Profile
            </button>
          </div>

          <div>
            <h2 className="text-xl font-bold">{profileData.full_name || profileData.username}</h2>
            <p className="text-xs text-slate-400">@{profileData.username}</p>
          </div>

          {profileData.bio && (
            <p className="text-sm text-slate-600 dark:text-slate-300 whitespace-pre-line">
              {profileData.bio}
            </p>
          )}

          <div className="flex flex-wrap gap-4 text-xs font-semibold text-slate-400">
            {profileData.location && (
              <span className="flex items-center gap-1">📍 {profileData.location}</span>
            )}
            {profileData.country && (
              <span className="flex items-center gap-1">🌍 {profileData.country}</span>
            )}
            {profileData.phone_number && (
              <span className="flex items-center gap-1">📞 {profileData.phone_number}</span>
            )}
            {profileData.website && (
              <a href={profileData.website} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-aqua hover:underline">
                🔗 Website
              </a>
            )}
            {profileData.twitter_url && (
              <a href={profileData.twitter_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-aqua hover:underline">
                🐦 Twitter
              </a>
            )}
            {profileData.github_url && (
              <a href={profileData.github_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-aqua hover:underline">
                💻 GitHub
              </a>
            )}
            <span>📅 Joined {new Date(profileData.created_at).toLocaleDateString()}</span>
          </div>

          {/* Stats counts riders / riding */}
          <div className="flex gap-6 text-sm font-semibold pt-2 border-t border-slate-100 dark:border-slate-800/40 select-none">
            <button 
              onClick={() => handleShowFollowModal('riding')}
              className="hover:underline cursor-pointer text-left text-text-primary"
            >
              <span className="font-bold">{profileData.riding_count}</span>
              <span className="text-text-secondary ml-1">Riding</span>
            </button>
            <button 
              onClick={() => handleShowFollowModal('riders')}
              className="hover:underline cursor-pointer text-left text-text-primary"
            >
              <span className="font-bold">{profileData.riders_count}</span>
              <span className="text-text-secondary ml-1">Wave Riders</span>
            </button>
            <div className="text-text-primary">
              <span className="font-bold">{profileData.wave_count}</span>
              <span className="text-text-secondary ml-1">Waves</span>
            </div>
          </div>
        </div>

        {/* User waves stream listing with Pinned waves support */}
        <div className="p-6 space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-wider text-slate-500 pb-2 border-b border-slate-100 dark:border-slate-800/40">
            Waves
          </h3>
          {myWaves.length === 0 ? (
            <p className="text-center text-xs text-slate-400 py-10">You haven't created any waves yet.</p>
          ) : (
            <div className="space-y-4">
              {/* Pinned Wave */}
              {profileData.pinned_wave_id && myWaves.find(w => w.id === profileData.pinned_wave_id) && (
                <div className="space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-yellow-600 dark:text-yellow-400 pl-4">
                    <span>📌</span>
                    <span>Pinned Wave</span>
                  </div>
                  <WaveCard 
                    wave={myWaves.find(w => w.id === profileData.pinned_wave_id)} 
                    onRefresh={fetchProfile} 
                  />
                </div>
              )}

              {/* Remaining Waves */}
              {myWaves
                .filter(w => w.id !== profileData.pinned_wave_id)
                .map((wave) => (
                  <WaveCard key={wave.id} wave={wave} onRefresh={fetchProfile} />
                ))}
            </div>
          )}
        </div>

        {/* Edit profile dialog modal */}
        {showEditModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-sm p-4 overflow-y-auto">
            <div className="w-full max-w-lg rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-850 dark:bg-slate-900/90 animate-fadeIn">
              <h3 className="text-lg font-bold mb-4">Edit Profile Settings</h3>
              
              {/* Image Previews & Custom Upload */}
              <div className="flex gap-4 mb-6">
                <div className="flex-1">
                  <span className="block text-xs font-bold text-slate-500 uppercase mb-2">Avatar Image</span>
                  <div className="flex items-center gap-3">
                    <div className="h-16 w-16 rounded-full overflow-hidden bg-slate-100 border border-slate-200 dark:border-slate-800 flex items-center justify-center font-bold">
                      {avatarPreview ? (
                        <img src={avatarPreview} alt="Avatar Preview" className="h-full w-full object-cover" />
                      ) : (
                        'None'
                      )}
                    </div>
                    <div className="space-y-1">
                      <input 
                        type="file" 
                        accept="image/*" 
                        id="avatar-upload" 
                        className="hidden" 
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            setAvatarFile(file);
                            setAvatarPreview(URL.createObjectURL(file));
                          }
                        }}
                      />
                      <label htmlFor="avatar-upload" className="block text-xs px-3 py-1.5 bg-aqua text-white rounded-lg cursor-pointer font-semibold text-center hover:bg-ocean">
                        Upload
                      </label>
                      {avatarPreview && (
                        <button
                          type="button"
                          onClick={() => {
                            setAvatarFile(null);
                            setAvatarPreview(null);
                          }}
                          className="block text-[10px] text-red-500 hover:underline font-semibold"
                        >
                          Remove
                        </button>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex-1">
                  <span className="block text-xs font-bold text-slate-500 uppercase mb-2">Cover Image</span>
                  <div className="flex items-center gap-3">
                    <div className="h-16 w-24 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 dark:border-slate-800 flex items-center justify-center font-bold text-xs">
                      {coverPreview ? (
                        <img src={coverPreview} alt="Cover Preview" className="h-full w-full object-cover" />
                      ) : (
                        'None'
                      )}
                    </div>
                    <div className="space-y-1">
                      <input 
                        type="file" 
                        accept="image/*" 
                        id="cover-upload" 
                        className="hidden" 
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            setCoverFile(file);
                            setCoverPreview(URL.createObjectURL(file));
                          }
                        }}
                      />
                      <label htmlFor="cover-upload" className="block text-xs px-3 py-1.5 bg-aqua text-white rounded-lg cursor-pointer font-semibold text-center hover:bg-ocean">
                        Upload
                      </label>
                      {coverPreview && (
                        <button
                          type="button"
                          onClick={() => {
                            setCoverFile(null);
                            setCoverPreview(null);
                          }}
                          className="block text-[10px] text-red-500 hover:underline font-semibold"
                        >
                          Remove
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              <form onSubmit={handleUpdateProfile} className="space-y-4">
                {updateError && (
                  <div className="rounded-xl bg-red-50/50 p-3 border border-red-100 dark:bg-red-950/20 dark:border-red-900/30 text-xs text-red-600 dark:text-red-400">
                    {updateError}
                  </div>
                )}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Display Name
                    </label>
                    <input
                      type="text"
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="Display Name"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Location
                    </label>
                    <input
                      type="text"
                      value={location}
                      onChange={(e) => setLocation(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="Location"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Country
                    </label>
                    <input
                      type="text"
                      value={country}
                      onChange={(e) => setCountry(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="Country"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Phone Number
                    </label>
                    <input
                      type="text"
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="Phone Number"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Website
                    </label>
                    <input
                      type="url"
                      value={website}
                      onChange={(e) => setWebsite(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="https://example.com"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                      Twitter / X
                    </label>
                    <input
                      type="url"
                      value={twitterUrl}
                      onChange={(e) => setTwitterUrl(e.target.value)}
                      className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                      placeholder="https://x.com/username"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    GitHub Link
                  </label>
                  <input
                    type="url"
                    value={githubUrl}
                    onChange={(e) => setGithubUrl(e.target.value)}
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="https://github.com/username"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    Bio
                  </label>
                  <textarea
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    rows={3}
                    maxLength={160}
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 resize-none dark:text-slate-200"
                    placeholder="Tell your story..."
                  />
                </div>

                <div className="pt-4 border-t border-slate-100 dark:border-slate-800/40 space-y-3">
                  <span className="block text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">Account Settings</span>
                  
                  <div className="flex flex-col gap-2">
                    {/* Change Password */}
                    <div className="flex justify-between items-center rounded-2xl border border-slate-200 bg-slate-50/50 p-3 dark:border-slate-800 dark:bg-slate-950/20">
                      <div className="text-left">
                        <p className="text-xs font-bold text-text-primary">Change Password</p>
                        <p className="text-[10px] text-text-secondary">Update your password regularly to secure your account.</p>
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowChangePasswordModal(true)}
                        className="rounded-full border border-[#0891B2] bg-transparent px-3 py-1.5 text-xs font-bold text-[#0891B2] hover:bg-[#0891B2] hover:text-white transition-all"
                      >
                        Change Password
                      </button>
                    </div>

                    {/* Deactivate Account */}
                    <div className="flex justify-between items-center rounded-2xl border border-yellow-200/50 bg-yellow-50/5 p-3 dark:border-yellow-900/30">
                      <div className="text-left">
                        <p className="text-xs font-bold text-yellow-600 dark:text-yellow-500">Deactivate Account</p>
                        <p className="text-[10px] text-text-secondary">Temporarily deactivate your account. Hide your profile and waves.</p>
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowDeactivateConfirm(true)}
                        className="rounded-full bg-yellow-500/10 px-3 py-1.5 text-xs font-bold text-yellow-600 dark:text-yellow-500 hover:bg-yellow-500 hover:text-white transition-all"
                      >
                        Deactivate
                      </button>
                    </div>

                    {/* Delete Account */}
                    <div className="flex justify-between items-center rounded-2xl border border-red-200/50 bg-red-50/5 p-3 dark:border-red-900/30">
                      <div className="text-left">
                        <p className="text-xs font-bold text-red-500">Delete Account</p>
                        <p className="text-[10px] text-text-secondary">Permanently delete your account. This action is irreversible.</p>
                      </div>
                      <button
                        type="button"
                        onClick={() => setShowDeleteConfirm(true)}
                        className="rounded-full bg-red-500/10 px-3 py-1.5 text-xs font-bold text-red-500 hover:bg-red-500 hover:text-white transition-all"
                      >
                        Delete Account
                      </button>
                    </div>
                  </div>
                </div>

                <div className="flex justify-end items-center pt-4 border-t border-slate-100 dark:border-slate-800/40">
                  <div className="flex gap-2">
                    <button
                      type="button"
                      disabled={updatingImages}
                      onClick={() => setShowEditModal(false)}
                      className="rounded-full px-4 py-2 text-xs font-bold border hover:bg-slate-50 dark:hover:bg-slate-800 dark:border-slate-800"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={updatingImages}
                      className="rounded-full bg-aqua px-4 py-2 text-xs font-bold text-white hover:bg-ocean flex items-center gap-1.5"
                    >
                      {updatingImages ? 'Saving...' : 'Save Changes'}
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Change Password Modal */}
        {showChangePasswordModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-sm p-4">
            <div className="w-full max-w-md rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-850 dark:bg-slate-900/90 animate-fadeIn">
              <h3 className="text-lg font-bold text-text-primary mb-2">Change Password</h3>
              
              {changePasswordError && (
                <div className="mb-4 rounded-xl bg-red-50/50 p-3 border border-red-100 dark:bg-red-950/20 dark:border-red-900/30 text-xs text-red-600 dark:text-red-400">
                  {changePasswordError}
                </div>
              )}
              {changePasswordSuccess && (
                <div className="mb-4 rounded-xl bg-green-50/50 p-3 border border-green-100 dark:bg-green-950/20 dark:border-green-900/30 text-xs text-green-600 dark:text-green-400">
                  {changePasswordSuccess}
                </div>
              )}

              <form onSubmit={handleChangePassword} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    Current Password
                  </label>
                  <input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    required
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="Enter current password"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    New Password
                  </label>
                  <input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="Enter new password (min 8 chars)"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    Confirm New Password
                  </label>
                  <input
                    type="password"
                    value={confirmNewPassword}
                    onChange={(e) => setConfirmNewPassword(e.target.value)}
                    required
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="Confirm new password"
                  />
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowChangePasswordModal(false);
                      setCurrentPassword('');
                      setNewPassword('');
                      setConfirmNewPassword('');
                      setChangePasswordError(null);
                      setChangePasswordSuccess(null);
                    }}
                    className="rounded-full px-4 py-2 text-xs font-bold border hover:bg-slate-50 dark:hover:bg-slate-800 dark:border-slate-800"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={changingPassword}
                    className="rounded-full bg-aqua text-white px-4 py-2 text-xs font-bold hover:bg-ocean disabled:opacity-50"
                  >
                    {changingPassword ? 'Updating...' : 'Change Password'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Deactivate Account Confirmation Modal */}
        {showDeactivateConfirm && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-sm p-4">
            <div className="w-full max-w-md rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-850 dark:bg-slate-900/90 animate-fadeIn">
              <h3 className="text-lg font-bold text-yellow-600 mb-2">Deactivate Account</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mb-4 leading-relaxed font-semibold">
                This will temporarily deactivate your profile and waves. You can reactivate your account at any time by logging back in, but ONLY after a 7-day break cooldown. Please enter your password to confirm.
              </p>
              
              {deactivateError && (
                <div className="mb-4 rounded-xl bg-red-50/50 p-3 border border-red-100 dark:bg-red-950/20 dark:border-red-900/30 text-xs text-red-600 dark:text-red-400">
                  {deactivateError}
                </div>
              )}

              <form onSubmit={handleDeactivateAccount} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    Confirm Password
                  </label>
                  <input
                    type="password"
                    value={deactivatePassword}
                    onChange={(e) => setDeactivatePassword(e.target.value)}
                    required
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="Enter password"
                  />
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowDeactivateConfirm(false);
                      setDeactivatePassword('');
                      setDeactivateError(null);
                    }}
                    className="rounded-full px-4 py-2 text-xs font-bold border hover:bg-slate-50 dark:hover:bg-slate-800 dark:border-slate-800"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={deactivatingAccount}
                    className="rounded-full bg-yellow-500 text-white px-4 py-2 text-xs font-bold hover:bg-yellow-600 disabled:opacity-50"
                  >
                    {deactivatingAccount ? 'Deactivating...' : 'Confirm Deactivation'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Delete Account Confirmation Modal */}
        {showDeleteConfirm && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-sm p-4">
            <div className="w-full max-w-md rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-850 dark:bg-slate-900/90 animate-fadeIn">
              <h3 className="text-lg font-bold text-red-500 mb-2">Delete Account</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mb-4 leading-relaxed font-semibold">
                Warning: This action will permanently delete your account and all associated data. This action is irreversible. Please enter your password to confirm.
              </p>
              
              {deleteError && (
                <div className="mb-4 rounded-xl bg-red-50/50 p-3 border border-red-100 dark:bg-red-950/20 dark:border-red-900/30 text-xs text-red-600 dark:text-red-400">
                  {deleteError}
                </div>
              )}

              <form onSubmit={handleDeleteAccount} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1.5">
                    Confirm Password
                  </label>
                  <input
                    type="password"
                    value={deletePassword}
                    onChange={(e) => setDeletePassword(e.target.value)}
                    required
                    className="w-full text-sm rounded-2xl border border-slate-200 px-4 py-2 outline-none dark:border-slate-800 dark:bg-slate-950/40 dark:text-slate-200"
                    placeholder="Enter password"
                  />
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowDeleteConfirm(false);
                      setDeletePassword('');
                      setDeleteError(null);
                    }}
                    className="rounded-full px-4 py-2 text-xs font-bold border hover:bg-slate-50 dark:hover:bg-slate-800 dark:border-slate-800"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={deactivating}
                    className="rounded-full bg-red-500 text-white px-4 py-2 text-xs font-bold hover:bg-red-600 disabled:opacity-50"
                  >
                    {deactivating ? 'Deleting...' : 'Confirm Permanent Deletion'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Follow modal lists */}
        {showFollowModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-sm p-4">
            <div className="w-full max-w-md rounded-3xl border border-slate-200/60 bg-white p-6 shadow-xl dark:border-slate-850 dark:bg-slate-900/90 animate-fadeIn flex flex-col max-h-[80vh]">
              <div className="flex justify-between items-center mb-4 border-b border-slate-100 dark:border-slate-800/40 pb-3">
                <h3 className="text-lg font-bold capitalize">
                  {followModalType === 'riding' ? 'Riding' : 'Wave Riders'}
                </h3>
                <button 
                  onClick={() => {
                    setShowFollowModal(false);
                    setFollowList([]);
                  }}
                  className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-sm font-bold"
                >
                  ✕
                </button>
              </div>

              <div className="flex-1 overflow-y-auto space-y-4 pr-1">
                {followLoading ? (
                  <div className="text-center py-8">
                    <svg className="animate-spin h-6 w-6 text-aqua mx-auto" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                  </div>
                ) : followList.length === 0 ? (
                  <p className="text-center text-xs text-slate-400 py-8">No riders here yet.</p>
                ) : (
                  followList.map((member) => (
                    <div key={member.id} className="flex items-center justify-between">
                      <Link 
                        href={`/you/${member.username}`} 
                        onClick={() => setShowFollowModal(false)}
                        className="flex items-center gap-3 group cursor-pointer"
                      >
                        <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white text-xs font-bold overflow-hidden">
                          {member.avatar_url ? (
                            <img src={member.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                          ) : (
                            member.username[0].toUpperCase()
                          )}
                        </div>
                        <div>
                          <p className="text-sm font-bold leading-none group-hover:underline">
                            {member.full_name || member.username}
                          </p>
                          <p className="text-xs text-slate-400">@{member.username}</p>
                        </div>
                      </Link>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </MainAppLayout>
  );
}
