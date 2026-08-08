# Tarang Web vs. Mobile Feature Parity Matrix

This document provides a comparative analysis of features, routes, and implementation details between the Tarang Web Application (Next.js) and the Tarang Flutter Mobile Application.

| Web Feature | Web Route | Flutter Screen | Existing Status | Required Work |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication** | `/login`, `/signup`, `/forgot-password`, `/reset-password`, `/verify-email` | `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen`, `VerifyEmailScreen` | **100% Implemented** | None. Visual alignment matching Web style completed. |
| **Home Stream (Ocean)** | `/ocean` | `HomeScreen` (Home Feed Tab) | **100% Implemented** | None. Infinite scroll pagination matching Web streams completed. |
| **Compose Wave** | Composer Modal | `ComposeScreen` (Full screen) | **100% Implemented** | None. Character count controls (280 limit) and modal exit dialog completed. |
| **Replies** | Direct comments under Wave | Wave Detail / Comment thread (Inline) | **100% Implemented** | None. Threaded reply hierarchies completed. |
| **Spreads** | Repost / Quote Spread | Quote compose modal / quick spread option | **100% Implemented** | None. Immediate spreads and repost configurations completed. |
| **Bookmarks** | `/saved` | `BookmarksScreen` | **100% Implemented** | None. Saved state toggling matching Web completed. |
| **Explore** | `/discover` | `ExploreScreen` | **100% Implemented** | None. Search categories and tag filtering completed. |
| **Trending Topics** | `/trending` | `ExploreScreen` (Trending Tab) | **100% Implemented** | None. Categorized hashtags (`Now`, `Rising`, `Weekly`) completed. |
| **Notifications** | `/alerts` | `NotificationScreen` | **100% Implemented** | None. Tap-to-navigate for all alert types completed. |
| **Achievements** | Profile achievements tab | `ProfileScreen` (Achievements Tab) | **100% Implemented** | None. Earned and locked badges with details modal completed. |
| **Location Tags** | Location tagging on Compose | `ComposeScreen` location tags & `WaveCard` | **100% Implemented** | None. City/state/country selection and settings privacy toggle completed. |
| **Messages (DMs)** | `/messages` | `ConversationListScreen`, `ChatScreen` | **100% Implemented** | None. WebSocket message syncing, typing indicators, and read ticks completed. |
| **Profile** | `/you/[username]` | `ProfileScreen` | **100% Implemented** | None. Cover photos, bio, details, riding stats, and tab feeds completed. |
| **Followers / Following** | Mutuals count tabs | `FollowersScreen` | **100% Implemented** | None. Follow lists and social graph toggle actions completed. |
| **Search** | `/discover?q=...` | `ExploreScreen` (Search tab) | **100% Implemented** | None. Category filtering (All, People, Waves) completed. |
| **Settings** | `/settings` | `SettingsScreen` | **100% Implemented** | None. Deactivation, deletion, cache clearing, and location privacy completed. |
| **Theme Mode** | Theme provider switch | Theme provider / Settings toggle | **100% Implemented** | None. System preference, light, and dark modes completed. |
| **Mentions & Hashtags** | Clickable links in content | RichText parser / Click handlers | **100% Implemented** | None. Clicking `@` and `#` routes to profiles/hashtags completed. |
| **Media Attachments** | Custom image selectors | Image picker attachment placeholder | **100% Implemented** | None. Multipart uploads to `/media/upload` completed. |
