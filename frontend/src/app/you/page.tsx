'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { useAuth } from '@/context/AuthContext';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';
import Link from 'next/link';
import { Button, Modal, Card } from '@/components/ui';
import { AchievementsSection } from '@/components/achievements/AchievementsSection';

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileData, setProfileData] = useState<any>(null);
  const [myWaves, setMyWaves] = useState<any[]>([]);
  const [bookmarkedWaves, setBookmarkedWaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'Waves' | 'Replies' | 'Media' | 'Bookmarks' | 'Activity'>('Waves');
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

      // Fetch bookmarks
      const bookmarksRes = await apiRequest('/waves/bookmarks');
      if (bookmarksRes.ok) {
        const bookmarksData = await bookmarksRes.json();
        setBookmarkedWaves(bookmarksData);
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
          <svg className="animate-spin h-8 w-8 text-primary" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
        </div>
      </MainAppLayout>
    );
  }

  // Filter lists based on selected tabs
  const getTabWaves = () => {
    switch (activeTab) {
      case 'Waves':
        return myWaves.filter(w => !w.parent_wave_id && w.spread_from_id === null);
      case 'Replies':
        return myWaves.filter(w => w.parent_wave_id !== null);
      case 'Media':
        return myWaves.filter(w => w.media_url !== null);
      case 'Bookmarks':
        return bookmarkedWaves;
      case 'Activity':
      default:
        return myWaves;
    }
  };

  const activeList = getTabWaves();

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6 font-body">
        {/* Cover Photo */}
        <div className="h-44 w-full relative overflow-hidden rounded-b-card shadow-sm border border-card-border bg-gradient-to-r from-secondary to-primary">
          {coverPreview && (
            <img src={coverPreview} alt="Cover" className="w-full h-full object-cover" />
          )}
        </div>

        {/* Profile Card details wrapper */}
        <div className="px-6 relative -mt-16 space-y-4">
          <div className="flex justify-between items-end">
            <div className="h-28 w-28 rounded-full border-4 border-background bg-surface flex items-center justify-center text-4xl font-bold overflow-hidden select-none shadow-md shrink-0">
              {avatarPreview ? (
                <img src={avatarPreview} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-tr from-secondary to-primary text-white flex items-center justify-center font-black text-3xl font-display">
                  {profileData.username[0].toUpperCase()}
                </div>
              )}
            </div>

            <Button
              variant="secondary"
              onClick={() => setShowEditModal(true)}
              className="rounded-full px-5 py-2 text-xs font-bold shadow-sm"
            >
              Edit Profile
            </Button>
          </div>

          <div>
            <h2 className="text-xl font-black text-text-primary font-display">{profileData.full_name || profileData.username}</h2>
            <p className="text-xs text-text-muted font-bold">@{profileData.username}</p>
          </div>

          {profileData.bio && (
            <p className="text-sm text-text-secondary whitespace-pre-line leading-relaxed">
              {profileData.bio}
            </p>
          )}

          <div className="flex flex-wrap gap-4 text-xs font-bold text-text-muted">
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
              <a href={profileData.website} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-primary hover:underline">
                🔗 Website
              </a>
            )}
            {profileData.twitter_url && (
              <a href={profileData.twitter_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-primary hover:underline">
                🐦 Twitter
              </a>
            )}
            {profileData.github_url && (
              <a href={profileData.github_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-primary hover:underline">
                💻 GitHub
              </a>
            )}
            <span>📅 Joined {new Date(profileData.created_at).toLocaleDateString()}</span>
          </div>

          {/* Stats counts riders / riding */}
          <div className="flex gap-6 text-sm font-bold pt-3 border-t border-card-border select-none">
            <button 
              onClick={() => handleShowFollowModal('riding')}
              className="hover:underline cursor-pointer text-left text-text-primary"
            >
              <span className="font-extrabold">{profileData.riding_count}</span>
              <span className="text-text-muted ml-1 font-semibold">Riding</span>
            </button>
            <button 
              onClick={() => handleShowFollowModal('riders')}
              className="hover:underline cursor-pointer text-left text-text-primary"
            >
              <span className="font-extrabold">{profileData.riders_count}</span>
              <span className="text-text-muted ml-1 font-semibold">Wave Riders</span>
            </button>
            <div className="text-text-primary">
              <span className="font-extrabold">{profileData.wave_count}</span>
              <span className="text-text-muted ml-1 font-semibold">Waves</span>
            </div>
          </div>
        </div>

        {/* Profile Tabs Navigation bar */}
        <div className="mt-6 border-b border-card-border px-6 flex gap-4 text-xs font-black uppercase tracking-wider text-text-secondary select-none overflow-x-auto scrollbar-none">
          {(['Waves', 'Replies', 'Media', 'Bookmarks', 'Activity', 'Achievements'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as any)}
              className={`pb-2.5 border-b-2 transition-all duration-200 whitespace-nowrap ${
                activeTab === tab
                  ? 'border-primary text-primary'
                  : 'border-transparent hover:text-text-primary'
              }`}
            >
              {tab === 'Achievements' ? '🏆 ' + tab : tab}
            </button>
          ))}
        </div>

        {/* Achievements Tab */}
        {(activeTab as string) === 'Achievements' ? (
          <AchievementsSection triggerCheck={true} />
        ) : (
        <div className="p-6 space-y-4">
          {activeList.length === 0 ? (
            <div className="text-center py-16 space-y-3.5 border border-dashed border-card-border rounded-card bg-card-bg/10 select-none">
              <div className="text-4xl animate-bounce">
                {activeTab === 'Waves' ? '🌊' : activeTab === 'Replies' ? '💬' : activeTab === 'Media' ? '📸' : activeTab === 'Bookmarks' ? '🔖' : '🪶'}
              </div>
              <h3 className="text-sm font-bold text-text-secondary font-display">No content found</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                {activeTab === 'Waves'
                  ? "You haven't released any original waves yet."
                  : activeTab === 'Replies'
                  ? "You haven't participated in any ripples or discussions."
                  : activeTab === 'Media'
                  ? "There are no images or video attachments on your timeline."
                  : activeTab === 'Bookmarks'
                  ? "Your saved bookmarks list is currently empty."
                  : "No timeline activities logged."}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Pinned Wave (rendered only on original Waves tab) */}
              {activeTab === 'Waves' && profileData.pinned_wave_id && activeList.find(w => w.id === profileData.pinned_wave_id) && (
                <div className="space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-primary pl-4">
                    <span>📌</span>
                    <span>Pinned Wave</span>
                  </div>
                  <WaveCard 
                    wave={activeList.find(w => w.id === profileData.pinned_wave_id)} 
                    onRefresh={fetchProfile} 
                  />
                </div>
              )}

              {/* Remaining List */}
              {activeList
                .filter(w => activeTab !== 'Waves' || w.id !== profileData.pinned_wave_id)
                .map((wave) => (
                  <WaveCard key={wave.id} wave={wave} onRefresh={fetchProfile} />
                ))}
            </div>
          )}
        </div>
        )}

        {/* Edit Profile Modal */}
        <Modal
          open={showEditModal}
          onClose={() => setShowEditModal(false)}
          title="Edit Profile Settings"
          maxWidth={540}
        >
          <div className="max-h-[70vh] overflow-y-auto pr-1">
            <form onSubmit={handleUpdateProfile} className="space-y-4 font-body text-xs font-bold text-text-secondary">
              {updateError && (
                <div className="rounded-xl bg-danger/10 p-3 border border-danger/25 text-danger">
                  {updateError}
                </div>
              )}

              {/* Avatar & Cover updates */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <span className="block uppercase tracking-wider text-text-muted">Avatar Image</span>
                  <div className="flex items-center gap-3">
                    <div className="h-12 w-12 rounded-full overflow-hidden border border-card-border bg-surface shrink-0">
                      {avatarPreview ? (
                        <img src={avatarPreview} alt="Avatar" className="h-full w-full object-cover" />
                      ) : (
                        <div className="h-full w-full bg-slate-200" />
                      )}
                    </div>
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
                      className="text-[10px] w-full"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <span className="block uppercase tracking-wider text-text-muted">Cover Photo</span>
                  <div className="flex items-center gap-3">
                    <div className="h-12 w-20 rounded-xl overflow-hidden border border-card-border bg-surface shrink-0">
                      {coverPreview ? (
                        <img src={coverPreview} alt="Cover" className="h-full w-full object-cover" />
                      ) : (
                        <div className="h-full w-full bg-slate-200" />
                      )}
                    </div>
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
                      className="text-[10px] w-full"
                    />
                  </div>
                </div>
              </div>

              {/* Text Fields */}
              <div className="grid grid-cols-2 gap-4 pt-2 border-t border-card-border">
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Display Name</label>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="Enter display name"
                  />
                </div>
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Location</label>
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="City, State"
                  />
                </div>
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Country</label>
                  <input
                    type="text"
                    value={country}
                    onChange={(e) => setCountry(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="Country"
                  />
                </div>
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Phone Number</label>
                  <input
                    type="text"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="Phone number"
                  />
                </div>
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Website</label>
                  <input
                    type="text"
                    value={website}
                    onChange={(e) => setWebsite(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="https://example.com"
                  />
                </div>
                <div className="space-y-1">
                  <label className="uppercase tracking-wider text-text-muted">Twitter URL</label>
                  <input
                    type="text"
                    value={twitterUrl}
                    onChange={(e) => setTwitterUrl(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="https://twitter.com/..."
                  />
                </div>
                <div className="space-y-1 col-span-2">
                  <label className="uppercase tracking-wider text-text-muted">GitHub URL</label>
                  <input
                    type="text"
                    value={githubUrl}
                    onChange={(e) => setGithubUrl(e.target.value)}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                    placeholder="https://github.com/..."
                  />
                </div>
                <div className="space-y-1 col-span-2">
                  <label className="uppercase tracking-wider text-text-muted">Bio</label>
                  <textarea
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    rows={3}
                    maxLength={160}
                    className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary resize-none"
                    placeholder="Tell your story..."
                  />
                </div>
              </div>

              {/* Account Settings Area */}
              <div className="pt-4 border-t border-card-border space-y-3">
                <span className="block uppercase tracking-wider text-text-muted mb-2">Account Management</span>
                
                <div className="flex flex-col gap-2">
                  {/* Change Password */}
                  <div className="flex justify-between items-center rounded-xl border border-card-border bg-surface/30 p-3">
                    <div className="text-left max-w-[65%]">
                      <p className="text-xs font-bold text-text-primary">Change Password</p>
                      <p className="text-[10px] text-text-muted leading-tight font-semibold">Update your password regularly to secure your account.</p>
                    </div>
                    <Button
                      type="button"
                      variant="secondary"
                      size="sm"
                      onClick={() => setShowChangePasswordModal(true)}
                      className="rounded-full px-3 py-1.5 text-xs font-bold"
                    >
                      Change Password
                    </Button>
                  </div>

                  {/* Deactivate Account */}
                  <div className="flex justify-between items-center rounded-xl border border-warning/20 bg-warning/5 p-3">
                    <div className="text-left max-w-[65%]">
                      <p className="text-xs font-bold text-warning">Deactivate Account</p>
                      <p className="text-[10px] text-text-muted leading-tight font-semibold">Temporarily deactivate your account. Hide profile & waves.</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setShowDeactivateConfirm(true)}
                      className="rounded-full bg-warning/10 px-3 py-1.5 text-xs font-bold text-warning hover:bg-warning hover:text-white transition-all duration-200"
                    >
                      Deactivate
                    </button>
                  </div>

                  {/* Delete Account */}
                  <div className="flex justify-between items-center rounded-xl border border-danger/20 bg-danger/5 p-3">
                    <div className="text-left max-w-[65%]">
                      <p className="text-xs font-bold text-danger">Delete Account</p>
                      <p className="text-[10px] text-text-muted leading-tight font-semibold">Permanently delete your account. Irreversible action.</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setShowDeleteConfirm(true)}
                      className="rounded-full bg-danger/10 px-3 py-1.5 text-xs font-bold text-danger hover:bg-danger hover:text-white transition-all duration-200"
                    >
                      Delete Account
                    </button>
                  </div>
                </div>
              </div>

              {/* Form Buttons */}
              <div className="flex justify-end items-center pt-4 border-t border-card-border gap-2">
                <Button
                  type="button"
                  disabled={updatingImages}
                  onClick={() => setShowEditModal(false)}
                  variant="ghost"
                  className="rounded-full"
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  disabled={updatingImages}
                  className="rounded-full"
                >
                  {updatingImages ? 'Saving...' : 'Save Changes'}
                </Button>
              </div>
            </form>
          </div>
        </Modal>

        {/* Change Password Modal */}
        <Modal
          open={showChangePasswordModal}
          onClose={() => {
            setShowChangePasswordModal(false);
            setChangePasswordError(null);
            setChangePasswordSuccess(null);
          }}
          title="Change Password"
        >
          {changePasswordError && (
            <div className="mb-4 rounded-xl bg-danger/10 p-3 border border-danger/25 text-xs text-danger font-bold">
              {changePasswordError}
            </div>
          )}
          {changePasswordSuccess && (
            <div className="mb-4 rounded-xl bg-success/10 p-3 border border-success/25 text-xs text-success font-bold">
              {changePasswordSuccess}
            </div>
          )}

          <form onSubmit={handleChangePassword} className="space-y-4 font-body text-xs font-bold text-text-secondary">
            <div className="space-y-1">
              <label className="uppercase tracking-wider text-text-muted">Current Password</label>
              <input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                required
                className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                placeholder="Enter current password"
              />
            </div>
            <div className="space-y-1">
              <label className="uppercase tracking-wider text-text-muted">New Password</label>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
                className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                placeholder="Enter new password (min 8 chars)"
              />
            </div>
            <div className="space-y-1">
              <label className="uppercase tracking-wider text-text-muted">Confirm New Password</label>
              <input
                type="password"
                value={confirmNewPassword}
                onChange={(e) => setConfirmNewPassword(e.target.value)}
                required
                className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
                placeholder="Confirm new password"
              />
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-card-border">
              <Button
                type="button"
                variant="ghost"
                onClick={() => setShowChangePasswordModal(false)}
                className="rounded-full"
              >
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={changingPassword}
                className="rounded-full"
              >
                {changingPassword ? 'Saving...' : 'Save'}
              </Button>
            </div>
          </form>
        </Modal>

        {/* Deactivate Confirm */}
        <Modal
          open={showDeactivateConfirm}
          onClose={() => setShowDeactivateConfirm(false)}
          title="Deactivate Account"
        >
          {deactivateError && (
            <div className="mb-4 rounded-xl bg-danger/10 p-3 border border-danger/25 text-xs text-danger font-bold">
              {deactivateError}
            </div>
          )}
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
                className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
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
                disabled={deactivatingAccount}
                className="rounded-full bg-warning px-5 py-2 text-xs font-bold text-white shadow-sm hover:opacity-90 transition-all"
              >
                {deactivatingAccount ? 'Deactivating...' : 'Confirm Deactivation'}
              </button>
            </div>
          </form>
        </Modal>

        {/* Delete Confirm */}
        <Modal
          open={showDeleteConfirm}
          onClose={() => setShowDeleteConfirm(false)}
          title="Delete Account"
        >
          {deleteError && (
            <div className="mb-4 rounded-xl bg-danger/10 p-3 border border-danger/25 text-xs text-danger font-bold">
              {deleteError}
            </div>
          )}
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
                className="w-full text-sm rounded-xl border border-card-border px-4 py-2 outline-none dark:bg-slate-950/40 text-text-primary"
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
                disabled={deactivating}
                className="rounded-full bg-danger px-5 py-2 text-xs font-bold text-white shadow-sm hover:opacity-90 transition-all"
              >
                {deactivating ? 'Deleting...' : 'Permanently Delete'}
              </button>
            </div>
          </form>
        </Modal>

        {/* Follow modal lists */}
        {showFollowModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-background/60 backdrop-blur-md p-4">
            <div className="w-full max-w-md rounded-dialog border border-card-border bg-card-bg p-6 shadow-lg animate-in fade-in-0 zoom-in-95 duration-200 flex flex-col max-h-[85vh] font-body">
              <div className="flex justify-between items-center mb-4 border-b border-card-border pb-3">
                <h3 className="text-base font-black text-text-primary font-display capitalize">
                  {followModalType === 'riding' ? 'Riding' : 'Wave Riders'}
                </h3>
                <button 
                  onClick={() => {
                    setShowFollowModal(false);
                    setFollowList([]);
                  }}
                  className="p-1.5 rounded-full hover:bg-card-border/30 text-text-secondary hover:text-text-primary text-xs font-bold transition-all"
                >
                  ✕
                </button>
              </div>

              <div className="flex-1 overflow-y-auto space-y-4 pr-1">
                {followLoading ? (
                  <div className="text-center py-8">
                    <svg className="animate-spin h-6 w-6 text-primary mx-auto" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                  </div>
                ) : followList.length === 0 ? (
                  <p className="text-center text-xs text-text-muted py-8 font-bold select-none">No riders here yet.</p>
                ) : (
                  followList.map((member) => (
                    <div key={member.id} className="flex items-center justify-between gap-3">
                      <Link 
                        href={`/you/${member.username}`} 
                        onClick={() => setShowFollowModal(false)}
                        className="flex items-center gap-3 group cursor-pointer truncate"
                      >
                        <div className="h-9 w-9 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shrink-0 shadow-sm">
                          {member.avatar_url ? (
                            <img src={member.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                          ) : (
                            member.username[0].toUpperCase()
                          )}
                        </div>
                        <div className="truncate">
                          <p className="text-xs font-bold leading-none group-hover:underline text-text-primary truncate">
                            {member.full_name || member.username}
                          </p>
                          <p className="text-[10px] text-text-muted mt-0.5">@{member.username}</p>
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
