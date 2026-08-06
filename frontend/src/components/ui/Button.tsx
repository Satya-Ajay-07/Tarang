'use client';

import React, { ButtonHTMLAttributes, forwardRef } from 'react';

/**
 * Button — shared UI primitive.
 *
 * Variants:  primary | secondary | ghost | danger
 * Sizes:     sm | md | lg
 *
 * Usage:
 *   <Button variant="primary" size="md" loading={submitting} onClick={handleClick}>
 *     Save Changes
 *   </Button>
 */

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  isIcon?: boolean;
}

const variantStyles: Record<NonNullable<ButtonProps['variant']>, string> = {
  primary:
    'bg-gradient-to-r from-secondary to-primary text-white hover:opacity-90 shadow-md focus-visible:ring-primary',
  secondary:
    'bg-surface/40 text-text-primary border border-card-border hover:bg-surface/80 hover:border-text-secondary/30 focus-visible:ring-primary/40',
  ghost:
    'bg-transparent text-text-secondary hover:bg-card-border/20 hover:text-text-primary focus-visible:ring-primary/20',
  danger:
    'bg-danger/10 text-danger border border-danger/30 hover:bg-danger/20 focus-visible:ring-danger/50',
};

const sizeStyles: Record<NonNullable<ButtonProps['size']>, string> = {
  sm: 'px-3 py-1.5 text-xs font-semibold',
  md: 'px-4 py-2 text-sm font-semibold',
  lg: 'px-6 py-3 text-base font-bold',
};

const iconSizeStyles: Record<NonNullable<ButtonProps['size']>, string> = {
  sm: 'p-1.5 text-xs',
  md: 'p-2.5 text-sm',
  lg: 'p-4 text-base',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      loading = false,
      isIcon = false,
      disabled,
      className = '',
      children,
      ...rest
    },
    ref
  ) => {
    const isDisabled = disabled || loading;

    return (
      <button
        ref={ref}
        disabled={isDisabled}
        className={[
          'inline-flex items-center justify-center gap-2',
          'tracking-tight select-none',
          'transition-all duration-200 active:scale-[0.98]',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-background',
          'disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100',
          isIcon ? 'rounded-full' : 'rounded-btn',
          isIcon ? iconSizeStyles[size] : sizeStyles[size],
          variantStyles[variant],
          className,
        ].join(' ')}
        {...rest}
      >
        {loading && (
          <svg
            className="animate-spin h-4 w-4 shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
            />
          </svg>
        )}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';

export default Button;
