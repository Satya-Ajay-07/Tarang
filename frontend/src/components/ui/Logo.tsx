import React from 'react';

interface LogoProps {
  className?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showText?: boolean;
}

export const Logo: React.FC<LogoProps> = ({ className = '', size = 'md', showText = true }) => {
  const sizeMap = {
    sm: { icon: 'w-6 h-6', text: 'text-lg' },
    md: { icon: 'w-10 h-10', text: 'text-2xl' },
    lg: { icon: 'w-16 h-16', text: 'text-4xl' },
    xl: { icon: 'w-24 h-24', text: 'text-6xl' },
  };

  const { icon: iconClass, text: textClass } = sizeMap[size];

  return (
    <div className={`flex items-center gap-3 select-none ${className}`}>
      {/* Dynamic SVG Wave Logo forming a subtle 'T' */}
      <svg
        className={`${iconClass} text-aqua transition-transform hover:scale-105 duration-500`}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M15 30 C 45 10, 55 50, 85 30"
          stroke="currentColor"
          strokeWidth="10"
          strokeLinecap="round"
        />
        <path
          d="M50 30 C 50 55, 30 75, 50 85"
          stroke="currentColor"
          strokeWidth="10"
          strokeLinecap="round"
        />
      </svg>
      {showText && (
        <span className={`${textClass} font-black tracking-tight bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent`}>
          Tarang
        </span>
      )}
    </div>
  );
};
