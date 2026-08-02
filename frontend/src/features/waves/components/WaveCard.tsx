'use client';

import React, { useState, useEffect, useRef } from 'react';
import { apiRequest } from '@/services/api';
import { formatDistanceToNow } from 'date-fns';
import { useRouter } from 'next/navigation';
import { useAuth } from "@/context/AuthContext";
import Link from 'next/link';
import { Modal } from '@/components/ui/Modal';

interface WaveCardProps {
  wave: any;
  onRefresh?: () => void;
}

export const WaveCard: React.FC<WaveCardProps> = ({ wave, onRefresh }) => {
  const router = useRouter();
  const { user } = useAuth();

  const isSpreadWave = wave.spread_from_id !== null && wave.spread_from !== null;
  const activeWaveData = isSpreadWave ? wave.spread_from : wave;

  const [rippled, setRippled] = useState(wave.rippled_by_me);
  const [ripplesCount, setRipplesCount] = useState(wave.ripples_count);
  const [spreaded, setSpreaded] = useState(wave.spread_by_me);
  const [spreadsCount, setSpreadsCount] = useState(wave.spreads_count);
  const [bookmarked, setBookmarked] = useState(wave.bookmarked_by_me);
  const [showJoinForm, setShowJoinForm] = useState(false);
  const [joinContent, setJoinContent] = useState('');
  const [submittingJoin, setSubmittingJoin] = useState(false);
  const [joinsList, setJoinsList] = useState<any[]>([]);
  const [loadedJoins, setLoadedJoins] = useState(false);

  // Menu Dropdown states
  const [showMenu, setShowMenu] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Edit states
  const [showEditModal, setShowEditModal] = useState(false);
  const [editContent, setEditContent] = useState(activeWaveData.content || '');
  const [updatingWave, setUpdatingWave] = useState(false);

  // Report states
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportReason, setReportReason] = useState('Spam');
  const [reportingWave, setReportingWave] = useState(false);

  // Toast feedback states
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [isSpreading, setIsSpreading] = useState(false);
  const [togglingBookmark, setTogglingBookmark] = useState(false);

  const isOwner = user?.id === activeWaveData.creator.id;

  // Auto-close menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setShowMenu(false);
      }
    };
    if (showMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showMenu]);

  // Display toast feedback utility helper
  const triggerToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 3000);
  };

  const handleRipple = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const res = await apiRequest(`/waves/${wave.id}/ripple`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setRippled(data.rippled);
        setRipplesCount(data.ripples_count);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleSpread = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isSpreading) return;

    // Optimistic UI updates
    const nextSpreadedState = !spreaded;
    setSpreaded(nextSpreadedState);
    setSpreadsCount((prev: number) => nextSpreadedState ? prev + 1 : Math.max(0, prev - 1));
    setIsSpreading(true);

    try {
      const res = await apiRequest(`/waves/${wave.id}/spread`, { method: 'POST' });
      if (res.ok) {
        const data = await res.json();
        setSpreaded(data.spread);
        setSpreadsCount(data.wave.spreads_count);
        triggerToast(data.spread ? "Wave spread successfully!" : "Spread removed.");
        // Notify parent context if onRefresh callback exists
        if (onRefresh) onRefresh();
      } else {
        // Revert optimistic updates
        setSpreaded(!nextSpreadedState);
        setSpreadsCount((prev: number) => !nextSpreadedState ? prev + 1 : Math.max(0, prev - 1));
        triggerToast("Failed to spread wave.");
      }
    } 
    catch (err) {
      console.error(err);
      // Revert optimistic updates
      setSpreaded(!nextSpreadedState);
      setSpreadsCount((prev: number) => !nextSpreadedState ? prev + 1 : Math.max(0, prev - 1));
      triggerToast("An error occurred.");
    } finally {
      setIsSpreading(false);
    }
  };

  const handleToggleBookmark = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (togglingBookmark) return;

    // Optimistic UI updates
    const nextBookmarkedState = !bookmarked;
    setBookmarked(nextBookmarkedState);
    setTogglingBookmark(true);

    try {
      const res = await apiRequest(
        `/waves/${activeWaveData.id}/bookmark`,
        { method: nextBookmarkedState ? 'POST' : 'DELETE' }
      );

      if (res.ok) {
        triggerToast(nextBookmarkedState ? "Wave bookmarked!" : "Bookmark removed.");
        if (onRefresh) onRefresh();
      } else {
        // Revert optimistic updates
        setBookmarked(!nextBookmarkedState);
        triggerToast("Failed to update bookmark.");
      }
    } catch (err) {
      console.error(err);
      // Revert optimistic updates
      setBookmarked(!nextBookmarkedState);
      triggerToast("An error occurred.");
    } finally {
      setTogglingBookmark(false);
    }
  };

  const handleDeleteWave = async () => {
    const confirmed = window.confirm("Are you sure you want to delete this Wave?");
    if (!confirmed) return;

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}`, {
        method: "DELETE",
      });

      if (res.ok) {
        triggerToast("Wave deleted successfully.");
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to delete wave.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred during deletion.");
    }
    setShowMenu(false);
  };

  const handleUpdateWave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editContent.trim()) return;

    setUpdatingWave(true);
    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}`, {
        method: "PUT",
        body: JSON.stringify({
          content: editContent,
        }),
      });

      if (res.ok) {
        triggerToast("Wave updated successfully.");
        setShowEditModal(false);
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to update wave.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred during updating.");
    } finally {
      setUpdatingWave(false);
    }
  };

  const handleReportWave = async (e: React.FormEvent) => {
    e.preventDefault();
    setReportingWave(true);
    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/report`, {
        method: "POST",
        body: JSON.stringify({
          reason: reportReason,
        }),
      });

      if (res.ok) {
        triggerToast("Thank you. Wave reported successfully.");
        setShowReportModal(false);
      } else {
        triggerToast("Failed to submit report.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred while reporting.");
    } finally {
      setReportingWave(false);
    }
  };

  const handlePinToggle = async () => {
    const isCurrentlyPinned = user?.pinned_wave_id === activeWaveData.id;
    try {
      const res = await apiRequest('/users/me', {
        method: 'PUT',
        body: JSON.stringify({
          pinned_wave_id: isCurrentlyPinned ? "" : activeWaveData.id
        })
      });

      if (res.ok) {
        triggerToast(isCurrentlyPinned ? "Wave unpinned!" : "Wave pinned to profile!");
        // Update user state fields in AuthContext if needed or refresh
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to toggle pin state.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    }
    setShowMenu(false);
  };

  const handleCopyLink = () => {
    const waveUrl = `https://tarangnetwork.vercel.app/wave/${activeWaveData.id}`;
    navigator.clipboard.writeText(waveUrl)
      .then(() => {
        triggerToast("Link copied to clipboard!");
      })
      .catch((err) => {
        console.error("Could not copy text: ", err);
        triggerToast("Failed to copy link.");
      });
    setShowMenu(false);
  };

  const fetchJoins = async () => {
    try {
      const res = await apiRequest(`/waves/${wave.id}/joins`);
      if (res.ok) {
        const data = await res.json();
        setJoinsList(data);
        setLoadedJoins(true);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleToggleJoin = (e: React.MouseEvent) => {
    e.stopPropagation();
    setShowJoinForm(!showJoinForm);
    if (!loadedJoins) {
      fetchJoins();
    }
  };

  const handleJoinSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!joinContent.trim()) return;

    setSubmittingJoin(true);
    try {
      const res = await apiRequest('/waves', {
        method: 'POST',
        body: JSON.stringify({
          content: joinContent,
          parent_wave_id: wave.id
        })
      });

      if (res.ok) {
        setJoinContent('');
        fetchJoins();
        if (onRefresh) onRefresh();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setSubmittingJoin(false);
    }
  };

  const dateStr = activeWaveData.created_at;
  const parsedDate = typeof dateStr === 'string' && !dateStr.endsWith('Z') && !dateStr.includes('+') 
    ? new Date(dateStr + 'Z') 
    : new Date(dateStr);

  const timeAgo = formatDistanceToNow(parsedDate, { addSuffix: true })
    .replace('about ', '')
    .replace('less than a minute ago', 'just now');

  return (
    <div className="rounded-3xl border border-card-border bg-card-bg p-5 shadow-[0_2px_8px_rgba(0,0,0,0.04)] transition-all hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)] space-y-4 relative">
      {/* Absolute Toast alert feedback */}
      {toastMessage && (
        <div className="absolute top-2 left-1/2 transform -translate-x-1/2 z-50 bg-[#0891B2] text-white text-xs font-bold px-4 py-2 rounded-full shadow-lg transition-all animate-fadeIn">
          {toastMessage}
        </div>
      )}

      {/* Spread header if applicable */}
      {isSpreadWave && (
        <div className="flex items-center gap-2 text-xs font-semibold text-text-secondary">
          <span>🔁</span>
          <span>@{wave.creator.username} spread this wave</span>
        </div>
      )}

      {/* Main card header */}
      <div className="flex items-start justify-between relative">
        <Link href={`/you/${activeWaveData.creator.username}`} className="flex items-center gap-3 group">
          <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white font-bold select-none overflow-hidden shrink-0">
            {activeWaveData.creator.avatar_url ? (
              <img src={activeWaveData.creator.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
            ) : (
              activeWaveData.creator.username[0].toUpperCase()
            )}
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h4 className="text-sm font-bold leading-none group-hover:underline text-text-primary">{activeWaveData.creator.full_name || activeWaveData.creator.username}</h4>
              <span className="text-xs text-text-secondary">@{activeWaveData.creator.username}</span>
            </div>
            <span className="text-[10px] text-text-secondary">{timeAgo}</span>
          </div>
        </Link>

        <div className="flex items-center gap-1.5">
          {/* Bookmark Button */}
          <button
            onClick={handleToggleBookmark}
            disabled={togglingBookmark}
            className={`p-1.5 rounded-full transition-colors focus:outline-none ${
              bookmarked ? 'text-yellow-500 bg-yellow-500/5 hover:bg-yellow-500/10' : 'text-text-secondary hover:text-yellow-500 hover:bg-black/5 dark:hover:bg-white/5'
            } ${togglingBookmark ? 'opacity-50' : ''}`}
            title={bookmarked ? "Remove Bookmark" : "Bookmark Wave"}
          >
            <span className="text-sm select-none">{bookmarked ? '🔖' : '🪶'}</span>
          </button>

          {/* Actions Dropdown Button */}
          <div className="relative" ref={menuRef}>
            <button
              onClick={(e) => {
                e.stopPropagation();
                setShowMenu(!showMenu);
              }}
              className="p-1 rounded-full text-text-secondary hover:text-text-primary hover:bg-black/5 dark:hover:bg-white/5 transition-colors focus:outline-none"
              aria-label="Wave actions"
            >
              <span className="text-lg font-bold leading-none tracking-tighter">•••</span>
            </button>

            {showMenu && (
              <div className="absolute right-0 mt-1 w-44 rounded-2xl border border-card-border bg-card-bg shadow-xl z-30 overflow-hidden py-1">
                {isOwner ? (
                  <>
                    <button
                      onClick={() => {
                        setShowEditModal(true);
                        setShowMenu(false);
                      }}
                      className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 text-left transition-colors"
                    >
                      ✏️ Edit Wave
                    </button>
                    <button
                      onClick={handlePinToggle}
                      className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 text-left transition-colors"
                    >
                      📌 {user?.pinned_wave_id === activeWaveData.id ? "Unpin Wave" : "Pin Wave"}
                    </button>
                    <button
                      onClick={handleDeleteWave}
                      className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-red-500 hover:bg-red-50/50 dark:hover:bg-red-950/20 text-left transition-colors"
                    >
                      🗑️ Delete Wave
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => {
                      setShowReportModal(true);
                      setShowMenu(false);
                    }}
                    className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 text-left transition-colors"
                  >
                    ⚠️ Report Wave
                  </button>
                )}
                <button
                  onClick={handleCopyLink}
                  className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 text-left transition-colors"
                >
                  🔗 Copy Link
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="pl-13 text-sm leading-relaxed text-text-primary">
        <p className="whitespace-pre-wrap">{activeWaveData.content}</p>
        
        {activeWaveData.media_url && (
          <div className="mt-3 overflow-hidden rounded-2xl border border-card-border">
            {activeWaveData.media_type === 'video' ? (
              <video src={activeWaveData.media_url} controls className="w-full max-h-96 object-cover" />
            ) : (
              <img src={activeWaveData.media_url} alt="Wave attachment" className="w-full max-h-96 object-cover" />
            )}
          </div>
        )}
      </div>

      {/* Actions row */}
      <div className="flex justify-around items-center pt-2 border-t border-card-border text-xs text-text-secondary font-semibold select-none">
        {/* Ripple action */}
        <button
          onClick={handleRipple}
          className={`flex items-center gap-2 py-1 px-3 rounded-full transition-colors ${
            rippled ? 'text-aqua bg-aqua/5' : 'hover:text-aqua hover:bg-aqua/5'
          }`}
        >
          <span>{rippled ? '💙' : '🤍'}</span>
          <span>{ripplesCount} Ripples</span>
        </button>

        {/* Join action */}
        <button
          onClick={handleToggleJoin}
          className="flex items-center gap-2 py-1 px-3 rounded-full hover:text-ocean hover:bg-ocean/5 dark:hover:text-foam dark:hover:bg-foam/5 transition-colors"
        >
          <span>💬</span>
          <span>{wave.joins_count} Joins</span>
        </button>

        {/* Spread action */}
        <button
          onClick={handleSpread}
          disabled={isSpreading}
          className={`flex items-center gap-2 py-1 px-3 rounded-full transition-colors ${
            spreaded ? 'text-teal-500 bg-teal-500/5' : 'hover:text-teal-500 hover:bg-teal-500/5'
          } ${isSpreading ? 'opacity-50 cursor-not-allowed' : ''}`}
        >
          <span>{isSpreading ? '⏳' : '🔁'}</span>
          <span>{spreadsCount} Spread</span>
        </button>
      </div>

      {/* Join comments form section */}
      {showJoinForm && (
        <div className="pt-4 border-t border-card-border space-y-4">
          <form onSubmit={handleJoinSubmit} className="flex gap-2">
            <input
              type="text"
              value={joinContent}
              onChange={(e) => setJoinContent(e.target.value)}
              placeholder="Join this wave..."
              className="flex-1 rounded-2xl border border-card-border bg-background px-4 py-2 text-xs outline-none focus:border-aqua text-text-primary placeholder-slate-400"
              required
              disabled={submittingJoin}
            />
            <button
              type="submit"
              disabled={submittingJoin}
              className="rounded-2xl bg-aqua px-4 py-2 text-xs font-bold text-white hover:bg-ocean transition-all disabled:opacity-50"
            >
              Join
            </button>
          </form>

          {/* Subjoins list */}
          <div className="space-y-4 pl-4 border-l border-card-border mt-3">
            {joinsList.map((join) => (
              <div key={join.id} className="scale-95 origin-top-left">
                <WaveCard wave={join} onRefresh={fetchJoins} />
              </div>
            ))}
            {joinsList.length === 0 && loadedJoins && (
              <p className="text-[10px] text-text-secondary pl-2">No joins yet. Be the first to start the ripple.</p>
            )}
          </div>
        </div>
      )}

      {/* Edit Wave Modal */}
      <Modal
        open={showEditModal}
        onClose={() => setShowEditModal(false)}
        title="Edit Wave Content"
      >
        <form onSubmit={handleUpdateWave} className="space-y-4">
          <div className="rounded-2xl border border-card-border bg-background p-3">
            <textarea
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              rows={4}
              maxLength={280}
              className="w-full resize-none bg-transparent text-sm outline-none placeholder-slate-400 border-none focus:ring-0 text-text-primary"
              placeholder="Update your wave..."
              required
              disabled={updatingWave}
            />
            <div className="text-right text-[10px] text-text-secondary font-semibold mt-1">
              {editContent.length}/280
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-card-border">
            <button
              type="button"
              disabled={updatingWave}
              onClick={() => setShowEditModal(false)}
              className="rounded-full border border-card-border bg-card-bg px-4 py-2 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={updatingWave || !editContent.trim()}
              className="rounded-full bg-gradient-to-r from-ocean to-aqua px-5 py-2 text-xs font-bold text-white shadow-md shadow-aqua/10 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
            >
              {updatingWave ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Report Wave Modal */}
      <Modal
        open={showReportModal}
        onClose={() => setShowReportModal(false)}
        title="Report Wave"
        description="Select the most appropriate category describing the violation."
      >
        <form onSubmit={handleReportWave} className="space-y-4">
          <div className="space-y-2">
            {['Spam', 'Harassment', 'Violence', 'Adult Content', 'Other'].map((reason) => (
              <label
                key={reason}
                className="flex items-center gap-3 p-3 rounded-xl border border-card-border bg-card-bg hover:bg-[#F1F5F9] dark:hover:bg-slate-800/30 transition-colors cursor-pointer text-xs font-semibold text-text-primary"
              >
                <input
                  type="radio"
                  name="report-reason"
                  value={reason}
                  checked={reportReason === reason}
                  onChange={(e) => setReportReason(e.target.value)}
                  className="h-4 w-4 text-aqua focus:ring-aqua"
                />
                <span>{reason}</span>
              </label>
            ))}
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-card-border">
            <button
              type="button"
              disabled={reportingWave}
              onClick={() => setShowReportModal(false)}
              className="rounded-full border border-card-border bg-card-bg px-4 py-2 text-xs font-bold text-text-primary hover:bg-[#F1F5F9] dark:hover:bg-slate-800/40 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={reportingWave}
              className="rounded-full bg-[#0891B2] hover:bg-ocean px-5 py-2 text-xs font-bold text-white transition-all disabled:opacity-50"
            >
              {reportingWave ? 'Submitting...' : 'Submit Report'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
