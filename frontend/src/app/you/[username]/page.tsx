'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { useAuth } from '@/context/AuthContext';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button, Modal } from '@/components/ui';

export default function UserProfilePage() {
  const { user: currentUser } = useAuth();
  const params = useParams();
  const router = useRouter();
  const username = params.username as string;

  const [profileData, setProfileData] = useState<any>(null);
  const [userWaves, setUserWaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isRiding, setIsRiding] = useState(false);
  const [ridingCount, setRidingCount] = useState(0);
  const [ridersCount, setRidersCount] = useState(0);
  const [ridingLoading, setRidingLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<'Waves' | 'Replies' | 'Media' | 'Activity'>('Waves');

  // Follow Dialog states
  const [showFollowModal, setShowFollowModal] = useState(false);
  const [followModalType, setFollowModalType] = useState<'riding' | 'riders'>('riding');
  const [followList, setFollowList] = useState<any[]>([]);
  const [followLoading, setFollowLoading] = useState(false);

  const handleShowFollowModal = async (type: 'riding' | 'riders') => {
    if (!profileData) return;
    setFollowModalType(type);
    setShowFollowModal(true);
    setFollowLoading(true);
    try {
      const endpoint = `/users/${profileData.id}/${type}`;
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
    if (!username) return;
    setLoading(true);
    try {
      // If it's the current user, redirect to /you
      if (currentUser && username === currentUser.username) {
        router.replace('/you');
        return;
      }

      const res = await apiRequest(`/users/profile/${username}`);
      if (res.ok) {
        const data = await res.json();
        setProfileData(data);
        setIsRiding(data.is_riding);
        setRidingCount(data.riding_count || 0);
        setRidersCount(data.riders_count || 0);
      }

      // Fetch waves created by this user
      const wavesRes = await apiRequest('/waves');
      if (wavesRes.ok) {
        const wavesData = await wavesRes.json();
        setUserWaves(wavesData.filter((w: any) => w.creator.username === username));
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, [username, currentUser]);

  const handleToggleRide = async () => {
    if (!profileData || ridingLoading) return;
    setRidingLoading(true);
    try {
      const res = await apiRequest(`/users/ride/${profileData.id}`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setIsRiding(data.riding);
        setRidersCount(prev => data.riding ? prev + 1 : prev - 1);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setRidingLoading(false);
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

  // Filter list based on selected tab
  const getTabWaves = () => {
    switch (activeTab) {
      case 'Waves':
        return userWaves.filter(w => !w.parent_wave_id && w.spread_from_id === null);
      case 'Replies':
        return userWaves.filter(w => w.parent_wave_id !== null);
      case 'Media':
        return userWaves.filter(w => w.media_url !== null);
      case 'Activity':
      default:
        return userWaves;
    }
  };

  const activeList = getTabWaves();

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6 font-body">
        {/* Cover Photo */}
        <div className="h-44 w-full relative overflow-hidden rounded-b-card shadow-sm border border-card-border bg-gradient-to-r from-secondary to-primary">
          {profileData.cover_url && (
            <img src={profileData.cover_url} alt="Cover" className="w-full h-full object-cover" />
          )}
        </div>

        {/* Profile Details */}
        <div className="px-6 relative -mt-16 space-y-4">
          <div className="flex justify-between items-end">
            <div className="h-28 w-28 rounded-full border-4 border-background bg-surface flex items-center justify-center text-4xl font-bold overflow-hidden select-none shadow-md shrink-0">
              {profileData.avatar_url ? (
                <img src={profileData.avatar_url} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-tr from-secondary to-primary text-white flex items-center justify-center font-black text-3xl font-display">
                  {profileData.username[0].toUpperCase()}
                </div>
              )}
            </div>

            <button
              onClick={handleToggleRide}
              disabled={ridingLoading}
              className={`rounded-full px-5 py-2 text-xs font-bold transition-all border shadow-sm ${
                isRiding 
                  ? 'bg-transparent text-text-secondary border-card-border hover:bg-danger/10 hover:text-danger hover:border-danger/35' 
                  : 'bg-primary text-white border-transparent hover:opacity-95'
              }`}
            >
              {isRiding ? 'Riding' : 'Ride'}
            </button>
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
            {profileData.website && (
              <a href={profileData.website} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-primary hover:underline">
                🔗 Website
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
              <span className="font-extrabold">{ridingCount}</span>
              <span className="text-text-muted ml-1 font-semibold">Riding</span>
            </button>
            <button 
              onClick={() => handleShowFollowModal('riders')}
              className="hover:underline cursor-pointer text-left text-text-primary"
            >
              <span className="font-extrabold">{ridersCount}</span>
              <span className="text-text-muted ml-1 font-semibold">Wave Riders</span>
            </button>
            <div className="text-text-primary">
              <span className="font-extrabold">{profileData.wave_count}</span>
              <span className="text-text-muted ml-1 font-semibold">Waves</span>
            </div>
          </div>
        </div>

        {/* Profile Tabs Navigation bar */}
        <div className="mt-6 border-b border-card-border px-6 flex gap-4 text-xs font-black uppercase tracking-wider text-text-secondary select-none">
          {(['Waves', 'Replies', 'Media', 'Activity'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-2.5 border-b-2 transition-all duration-200 ${
                activeTab === tab
                  ? 'border-primary text-primary'
                  : 'border-transparent hover:text-text-primary'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* User waves stream listing */}
        <div className="p-6 space-y-4">
          {activeList.length === 0 ? (
            <div className="text-center py-16 space-y-3.5 border border-dashed border-card-border rounded-card bg-card-bg/10 select-none">
              <div className="text-4xl animate-bounce">
                {activeTab === 'Waves' ? '🌊' : activeTab === 'Replies' ? '💬' : activeTab === 'Media' ? '📸' : '🪶'}
              </div>
              <h3 className="text-sm font-bold text-text-secondary font-display">No content found</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                {activeTab === 'Waves'
                  ? `@${profileData.username} hasn't released any original waves yet.`
                  : activeTab === 'Replies'
                  ? `@${profileData.username} hasn't replied to any waves.`
                  : activeTab === 'Media'
                  ? `@${profileData.username} hasn't uploaded any media attachments.`
                  : `@${profileData.username} has no timeline activities logged.`}
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

              {/* Remaining Waves */}
              {activeList
                .filter(w => activeTab !== 'Waves' || w.id !== profileData.pinned_wave_id)
                .map((wave) => (
                  <WaveCard key={wave.id} wave={wave} onRefresh={fetchProfile} />
                ))}
            </div>
          )}
        </div>

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
