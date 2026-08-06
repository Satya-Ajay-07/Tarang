'use client';

import React, { useState, useEffect, useRef } from 'react';
import { apiRequest } from '@/services/api';
import { formatDistanceToNow } from 'date-fns';
import { useRouter } from 'next/navigation';
import { useAuth } from "@/context/AuthContext";
import Link from 'next/link';
import { Modal } from '@/components/ui/Modal';
import { Card } from '@/components/ui/Card';

interface WaveCardProps {
  wave: any;
  onRefresh?: () => void;
}

const WaveCardComponent: React.FC<WaveCardProps> = ({ wave, onRefresh }) => {
  const router = useRouter();
  const { user } = useAuth();

  const isSpreadWave = wave.spread_from_id !== null && wave.spread_from_id !== undefined;
  const isQuoteSpread = isSpreadWave && wave.content !== null && wave.content !== '';
  const activeWaveData = (isSpreadWave && !isQuoteSpread) ? wave.spread_from : wave;

  // Quote Spread states
  const [showQuoteModal, setShowQuoteModal] = useState(false);
  const [quoteThoughts, setQuoteThoughts] = useState('');
  const [submittingQuote, setSubmittingQuote] = useState(false);
  const [showSpreadMenu, setShowSpreadMenu] = useState(false);
  const spreadMenuRef = useRef<HTMLDivElement>(null);

  const [rippled, setRippled] = useState<boolean>(!!wave.rippled_by_me);
  const [ripplesCount, setRipplesCount] = useState<number>(Number(wave.ripples_count) || 0);
  const [spreaded, setSpreaded] = useState<boolean>(!!wave.spread_by_me);
  const [spreadsCount, setSpreadsCount] = useState<number>(Number(wave.spreads_count) || 0);
  const [bookmarked, setBookmarked] = useState<boolean>(!!wave.bookmarked_by_me);
  const [showJoinForm, setShowJoinForm] = useState(false);
  const [joinContent, setJoinContent] = useState('');
  const [submittingJoin, setSubmittingJoin] = useState(false);
  const [joinsList, setJoinsList] = useState<any[]>([]);
  const [loadedJoins, setLoadedJoins] = useState(false);

  // Poll state
  const [poll, setPoll] = useState(activeWaveData.poll);
  const [votingOptionId, setVotingOptionId] = useState<string | null>(null);

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

  // Auto-close spread menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (spreadMenuRef.current && !spreadMenuRef.current.contains(e.target as Node)) {
        setShowSpreadMenu(false);
      }
    };
    if (showSpreadMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showSpreadMenu]);

  // Display toast feedback utility helper
  const triggerToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 3000);
  };

  const handleRipple = async (e: React.MouseEvent) => {
    e.stopPropagation();
    
    // Optimistic UI updates
    const prevRippled = rippled;
    const prevCount = ripplesCount;
    setRippled(!rippled);
    setRipplesCount(rippled ? ripplesCount - 1 : ripplesCount + 1);

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/ripple`, {
        method: 'POST',
      });
      if (!res.ok) {
        throw new Error('API failed');
      }
    } catch (err) {
      console.error(err);
      setRippled(prevRippled);
      setRipplesCount(prevCount);
    }
  };

  const handleSpread = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isSpreading) return;
    setIsSpreading(true);

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/spread`, {
        method: 'POST',
      });

      if (res.ok) {
        setSpreaded(true);
        setSpreadsCount(prev => prev + 1);
        triggerToast("Wave spread to your timeline!");
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to spread Wave.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    } finally {
      setIsSpreading(false);
    }
  };

  const handleQuoteSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!quoteThoughts.trim() || submittingQuote) return;
    setSubmittingQuote(true);

    try {
      const res = await apiRequest('/waves', {
        method: 'POST',
        body: JSON.stringify({
          content: quoteThoughts,
          spread_from_id: activeWaveData.id,
        })
      });

      if (res.ok) {
        setQuoteThoughts('');
        setShowQuoteModal(false);
        setSpreaded(true);
        setSpreadsCount(prev => prev + 1);
        triggerToast("Spread posted successfully!");
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to spread thoughts.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    } finally {
      setSubmittingQuote(false);
    }
  };

  const handleToggleBookmark = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (togglingBookmark) return;
    setTogglingBookmark(true);

    const prevBookmarked = bookmarked;
    setBookmarked(!bookmarked);

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/bookmark`, {
        method: 'POST',
      });

      if (res.ok) {
        triggerToast(!prevBookmarked ? "Wave bookmarked!" : "Bookmark removed!");
        if (onRefresh) onRefresh();
      } else {
        setBookmarked(prevBookmarked);
        triggerToast("Failed to bookmark Wave.");
      }
    } catch (err) {
      console.error(err);
      setBookmarked(prevBookmarked);
      triggerToast("An error occurred.");
    } finally {
      setTogglingBookmark(false);
    }
  };

  const handleUpdateWave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editContent.trim() || updatingWave) return;
    setUpdatingWave(true);

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          content: editContent
        })
      });

      if (res.ok) {
        setShowEditModal(false);
        triggerToast("Wave updated!");
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to update Wave.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    } finally {
      setUpdatingWave(false);
    }
  };

  const handleDeleteWave = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const confirm = window.confirm("Are you sure you want to delete this Wave?");
    if (!confirm) return;

    try {
      const res = await apiRequest(`/waves/${wave.id}`, {
        method: 'DELETE',
      });

      if (res.ok) {
        triggerToast("Wave deleted.");
        if (onRefresh) onRefresh();
      } else {
        triggerToast("Failed to delete Wave.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    }
  };

  const handleReportWave = async (e: React.FormEvent) => {
    e.preventDefault();
    setReportingWave(true);

    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/report`, {
        method: 'POST',
        body: JSON.stringify({
          reason: reportReason
        })
      });

      if (res.ok) {
        setShowReportModal(false);
        triggerToast("Wave reported. Thank you for keeping Tarang clean.");
      } else {
        triggerToast("Failed to submit report.");
      }
    } catch (err) {
      console.error(err);
      triggerToast("An error occurred.");
    } finally {
      setReportingWave(false);
    }
  };

  const handlePinToggle = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const res = await apiRequest(`/users/pin/${activeWaveData.id}`, {
        method: 'POST'
      });
      if (res.ok) {
        triggerToast(user?.pinned_wave_id === activeWaveData.id ? "Wave unpinned!" : "Wave pinned to profile!");
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

  const handleCopyLink = (e: React.MouseEvent) => {
    e.stopPropagation();
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

  const handleVote = async (optionId: string) => {
    if (poll.my_vote_option_id || votingOptionId) return;
    setVotingOptionId(optionId);
    try {
      const res = await apiRequest(`/waves/${activeWaveData.id}/poll/vote/${optionId}`, {
        method: 'POST',
      });
      if (res.ok) {
        const updatedWave = await res.json();
        setPoll(updatedWave.poll);
        if (onRefresh) onRefresh();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setVotingOptionId(null);
    }
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

  const renderContent = (content: string) => {
    if (!content) return null;
    const regex = /(https?:\/\/[^\s]+|www\.[^\s]+|#[a-zA-Z0-9_]+|@[a-zA-Z0-9_]+)/g;
    const parts = content.split(regex);
    return parts.map((part, index) => {
      if (part.startsWith('#')) {
        const tag = part.slice(1);
        return (
          <Link
            key={index}
            href={`/hashtags/${tag.toLowerCase()}`}
            onClick={(e) => e.stopPropagation()}
            className="text-primary hover:underline font-semibold"
          >
            {part}
          </Link>
        );
      } else if (part.startsWith('@')) {
        const username = part.slice(1);
        return (
          <Link
            key={index}
            href={`/you/${username}`}
            onClick={(e) => e.stopPropagation()}
            className="text-primary hover:underline font-bold"
          >
            {part}
          </Link>
        );
      } else if (part.match(/^(https?:\/\/|www\.)/i)) {
        const href = part.toLowerCase().startsWith('www.') ? `https://${part}` : part;
        const displayUrl = part.length > 30 ? part.slice(0, 30) + '...' : part;
        return (
          <a
            key={index}
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            onClick={(e) => e.stopPropagation()}
            className="text-primary hover:underline font-bold break-all inline-flex items-center gap-0.5"
          >
            🔗 {displayUrl}
          </a>
        );
      }
      return part;
    });
  };

  return (
    <Card hoverable className="space-y-4 relative overflow-hidden transition-all duration-200">
      {/* Absolute Toast alert feedback */}
      {toastMessage && (
        <div className="absolute top-2 left-1/2 transform -translate-x-1/2 z-50 bg-primary text-white text-xs font-bold px-4 py-2 rounded-full shadow-lg transition-all">
          {toastMessage}
        </div>
      )}

      {/* Spread header if applicable */}
      {isSpreadWave && (
        <div className="flex items-center gap-2 text-xs font-bold text-primary select-none border-b border-card-border pb-2">
          <span>🔁</span>
          <span>
            {isQuoteSpread 
              ? `@${wave.creator.username} spread a Wave` 
              : `@${wave.creator.username} spread this wave`}
          </span>
        </div>
      )}

      {/* Main card header */}
      <div className="flex items-start justify-between relative">
        <Link href={`/you/${activeWaveData.creator.username}`} className="flex items-center gap-3 group">
          <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white font-bold select-none overflow-hidden shrink-0 shadow-sm transition-transform duration-200 group-hover:scale-105">
            {activeWaveData.creator.avatar_url ? (
              <img src={activeWaveData.creator.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
            ) : (
              activeWaveData.creator.username[0].toUpperCase()
            )}
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h4 className="text-sm font-black leading-none group-hover:underline text-text-primary font-display">{activeWaveData.creator.full_name || activeWaveData.creator.username}</h4>
              <span className="text-xs text-text-secondary font-medium">@{activeWaveData.creator.username}</span>
            </div>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-[10px] text-text-muted font-semibold flex items-center gap-1.5 select-none">
                {timeAgo}
                {activeWaveData.is_edited && (
                  <span className="inline-flex items-center rounded bg-primary/10 px-1.5 py-0.5 text-[9px] font-extrabold text-primary">
                    Edited
                  </span>
                )}
              </span>
              <span className="text-[10px] text-text-muted font-bold select-none">•</span>
              <span className="text-[10px] text-text-muted font-bold select-none">
                {activeWaveData.circle_id ? '🎯 Circle' : '🌍 Public'}
              </span>
            </div>
          </div>
        </Link>

        {/* Dropdown Options */}
        <div className="relative" ref={menuRef}>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setShowMenu(!showMenu);
            }}
            className="p-2 rounded-full text-text-secondary hover:text-text-primary hover:bg-card-border/30 transition-all active:scale-95 focus:outline-none"
            aria-label="Wave actions"
          >
            <span className="text-sm leading-none font-bold select-none">•••</span>
          </button>

          {showMenu && (
            <div className="absolute right-0 mt-1.5 w-44 rounded-dropdown border border-card-border bg-card-bg shadow-lg z-30 overflow-hidden py-1">
              {isOwner ? (
                <>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowEditModal(true);
                      setShowMenu(false);
                    }}
                    className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-card-border/30 text-left transition-colors"
                  >
                    ✏️ Edit Wave
                  </button>
                  <button
                    onClick={handlePinToggle}
                    className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-card-border/30 text-left transition-colors"
                  >
                    📌 {user?.pinned_wave_id === activeWaveData.id ? "Unpin Wave" : "Pin Wave"}
                  </button>
                  <button
                    onClick={handleDeleteWave}
                    className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-danger hover:bg-danger/10 text-left transition-colors"
                  >
                    🗑️ Delete Wave
                  </button>
                </>
              ) : (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowReportModal(true);
                    setShowMenu(false);
                  }}
                  className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-card-border/30 text-left transition-colors"
                >
                  ⚠️ Report Wave
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Body Content */}
      <div className="pl-13 text-sm leading-relaxed text-text-primary space-y-3">
        <p className="whitespace-pre-wrap leading-relaxed text-text-primary">{renderContent(activeWaveData.content)}</p>
        
        {activeWaveData.media_url && (
          <div className="overflow-hidden rounded-card border border-card-border max-h-96 shadow-sm">
            {activeWaveData.media_type === 'video' ? (
              <video src={activeWaveData.media_url} controls className="w-full max-h-96 object-cover" />
            ) : (
              <img src={activeWaveData.media_url} alt="Wave attachment" className="w-full max-h-96 object-cover hover:scale-[1.01] transition-transform duration-300" />
            )}
          </div>
        )}

        {/* Dynamic Poll visualizer block */}
        {poll && (
          <div className="p-4 rounded-card border border-card-border bg-surface/30 space-y-3 shadow-sm select-none">
            <h5 className="text-xs font-bold text-text-primary">📊 {poll.question}</h5>
            <div className="space-y-2">
              {poll.options.map((option: any) => {
                const isVoted = poll.my_vote_option_id === option.id;
                const hasVotedAny = !!poll.my_vote_option_id;
                const isExpired = new Date(poll.expires_at) < new Date();
                const showResults = hasVotedAny || isExpired;
                
                const totalVotes = poll.options.reduce((sum: number, o: any) => sum + (o.votes_count || 0), 0);
                const percent = totalVotes > 0 ? Math.round(((option.votes_count || 0) / totalVotes) * 100) : 0;
                
                return (
                  <div key={option.id} className="relative overflow-hidden rounded-xl border border-card-border">
                    {showResults ? (
                      <div className="flex items-center justify-between p-3 text-xs relative z-10 font-semibold">
                        <span className="flex items-center gap-1.5 truncate">
                          {option.text} {isVoted && '✅'}
                        </span>
                        <span className="text-text-secondary">{percent}% ({option.votes_count || 0})</span>
                        <div
                          className="absolute inset-y-0 left-0 bg-primary/10 transition-all duration-500 -z-10"
                          style={{ width: `${percent}%` }}
                        />
                      </div>
                    ) : (
                      <button
                        onClick={() => handleVote(option.id)}
                        disabled={!!votingOptionId}
                        className="w-full text-left p-3 text-xs font-semibold text-text-primary hover:bg-card-border/20 transition-all active:scale-[0.99] flex items-center justify-between"
                      >
                        <span>{option.text}</span>
                        {votingOptionId === option.id && <span className="animate-spin text-[10px]">⏳</span>}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
            <div className="text-[10px] text-text-muted font-bold flex justify-between">
              <span>{poll.options.reduce((sum: number, o: any) => sum + (o.votes_count || 0), 0)} votes</span>
              <span>{new Date(poll.expires_at) < new Date() ? 'Closed' : 'Active'}</span>
            </div>
          </div>
        )}

        {/* Embedded Original Wave for Quote Spreads */}
        {isQuoteSpread && (
          <div className="mt-3">
            {wave.spread_from ? (
              <div 
                onClick={(e) => {
                  e.stopPropagation();
                  router.push(`/you/${wave.spread_from.creator.username}`);
                }}
                className="p-4 rounded-card border border-card-border bg-surface/30 hover:bg-surface/60 transition-all shadow-sm cursor-pointer text-left space-y-2"
              >
                <div className="flex items-center gap-2 mb-1.5">
                  <div className="h-5 w-5 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-[8px] font-bold overflow-hidden shrink-0">
                    {wave.spread_from.creator.avatar_url ? (
                      <img src={wave.spread_from.creator.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                    ) : (
                      wave.spread_from.creator.username[0].toUpperCase()
                    )}
                  </div>
                  <span className="text-xs font-bold text-text-primary leading-none">{wave.spread_from.creator.full_name || wave.spread_from.creator.username}</span>
                  <span className="text-[10px] text-text-muted">@{wave.spread_from.creator.username}</span>
                </div>
                <p className="text-xs text-text-primary whitespace-pre-wrap leading-relaxed">{renderContent(wave.spread_from.content)}</p>
                {wave.spread_from.media_url && (
                  <div className="mt-2 overflow-hidden rounded-xl border border-card-border max-h-40 shadow-inner">
                    {wave.spread_from.media_type === 'video' ? (
                      <video src={wave.spread_from.media_url} className="w-full max-h-40 object-cover" />
                    ) : (
                      <img src={wave.spread_from.media_url} alt="Attached media" className="w-full max-h-40 object-cover" />
                    )}
                  </div>
                )}
              </div>
            ) : (
              <div className="p-4 rounded-card border border-dashed border-card-border bg-card-bg/25 text-xs font-bold text-text-muted text-center select-none">
                🚫 This original Wave is no longer available.
              </div>
            )}
          </div>
        )}
      </div>

      {/* Footer Actions row */}
      <div className="flex justify-around items-center pt-2 border-t border-card-border text-[11px] text-text-secondary font-bold select-none">
        {/* Ripple action */}
        <button
          onClick={handleRipple}
          className={`flex items-center gap-1.5 py-1.5 px-3.5 rounded-full transition-all duration-200 hover:scale-105 active:scale-95 ${
            rippled ? 'text-primary bg-primary/10 shadow-inner' : 'hover:text-primary hover:bg-primary/10'
          }`}
        >
          <span className="text-sm leading-none">{rippled ? '💙' : '🤍'}</span>
          <span>{ripplesCount}</span>
        </button>

        {/* Join action */}
        <button
          onClick={handleToggleJoin}
          className="flex items-center gap-1.5 py-1.5 px-3.5 rounded-full hover:text-secondary hover:bg-secondary/10 hover:scale-105 active:scale-95 transition-all duration-200"
        >
          <span className="text-sm leading-none">💬</span>
          <span>{wave.joins_count}</span>
        </button>

        {/* Spread action */}
        <div className="relative" ref={spreadMenuRef}>
          <button
            onClick={(e) => {
              e.stopPropagation();
              if (wave.spread_from_id && !wave.spread_from) {
                triggerToast("Cannot spread a deleted Wave.");
                return;
              }
              setShowSpreadMenu(!showSpreadMenu);
            }}
            disabled={isSpreading}
            className={`flex items-center gap-1.5 py-1.5 px-3.5 rounded-full transition-all duration-200 hover:scale-105 active:scale-95 ${
              spreaded ? 'text-teal-500 bg-teal-500/10 shadow-inner' : 'hover:text-teal-500 hover:bg-teal-500/10'
            } ${isSpreading ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            <span className="text-sm leading-none">{isSpreading ? '⏳' : '🔁'}</span>
            <span>{spreadsCount}</span>
          </button>

          {showSpreadMenu && (
            <div className="absolute bottom-full mb-1.5 left-1/2 transform -translate-x-1/2 w-48 rounded-dropdown border border-card-border bg-card-bg shadow-lg z-30 overflow-hidden py-1">
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowSpreadMenu(false);
                  handleSpread(e);
                }}
                className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-card-border/30 text-left transition-colors"
              >
                🌊 Spread Immediately
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowSpreadMenu(false);
                  setShowQuoteModal(true);
                }}
                className="flex w-full items-center px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-card-border/30 text-left transition-colors"
              >
                💭 Spread + Thoughts
              </button>
            </div>
          )}
        </div>

        {/* Bookmark action */}
        <button
          onClick={handleToggleBookmark}
          disabled={togglingBookmark}
          className={`flex items-center gap-1.5 py-1.5 px-3.5 rounded-full transition-all duration-200 hover:scale-105 active:scale-95 ${
            bookmarked ? 'text-yellow-500 bg-yellow-500/10 shadow-inner' : 'hover:text-yellow-500 hover:bg-yellow-500/10'
          }`}
          title={bookmarked ? "Remove Bookmark" : "Bookmark Wave"}
        >
          <span className="text-sm leading-none">{bookmarked ? '🔖' : '🪶'}</span>
          <span>Save</span>
        </button>

        {/* Share Link action */}
        <button
          onClick={handleCopyLink}
          className="flex items-center gap-1.5 py-1.5 px-3.5 rounded-full hover:text-primary hover:bg-primary/10 hover:scale-105 active:scale-95 transition-all duration-200"
          title="Copy link"
        >
          <span className="text-sm leading-none">🔗</span>
          <span>Share</span>
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
              className="flex-1 rounded-full border border-card-border bg-surface/30 px-4 py-2 text-xs outline-none focus:border-primary focus:bg-surface text-text-primary placeholder-text-muted transition-all duration-200"
              required
              disabled={submittingJoin}
            />
            <button
              type="submit"
              disabled={submittingJoin}
              className="rounded-full bg-primary hover:opacity-90 px-4 py-2 text-xs font-bold text-white transition-all disabled:opacity-50"
            >
              Join
            </button>
          </form>

          {/* Subjoins list */}
          <div className="space-y-4 pl-4 border-l border-card-border mt-3">
            {joinsList.map((join) => (
              <div key={join.id} className="scale-[0.98] origin-top-left">
                <WaveCard wave={join} onRefresh={fetchJoins} />
              </div>
            ))}
            {joinsList.length === 0 && loadedJoins && (
              <p className="text-[10px] text-text-muted pl-2 font-bold select-none">No joins yet. Be the first to start the ripple.</p>
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
        <form onSubmit={handleUpdateWave} className="space-y-4 font-body">
          <div className="rounded-card border border-card-border bg-surface/40 p-3.5 focus-within:ring-2 focus-within:ring-primary/20 focus-within:border-primary focus-within:bg-surface/85 transition-all">
            <textarea
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              rows={4}
              maxLength={280}
              className="w-full resize-none bg-transparent text-sm outline-none placeholder-text-muted border-none focus:ring-0 text-text-primary"
              placeholder="Update your wave..."
              required
              disabled={updatingWave}
            />
            <div className="text-right text-[10px] text-text-muted font-bold mt-1">
              {editContent.length}/280
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-card-border">
            <button
              type="button"
              disabled={updatingWave}
              onClick={() => setShowEditModal(false)}
              className="rounded-full border border-card-border bg-card-bg px-4 py-2 text-xs font-bold text-text-primary hover:bg-card-border/30 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={updatingWave || !editContent.trim()}
              className="rounded-full bg-gradient-to-r from-secondary to-primary px-5 py-2 text-xs font-bold text-white shadow-md hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
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
        <form onSubmit={handleReportWave} className="space-y-4 font-body">
          <div className="space-y-2">
            {['Spam', 'Harassment', 'Violence', 'Adult Content', 'Other'].map((reason) => (
              <label
                key={reason}
                className="flex items-center gap-3 p-3 rounded-xl border border-card-border bg-card-bg hover:bg-card-border/20 transition-colors cursor-pointer text-xs font-bold text-text-primary"
              >
                <input
                  type="radio"
                  name="report-reason"
                  value={reason}
                  checked={reportReason === reason}
                  onChange={(e) => setReportReason(e.target.value)}
                  className="h-4 w-4 text-primary focus:ring-primary/40"
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
              className="rounded-full border border-card-border bg-card-bg px-4 py-2 text-xs font-bold text-text-primary hover:bg-card-border/30 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={reportingWave}
              className="rounded-full bg-primary hover:opacity-95 px-5 py-2 text-xs font-bold text-white transition-all disabled:opacity-50"
            >
              {reportingWave ? 'Submitting...' : 'Submit Report'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Quote Spread Modal */}
      <Modal
        open={showQuoteModal}
        onClose={() => setShowQuoteModal(false)}
        title="Spread + Thoughts"
      >
        <form onSubmit={handleQuoteSubmit} className="space-y-4 font-body">
          <div className="rounded-card border border-card-border bg-surface/40 p-3.5 focus-within:ring-2 focus-within:ring-primary/20 focus-within:border-primary focus-within:bg-surface/85 transition-all">
            <textarea
              value={quoteThoughts}
              onChange={(e) => setQuoteThoughts(e.target.value)}
              rows={3}
              maxLength={280}
              className="w-full resize-none bg-transparent text-sm outline-none placeholder-text-muted border-none focus:ring-0 text-text-primary"
              placeholder="Share why you're spreading this Wave..."
              required
              disabled={submittingQuote}
            />
            <div className="text-right text-[10px] text-text-muted font-bold mt-1">
              {quoteThoughts.length}/280
            </div>
          </div>

          {/* Original Wave Preview (compact) */}
          <div className="p-4 rounded-card border border-card-border bg-surface/30 text-left space-y-2">
            <div className="flex items-center gap-2 mb-1">
              <div className="h-5 w-5 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-[8px] font-bold overflow-hidden shrink-0">
                {activeWaveData.creator.avatar_url ? (
                  <img src={activeWaveData.creator.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                ) : (
                  activeWaveData.creator.username[0].toUpperCase()
                )}
              </div>
              <span className="text-xs font-bold text-text-primary leading-none">{activeWaveData.creator.full_name || activeWaveData.creator.username}</span>
              <span className="text-[10px] text-text-muted">@{activeWaveData.creator.username}</span>
            </div>
            <p className="text-xs text-text-primary line-clamp-3 leading-relaxed">{activeWaveData.content}</p>
            {activeWaveData.media_url && (
              <div className="mt-2 overflow-hidden rounded-xl border border-card-border max-h-20 w-32 shadow-inner">
                {activeWaveData.media_type === 'video' ? (
                  <video src={activeWaveData.media_url} className="w-full h-full object-cover" />
                ) : (
                  <img src={activeWaveData.media_url} alt="Attachment preview" className="w-full h-full object-cover" />
                )}
              </div>
            )}
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-card-border">
            <button
              type="button"
              disabled={submittingQuote}
              onClick={() => setShowQuoteModal(false)}
              className="rounded-full border border-card-border bg-card-bg px-4 py-2 text-xs font-bold text-text-primary hover:bg-card-border/30 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submittingQuote || !quoteThoughts.trim()}
              className="rounded-full bg-gradient-to-r from-secondary to-primary px-5 py-2 text-xs font-bold text-white shadow-md hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
            >
              {submittingQuote ? 'Spreading...' : 'Spread'}
            </button>
          </div>
        </form>
      </Modal>
    </Card>
  );
};

export const WaveCard = React.memo(WaveCardComponent, (prev, next) => {
  return prev.wave.id === next.wave.id &&
         prev.wave.ripples_count === next.wave.ripples_count &&
         prev.wave.joins_count === next.wave.joins_count &&
         prev.wave.spreads_count === next.wave.spreads_count &&
         prev.wave.rippled_by_me === next.wave.rippled_by_me &&
         prev.wave.spread_by_me === next.wave.spread_by_me &&
         prev.wave.bookmarked_by_me === next.wave.bookmarked_by_me;
});
