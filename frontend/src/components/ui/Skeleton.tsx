import React from 'react';

/**
 * Skeleton — shared loading primitive.
 *
 * Usage:
 *   <Skeleton variant="circle" width={40} height={40} />
 *   <Skeleton variant="text" width="60%" />
 */

interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'text' | 'rect' | 'circle';
  width?: string | number;
  height?: string | number;
}

export const Skeleton: React.FC<SkeletonProps> = ({
  variant = 'rect',
  width,
  height,
  className = '',
  style,
  ...rest
}) => {
  const variantClass =
    variant === 'circle'
      ? 'rounded-full'
      : variant === 'text'
      ? 'rounded-md h-3.5 w-3/4'
      : 'rounded-xl';

  return (
    <div
      className={[
        'animate-pulse bg-card-border/40 dark:bg-card-border/20 shrink-0',
        variantClass,
        className,
      ].join(' ')}
      style={{
        width,
        height,
        ...style,
      }}
      {...rest}
    />
  );
};

export default Skeleton;
