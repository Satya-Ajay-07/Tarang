'use client';

import React, { useState, useRef } from 'react';
import { apiRequest } from '@/services/api';
import { useAuth } from '@/context/AuthContext';

interface CreateWaveProps {
  onWaveCreated: () => void;
  circleId?: string;
}

export const CreateWave: React.FC<CreateWaveProps> = ({ onWaveCreated, circleId }) => {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [content, setContent] = useState('');
  const [mediaUrl, setMediaUrl] = useState('');
  const [mediaType, setMediaType] = useState<'image' | 'video' | ''>('');
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setUploadError('');
    
    // Auto-detect type
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
      // Direct call using fetch to handle FormData properly (apiRequest handles Content-Type mapping)
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

  if (!user) return null;

  return (
    <div className="rounded-3xl border border-card-border bg-card-bg p-5 shadow-[0_2px_8px_rgba(0,0,0,0.04)] space-y-4">
      <form onSubmit={handleSubmit} className="space-y-3">
        <div className="flex gap-4 items-start">
          <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white font-bold shrink-0">
            {user.username[0].toUpperCase()}
          </div>
          <div className="flex-1">
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="What's your next wave?"
              rows={3}
              maxLength={280}
              className="w-full resize-none bg-transparent text-sm outline-none placeholder-slate-400 border-none focus:ring-0"
              disabled={loading}
            />
          </div>
        </div>

        {/* Media Preview Box */}
        {(uploading || mediaUrl || uploadError) && (
          <div className="relative p-3 bg-background rounded-2xl border border-card-border">
            {uploading && (
              <div className="flex items-center gap-2 text-xs text-slate-500 font-medium">
                <svg className="animate-spin h-4 w-4 text-aqua" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>Uploading attachment to secure cloud...</span>
              </div>
            )}
            
            {uploadError && (
              <p className="text-xs text-red-500 font-medium">{uploadError}</p>
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
                  className="absolute top-2 right-2 bg-black/60 hover:bg-black/80 text-white rounded-full p-1.5 text-xs transition-colors"
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

        <div className="flex justify-between items-center pt-2 border-t border-slate-100 dark:border-slate-800/40">
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="p-2 text-slate-400 hover:text-aqua transition-colors text-lg"
              title="Add attachment"
              disabled={loading || uploading}
            >
              🖼️
            </button>
            <span className="self-center text-xs text-slate-400 font-bold">
              {content.length}/280
            </span>
          </div>

          <button
            type="submit"
            disabled={loading || uploading || (!content.trim() && !mediaUrl)}
            className="rounded-full bg-gradient-to-r from-ocean to-aqua px-6 py-2 text-xs font-bold text-white shadow-md shadow-aqua/10 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
          >
            {loading ? 'Releasing...' : 'Release Wave'}
          </button>
        </div>
      </form>
    </div>
  );
};

