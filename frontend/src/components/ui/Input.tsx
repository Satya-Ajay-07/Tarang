'use client';

import React, { forwardRef, InputHTMLAttributes } from 'react';

/**
 * Input — shared UI primitive.
 *
 * Usage:
 *   <Input label="Username" error={errors.username} {...register('username')} />
 */

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, hint, leftIcon, rightIcon, className = '', id, disabled, ...rest }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className="flex flex-col gap-1.5 w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="text-xs font-bold text-text-secondary uppercase tracking-wider select-none"
          >
            {label}
          </label>
        )}

        <div className="relative flex items-center w-full">
          {leftIcon && (
            <span className="absolute left-3.5 text-text-muted pointer-events-none transition-colors">
              {leftIcon}
            </span>
          )}

          <input
            ref={ref}
            id={inputId}
            disabled={disabled}
            className={[
              'w-full bg-surface/40 border rounded-input text-sm text-text-primary placeholder-text-muted',
              'px-3.5 py-3',
              'transition-all duration-200',
              'focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary focus:bg-surface/80',
              'disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-card-border/10',
              leftIcon ? 'pl-10' : '',
              rightIcon ? 'pr-10' : '',
              error
                ? 'border-danger/60 focus:ring-danger/20 focus:border-danger bg-danger/5'
                : 'border-card-border hover:border-text-secondary/30',
              className,
            ].join(' ')}
            {...rest}
          />

          {rightIcon && (
            <span className="absolute right-3.5 text-text-muted">
              {rightIcon}
            </span>
          )}
        </div>

        {hint && !error && (
          <p className="text-xs text-text-muted">{hint}</p>
        )}
        {error && (
          <p className="text-xs font-medium text-danger" role="alert">
            {error}
          </p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';

export default Input;
