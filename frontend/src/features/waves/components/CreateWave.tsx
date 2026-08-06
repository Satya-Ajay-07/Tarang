'use client';

import React, { useState, useRef, useEffect } from 'react';
import { apiRequest } from '@/services/api';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui';

interface CreateWaveProps {
  onWaveCreated: () => void;
  circleId?: string;
}

export const CreateWave: React.FC<CreateWaveProps> = ({ onWaveCreated, circleId }) => {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const [content, setContent] = useState('');
  const [mediaUrl, setMediaUrl] = useState('');
  const [mediaType, setMediaType] = useState<'image' | 'video' | ''>('');
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');

  // Autocomplete Mentions states
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestionList, setSuggestionList] = useState<any[]>([]);
  const [suggestionIndex, setSuggestionIndex] = useState(0);
  const [mentionTriggerIndex, setMentionTriggerIndex] = useState(-1);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setUploadError('');
    
    if (file.type.startsWith('image/')) {
      setMediaType('image');
    } else if (file.type.startsWith('video/')) {
      setMediaType('video');
    } else {
      setUploadError('Unsupported file type. Please upload an image or video.');
      setUploading(false);
      return;
    }

    const formData = new FormData();
    formData.append('file', file);

    try {
      const res = await apiRequest('/media/upload', {
        method: 'POST',
        body: formData,
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData?.error?.message || 'Upload failed');
      }

      const data = await res.json();
      setMediaUrl(data.url);
    } catch (err: any) {
      console.error(err);
      setUploadError(err.message || 'Failed to upload media. Please try again.');
      setMediaUrl('');
      setMediaType('');
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveMedia = () => {
    setMediaUrl('');
    setMediaType('');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim() && !mediaUrl) return;

    setLoading(true);
    try {
      const res = await apiRequest('/waves', {
        method: 'POST',
        body: JSON.stringify({
          content,
          media_url: mediaUrl || null,
          media_type: mediaUrl ? (mediaType || 'image') : null,
          circle_id: circleId || null,
        })
      });

      if (res.ok) {
        setContent('');
        setMediaUrl('');
        setMediaType('');
        if (fileInputRef.current) {
          fileInputRef.current.value = '';
        }
        onWaveCreated();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleTextareaChange = async (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    setContent(val);

    const selectionStart = e.target.selectionStart || 0;
    const textBeforeCursor = val.slice(0, selectionStart);
    
    // Look for last index of '@' before cursor
    const lastAtIdx = textBeforeCursor.lastIndexOf('@');
    if (lastAtIdx !== -1) {
      // Ensure it is preceded by whitespace or is at the start
      const charBeforeAt = lastAtIdx > 0 ? textBeforeCursor[lastAtIdx - 1] : ' ';
      if (/\s/.test(charBeforeAt)) {
        const queryTerm = textBeforeCursor.slice(lastAtIdx + 1);
        // Only trigger query if there's no space in the term
        if (!/\s/.test(queryTerm)) {
          setMentionTriggerIndex(lastAtIdx);
          setShowSuggestions(true);
          
          try {
            const res = await apiRequest(`/explore?q=${encodeURIComponent(queryTerm || 'a')}&kind=people&limit=5`);
            if (res.ok) {
              const data = await res.json();
              setSuggestionList(data.people || []);
              setSuggestionIndex(0);
            }
          } catch (err) {
            console.error(err);
          }
          return;
        }
      }
    }
    
    setShowSuggestions(false);
    setSuggestionList([]);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (!showSuggestions || suggestionList.length === 0) return;
    
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSuggestionIndex((prev) => (prev + 1) % suggestionList.length);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSuggestionIndex((prev) => (prev - 1 + suggestionList.length) % suggestionList.length);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      selectSuggestion(suggestionList[suggestionIndex]);
    } else if (e.key === 'Escape') {
      e.preventDefault();
      setShowSuggestions(false);
    }
  };

  const selectSuggestion = (selectedUser: any) => {
    if (!textareaRef.current) return;
    const val = content;
    const cursor = textareaRef.current.selectionStart || 0;
    
    const textBeforeAt = val.slice(0, mentionTriggerIndex);
    const textAfterCursor = val.slice(cursor);
    
    const newContent = `${textBeforeAt}@${selectedUser.username} ${textAfterCursor}`;
    setContent(newContent);
    setShowSuggestions(false);
    setSuggestionList([]);
    
    // Focus back on textarea
    textareaRef.current.focus();
  };

  if (!user) return null;

  return (
    <div className="rounded-card border border-card-border bg-card-bg p-5 shadow-sm space-y-4 relative">
      <form onSubmit={handleSubmit} className="space-y-3 relative">
        <div className="flex gap-4 items-start relative">
          <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white font-bold shrink-0 shadow-sm select-none">
            {user.username[0].toUpperCase()}
          </div>
          <div className="flex-1 relative">
            <textarea
              ref={textareaRef}
              value={content}
              onChange={handleTextareaChange}
              onKeyDown={handleKeyDown}
              placeholder="What's your next wave?"
              rows={3}
              maxLength={280}
              className="w-full resize-none bg-transparent text-sm outline-none placeholder-text-muted border-none focus:ring-0 text-text-primary leading-relaxed"
              disabled={loading}
            />

            {/* Floating Autocomplete Suggestions Box */}
            {showSuggestions && suggestionList.length > 0 && (
              <div className="absolute left-0 top-full mt-1.5 w-60 rounded-dropdown border border-card-border bg-card-bg shadow-lg z-50 overflow-hidden divide-y divide-card-border select-none animate-in fade-in slide-in-from-top-1 duration-150">
                {suggestionList.map((item, idx) => (
                  <div
                    key={item.id}
                    onClick={() => selectSuggestion(item)}
                    className={`flex items-center gap-2.5 px-3 py-2 cursor-pointer transition-colors text-left ${
                      idx === suggestionIndex
                        ? 'bg-primary/10 text-primary'
                        : 'hover:bg-card-border/20 text-text-primary'
                    }`}
                  >
                    <div className="h-7 w-7 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-[10px] font-bold overflow-hidden shrink-0">
                      {item.avatar_url ? (
                        <img src={item.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                      ) : (
                        item.username[0].toUpperCase()
                      )}
                    </div>
                    <div className="truncate">
                      <p className="text-xs font-bold leading-none truncate">{item.full_name || item.username}</p>
                      <p className="text-[9px] text-text-muted mt-0.5 font-semibold">@{item.username}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Media Preview Box */}
        {(uploading || mediaUrl || uploadError) && (
          <div className="relative p-3 bg-background rounded-xl border border-card-border">
            {uploading && (
              <div className="flex items-center gap-2 text-xs text-text-muted font-bold animate-pulse">
                <svg className="animate-spin h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>Uploading attachment to secure cloud...</span>
              </div>
            )}
            
            {uploadError && (
              <p className="text-xs text-danger font-bold">{uploadError}</p>
            )}

            {!uploading && mediaUrl && (
              <div className="relative group max-w-xs rounded-xl overflow-hidden shadow-sm">
                {mediaType === 'video' ? (
                  <video src={mediaUrl} controls className="max-h-48 object-cover rounded-xl" />
                ) : (
                  <img src={mediaUrl} alt="Attached Wave Asset" className="max-h-48 object-cover rounded-xl" />
                )}
                <button
                  type="button"
                  onClick={handleRemoveMedia}
                  className="absolute top-2 right-2 bg-black/60 hover:bg-black/80 text-white rounded-full p-1.5 text-xs transition-colors font-bold"
                  title="Remove asset"
                >
                  ✕
                </button>
              </div>
            )}
          </div>
        )}

        {/* Hidden File Input */}
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFileChange}
          accept="image/jpeg,image/png,image/webp,video/mp4,video/webm"
          className="hidden"
          disabled={loading || uploading}
        />

        <div className="flex justify-between items-center pt-2 border-t border-card-border">
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="p-2 text-text-secondary hover:text-primary transition-colors text-lg"
              title="Add attachment"
              disabled={loading || uploading}
            >
              🖼️
            </button>
            <span className="self-center text-xs text-text-muted font-bold">
              {content.length}/280
            </span>
          </div>

          <Button
            type="submit"
            disabled={loading || uploading || (!content.trim() && !mediaUrl)}
            className="rounded-full px-6 py-2 text-xs font-bold"
          >
            {loading ? 'Releasing...' : 'Release Wave'}
          </Button>
        </div>
      </form>
    </div>
  );
};
