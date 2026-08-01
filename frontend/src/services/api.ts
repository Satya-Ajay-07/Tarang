const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

let accessToken: string | null = null;

export const setAccessToken = (token: string | null) => {
  accessToken = token;
};

export const getAccessToken = () => accessToken;

interface RequestOptions extends RequestInit {
  skipAuth?: boolean;
}

export async function apiRequest(path: string, options: RequestOptions = {}) {
  const headers = new Headers(options.headers || {});
  
  if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  if (accessToken && !options.skipAuth) {
    headers.set('Authorization', `Bearer ${accessToken}`);
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
    credentials: 'include',
  });

  if (response.status === 401 && !options.skipAuth) {
    // Attempt token refresh
    try {
      const refreshSuccess = await attemptTokenRefresh();
      if (refreshSuccess) {
        // Retry initial request with new token
        headers.set('Authorization', `Bearer ${accessToken}`);
        return await fetch(`${API_URL}${path}`, {
          ...options,
          headers,
          credentials: 'include',
        });
      }
    } catch (err) {
      console.error("Token refresh failed", err);
    }
  }

  return response;
}

async function attemptTokenRefresh(): Promise<boolean> {
  try {
    const res = await fetch(`${API_URL}/auth/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
    });

    if (res.ok) {
      const data = await res.json();
      setAccessToken(data.access_token);
      return true;
    }
  } catch (err) {
    console.error(err);
  }
  
  setAccessToken(null);
  return false;
}
