'use client';

import React, { useEffect } from 'react';

/**
 * Toast — shared UI primitive for floating user notifications.
 *
 * Usage:
 *   <Toast message="Wave posted successfully!" type="success" onClose={() => setShowToast(false)} />
 */

export interface ToastProps {
  message: string;
  type?: 'success' | 'error' | 'info';
  onClose: () => void;
  duration?: number;
}

export const Toast: React.FC<ToastProps> = ({
  message,
  type = 'success',
  onClose,
  duration = 3000,
}) => {
  useEffect(() => {
    const timer = setTimeout(onClose, duration);
    return () => clearTimeout(timer);
  }, [onClose, duration]);

  const typeStyles = {
    success: 'bg-success/90 border-success/30 text-white',
    error: 'bg-danger/90 border-danger/30 text-white',
    info: 'bg-secondary/90 border-secondary/30 text-white',
  };

  return (
    <div
      className={[
        'fixed bottom-6 right-6 z-50 flex items-center gap-3 px-5 py-3.5 rounded-full border shadow-lg',
        'backdrop-blur-md animate-in slide-in-from-bottom-5 fade-in-0 duration-300',
        typeStyles[type],
      ].join(' ')}
      role="alert"
    >
      <span className="text-sm font-semibold select-none">
        {type === 'success' ? '🌊' : type === 'error' ? '⚠️' : 'ℹ️'}
      </span>
      <span className="text-xs font-bold leading-none">{message}</span>
      <button
        onClick={onClose}
        className="text-white/60 hover:text-white transition-colors ml-1 focus:outline-none"
        aria-label="Close notification"
      >
        <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  );
};

export default Toast;
