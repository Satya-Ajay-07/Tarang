'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { useAuth } from '@/context/AuthContext';
import { WaveCard } from '@/features/waves/components/WaveCard';
import { apiRequest } from '@/services/api';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';

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
          {profileData.cover_url ? (
            <img src={profileData.cover_url} alt="Cover" className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-800 dark:to-slate-900" />
          )}
        </div>

        {/* Profile Details */}
        <div className="px-6 relative -mt-16 space-y-4">
          <div className="flex justify-between items-end">
            <div className="h-28 w-28 rounded-full border-4 border-white dark:border-tarang-bg-dark bg-slate-200 dark:bg-slate-800 flex items-center justify-center text-4xl font-bold overflow-hidden select-none">
              {profileData.avatar_url ? (
                <img src={profileData.avatar_url} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-tr from-ocean to-aqua text-white flex items-center justify-center font-extrabold text-3xl">
                  {profileData.username[0].toUpperCase()}
                </div>
              )}
            </div>

            <button
              onClick={handleToggleRide}
              disabled={ridingLoading}
              className={`rounded-full px-5 py-2 text-xs font-bold transition-all border ${
                isRiding 
                  ? 'bg-transparent text-slate-500 border-slate-200 dark:border-slate-800 hover:bg-red-50 hover:text-red-500 hover:border-red-100 dark:hover:bg-red-950/20' 
                  : 'bg-aqua text-white border-transparent hover:bg-ocean'
              }`}
            >
              {isRiding ? 'Riding' : 'Ride'}
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
            <span>📅 Joined {new Date(profileData.created_at).toLocaleDateString()}</span>
          </div>

          {/* Stats counts riders / riding */}
          <div className="flex gap-6 text-sm font-semibold pt-2 border-t border-slate-100 dark:border-slate-800/40 select-none">
            <button 
              onClick={() => handleShowFollowModal('riding')}
              className="hover:underline cursor-pointer text-left"
            >
              <span className="font-bold text-slate-850 dark:text-slate-100">{ridingCount}</span>
              <span className="text-slate-400 ml-1">Riding</span>
            </button>
            <button 
              onClick={() => handleShowFollowModal('riders')}
              className="hover:underline cursor-pointer text-left"
            >
              <span className="font-bold text-slate-850 dark:text-slate-100">{ridersCount}</span>
              <span className="text-slate-400 ml-1">Wave Riders</span>
            </button>
            <div>
              <span className="font-bold text-slate-850 dark:text-slate-100">{profileData.wave_count || 0}</span>
              <span className="text-slate-400 ml-1">Waves</span>
            </div>
          </div>
        </div>

        {/* User waves stream listing */}
        <div className="p-6 space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-wider text-slate-500 pb-2 border-b border-slate-100 dark:border-slate-800/40">
            Waves
          </h3>
          {userWaves.length === 0 ? (
            <p className="text-center text-xs text-slate-400 py-10">This rider hasn't created any waves yet.</p>
          ) : (
            <div className="space-y-4">
              {userWaves.map((wave) => (
                <WaveCard key={wave.id} wave={wave} onRefresh={fetchProfile} />
              ))}
            </div>
          )}
        </div>

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
