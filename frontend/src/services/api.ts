const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

let accessToken: string | null = null;
let refreshToken: string | null =
    typeof window !== "undefined"
        ? localStorage.getItem("refresh_token")
        : null;

export const setRefreshToken = (token: string | null) => {
    refreshToken = token;
};

export const getRefreshToken = () => refreshToken;  
export const setAccessToken = (token: string | null) => {
  accessToken = token;
};

export const getAccessToken = () => accessToken;

interface RequestOptions extends RequestInit {
  skipAuth?: boolean;
}

export async function apiRequest(
  path: string,
  options: RequestOptions = {}
): Promise<Response> {
  const headers = new Headers(options.headers || {});

  if (!headers.has("Content-Type") && !(options.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }

  // Attach access token
  if (accessToken && !options.skipAuth) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  console.log("==================================");
  console.log("API:", `${API_URL}${path}`);
  console.log("Access Token:", accessToken ? "Present" : "NULL");
  console.log("Skip Auth:", options.skipAuth);
  console.log("==================================");

  let response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
    credentials: "include",
  });

  // Access token expired
  if (response.status === 401 && !options.skipAuth) {
    console.warn("401 received. Attempting refresh...");

    const refreshed = await attemptTokenRefresh();

    if (refreshed && accessToken) {
      headers.set("Authorization", `Bearer ${accessToken}`);

      response = await fetch(`${API_URL}${path}`, {
        ...options,
        headers,
        credentials: "include",
      });
    }
  }

  return response;
}

async function attemptTokenRefresh() {
    if (!refreshToken)
        return false;

    const res = await fetch(
        `${API_URL}/auth/refresh`,
        {
            method: "POST",
            headers: {
                Authorization: `Bearer ${refreshToken}`,
                "Content-Type":"application/json"
            }
        }
    );

    if (!res.ok)
        return false;

    const data = await res.json();

    setAccessToken(data.access_token);
    setRefreshToken(data.refresh_token);

    return true;
}