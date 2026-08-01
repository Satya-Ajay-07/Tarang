import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Match pages that require user login
const protectedPaths = [
  '/ocean',
  '/you',
  '/alerts',
  '/messages',
  '/circles',
  '/discover'
];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Check if target pathname requires authentication
  const isProtected = protectedPaths.some(path => pathname.startsWith(path));
  
  if (isProtected) {
    // Read the HttpOnly refresh token cookie
    const refreshToken = request.cookies.get('refresh_token');
    
    if (!refreshToken) {
      // Redirect to login page if unauthorized
      const url = request.nextUrl.clone();
      url.pathname = '/login';
      url.searchParams.set('redirect', pathname);
      return NextResponse.redirect(url);
    }
  }

  // Allow login/signup page visits to bypass if already authenticated
  if (pathname === '/login' || pathname === '/signup') {
    const refreshToken = request.cookies.get('refresh_token');
    if (refreshToken) {
      const url = request.nextUrl.clone();
      url.pathname = '/ocean';
      return NextResponse.redirect(url);
    }
  }

  return NextResponse.next();
}

export const config = {
  // Run middleware on all paths except static assets, favicon, etc.
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|images|api).*)',
  ],
};
