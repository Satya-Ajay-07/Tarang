'use client';

import React from 'react';

/**
 * Avatar — shared UI component.
 *
 * Displays a user avatar with:
 * - Image from avatar_url if available
 * - Gradient initials fallback
 * - Optional online-presence dot
 * - Three preset sizes: sm | md | lg
 *
 * Usage:
 *   <Avatar username="alice" avatar_url={url} is_online size="md" />
 */

interface AvatarProps {
  username: string;
  avatar_url?: string | null;
  is_online?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizeMap: Record<NonNullable<AvatarProps['size']>, string> = {
  sm: 'h-8 w-8 text-xs',
  md: 'h-10 w-10 text-sm',
  lg: 'h-12 w-12 text-base',
  xl: 'h-16 w-16 text-xl',
};

const dotSizeMap: Record<NonNullable<AvatarProps['size']>, string> = {
  sm: 'h-2 w-2',
  md: 'h-2.5 w-2.5',
  lg: 'h-3 w-3',
  xl: 'h-3.5 w-3.5',
};

export function Avatar({
  username,
  avatar_url,
  is_online,
  size = 'md',
  className = '',
}: AvatarProps) {
  const initials = username?.[0]?.toUpperCase() ?? '?';

  return (
    <div className={`relative inline-block shrink-0 ${className}`}>
      <div
        className={`${sizeMap[size]} rounded-full bg-gradient-to-tr from-ocean to-aqua flex items-center justify-center text-white font-bold overflow-hidden`}
      >
        {avatar_url ? (
          <img
            src={avatar_url}
            alt={username}
            className="h-full w-full object-cover"
          />
        ) : (
          initials
        )}
      </div>

      {is_online !== undefined && (
        <span
          className={`absolute bottom-0 right-0 ${dotSizeMap[size]} rounded-full border-2 border-white dark:border-slate-900 ${
            is_online ? 'bg-green-400' : 'bg-slate-300 dark:bg-slate-600'
          }`}
          aria-label={is_online ? 'Online' : 'Offline'}
        />
      )}
    </div>
  );
}

export default Avatar;
