import React from 'react';

/**
 * Card — shared UI primitive.
 *
 * Usage:
 *   <Card elevation="sm" hoverable>
 *     <h4>Title</h4>
 *     <p>Content</p>
 *   </Card>
 */

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  elevation?: 'sm' | 'md' | 'lg';
  hoverable?: boolean;
}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ children, elevation = 'sm', hoverable = true, className = '', ...rest }, ref) => {
    const shadowClass =
      elevation === 'sm'
        ? 'shadow-sm'
        : elevation === 'md'
        ? 'shadow-md'
        : 'shadow-lg';

    return (
      <div
        ref={ref}
        className={[
          'rounded-card border border-card-border bg-card-bg p-5 text-text-primary transition-all duration-200',
          shadowClass,
          hoverable ? 'hover:shadow-md hover:border-text-secondary/20' : '',
          className,
        ].join(' ')}
        {...rest}
      >
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';

export default Card;
