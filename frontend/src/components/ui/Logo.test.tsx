import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { Logo } from './Logo';

describe('Logo Component', () => {
  it('renders logo text "Tarang" by default', () => {
    render(<Logo />);
    expect(screen.getByText('Tarang')).toBeDefined();
  });

  it('hides text when showText is false', () => {
    render(<Logo showText={false} />);
    expect(screen.queryByText('Tarang')).toBeNull();
  });
});
