export interface User {
  id: string;
  email: string;
  username: string;
  full_name?: string;
  avatar_url?: string;
  cover_url?: string;
  bio?: string;
  location?: string;
  website?: string;
  twitter_url?: string;
  github_url?: string;
  pinned_wave_id?: string;
  created_at: string;
  role: string;
}

export interface Token {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export interface WaveAlert {
  id: string;
  recipient_id: string;
  sender?: User;
  wave_id?: string;
  type: 'ripple' | 'join' | 'spread' | 'follow';
  content?: string;
  is_read: boolean;
  created_at: string;
}
