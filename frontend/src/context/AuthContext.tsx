'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types';
import { apiRequest, setAccessToken,getAccessToken,setRefreshToken} from '../services/api';
import { useRouter } from 'next/navigation';


interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (usernameOrEmail: string, password: string, rememberMe?: boolean) => Promise<void>;
  register: (email: string, username: string, password: string, fullName: string, country?: string, phoneNumber?: string) => Promise<void>;
  logout: () => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (token: string, newPassword: string) => Promise<void>;
  verifyEmail: (token: string) => Promise<void>;
  resendVerification: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const router = useRouter();

  // On startup, attempt to refresh token to see if user session is active
 useEffect(() => {
  async function checkAuthSession() {
    // If we already have an access token,
    // don't try to refresh immediately.
    if (getAccessToken()) {
      setLoading(false);
      return;
    }

    try {
      const refreshToken = localStorage.getItem("refresh_token");

      if (!refreshToken) {
        setLoading(false);
        return; 
      }

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/auth/refresh`,
        {
          method: "POST",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${refreshToken}`,
          },
        }
    );

     if (response.ok) {
    const data = await response.json();

    setAccessToken(data.access_token);
    setRefreshToken(data.refresh_token);

    const userRes = await apiRequest("/users/me");

    if (!userRes.ok)
        throw new Error("Failed to fetch user");

    const userData = await userRes.json();

    setUser(userData);
}
    } catch (err) {
      console.error("No active session found", err);
    } finally {
      setLoading(false);
    }
  }

  checkAuthSession();
  }, []);
  const login = async (usernameOrEmail: string, password: string, rememberMe = false) => {
    setLoading(true);
    try {
      const res = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username_or_email: usernameOrEmail, password }),
        skipAuth: true
      });

      if (!res.ok) {
        const errorData = await res.json();
        const errorMsg = errorData?.error?.message || 'Login failed';
        if (errorData?.error?.days_remaining !== undefined) {
          const err: any = new Error(`${errorMsg} (Remaining: ${errorData.error.days_remaining} days)`);
          err.days_remaining = errorData.error.days_remaining;
          throw err;
        }
        throw new Error(errorMsg);
      }

      const data = await res.json();

      setAccessToken(data.access_token);
      setRefreshToken(data.refresh_token);   // <-- ADD THIS

      const userRes = await apiRequest('/users/me');

      if (!userRes.ok)
        throw new Error("Failed to fetch user profile");

      const userData = await userRes.json();

      setUser(userData);

      router.push('/ocean');
      if (!userRes.ok) throw new Error("Failed to fetch user profile");
      
      setUser(userData);
      router.push('/ocean');
    } finally {
      setLoading(false);
    }
  };

  const register = async (email: string, username: string, password: string, fullName: string, country?: string, phoneNumber?: string) => {
    setLoading(true);
    try {
      const res = await apiRequest('/auth/register', {
        method: 'POST',
        body: JSON.stringify({ 
          email, 
          username, 
          password, 
          full_name: fullName,
          country,
          phone_number: phoneNumber
        }),
        skipAuth: true
      });

      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData?.error?.message || 'Registration failed');
      }
      
      // Redirect to simulated verification pending screen
      router.push('/verify-email?pending=true');
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    setLoading(true);
    try {
      await apiRequest('/auth/logout', { method: 'POST', skipAuth: true });
    } finally {
      setUser(null);
      setAccessToken(null);
      setRefreshToken(null);

      localStorage.removeItem(
        "refresh_token"
      );
      setLoading(false);
      router.push('/login');
    }
  };

  const forgotPassword = async (email: string) => {
    const res = await apiRequest(`/auth/forgot-password?email=${encodeURIComponent(email)}`, {
      method: 'POST',
      skipAuth: true
    });
    if (!res.ok) {
      const errorData = await res.json();
      throw new Error(errorData?.error?.message || 'Failed to trigger reset');
    }
  };

  const resetPassword = async (token: string, newPassword: string) => {
    const res = await apiRequest(`/auth/reset-password?token=${encodeURIComponent(token)}&new_password=${encodeURIComponent(newPassword)}`, {
      method: 'POST',
      skipAuth: true
    });
    if (!res.ok) {
      const errorData = await res.json();
      throw new Error(errorData?.error?.message || 'Failed to reset password');
    }
  };

  const verifyEmail = async (token: string) => {
    const res = await apiRequest(`/auth/verify-email?token=${encodeURIComponent(token)}`, {
      method: 'POST',
      skipAuth: true
    });
    if (!res.ok) {
      const errorData = await res.json();
      throw new Error(errorData?.error?.message || 'Verification failed');
    }
  };

  const resendVerification = async (email: string) => {
    const res = await apiRequest('/auth/resend-verification', {
      method: 'POST',
      body: JSON.stringify({ email }),
      skipAuth: true
    });
    if (!res.ok) {
      const errorData = await res.json();
      const err: any = new Error(errorData?.error?.message || 'Failed to resend verification email');
      err.code = errorData?.error?.code;
      throw err;
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, forgotPassword, resetPassword, verifyEmail, resendVerification }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
export type { AuthContextType };
