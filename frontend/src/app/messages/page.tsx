'use client';

import React, { useState, useEffect, useRef, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest, getAccessToken } from '@/services/api';
import { useAuth } from '@/context/AuthContext';
import { formatDistanceToNow } from 'date-fns';
import { Avatar } from '@/components/ui';

// ─── Types ────────────────────────────────────────────────────────────────────

interface Conversation {
  partner_id: string;
  username: string;
  full_name: string | null;
  avatar_url: string | null;
  last_message: string;
  last_message_time: string;
  unread_count: number;
  is_online: boolean;
}

interface ChatMessage {
  id: string;
  sender_id: string;
  recipient_id: string;
  content: string | null;
  media_url: string | null;
  created_at: string;
  is_read: boolean;
}

// ─── Chat Window ──────────────────────────────────────────────────────────────

interface ChatWindowProps {
  partnerId: string;
  partnerUsername: string;
  partnerFullName: string | null;
  partnerAvatarUrl: string | null;
  isPartnerOnline: boolean;
  currentUserId: string;
  wsRef: React.MutableRefObject<WebSocket | null>;
  onBack: () => void;
  onMessageSent: (content: string) => void;
}

function ChatWindow({
  partnerId,
  partnerUsername,
  partnerFullName,
  partnerAvatarUrl,
  isPartnerOnline,
  currentUserId,
  wsRef,
  onBack,
  onMessageSent,
}: ChatWindowProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [partnerTyping, setPartnerTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const typingTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Load message history & mark messages as read
  useEffect(() => {
    const load = async () => {
      // Mark read
      await apiRequest(`/messages/${partnerId}/read`, { method: 'POST' });
      
      const res = await apiRequest(`/messages/${partnerId}`);
      if (res.ok) {
        setMessages(await res.json());
      }
    };
    load();
  }, [partnerId]);

  // Scroll to bottom on new messages
  useEffect(() => {
    scrollRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, partnerTyping]);

  // Listen for incoming WS events
  useEffect(() => {
    if (!wsRef.current) return;
    const handleMessage = (event: MessageEvent) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === 'message' && data.message.sender_id === partnerId) {
          setMessages((prev) => {
            // Avoid duplicate message render if already added locally
            if (prev.some((m) => m.id === data.message.id)) return prev;
            return [...prev, data.message];
          });
          setPartnerTyping(false);
          // Auto mark read if conversation is active
          apiRequest(`/messages/${partnerId}/read`, { method: 'POST' });
        }
        if (data.type === 'typing' && data.sender_id === partnerId) {
          setPartnerTyping(data.typing);
        }
        if (data.type === 'read_receipt' && data.reader_id === partnerId) {
          setMessages((prev) =>
            prev.map((m) => (m.sender_id === currentUserId ? { ...m, is_read: true } : m))
          );
        }
      } catch (e) {
        console.error(e);
      }
    };
    wsRef.current.addEventListener('message', handleMessage);
    return () => wsRef.current?.removeEventListener('message', handleMessage);
  }, [partnerId, wsRef, currentUserId]);

  const sendTypingSignal = (typing: boolean) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'typing', recipient_id: partnerId, typing }));
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput(e.target.value);
    if (!isTyping) {
      setIsTyping(true);
      sendTypingSignal(true);
    }
    if (typingTimerRef.current) clearTimeout(typingTimerRef.current);
    typingTimerRef.current = setTimeout(() => {
      setIsTyping(false);
      sendTypingSignal(false);
    }, 1500);
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    const content = input.trim();
    setInput('');
    sendTypingSignal(false);

    const res = await apiRequest('/messages', {
      method: 'POST',
      body: JSON.stringify({ recipient_id: partnerId, content }),
    });
    if (res.ok) {
      const msg = await res.json();
      setMessages((prev) => [...prev, msg]);
      onMessageSent(content);
    }
  };

  return (
    <div className="flex flex-col h-full bg-tarang-bg-light dark:bg-tarang-bg-dark">
      {/* Chat header */}
      <div className="flex items-center gap-3 border-b border-card-border bg-card-bg/70 px-5 py-4 backdrop-blur shadow-sm select-none">
        <button
          onClick={onBack}
          className="md:hidden p-1.5 rounded-full hover:bg-card-border/50 text-text-secondary transition-colors"
          title="Back to list"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        <Avatar
          username={partnerUsername}
          avatar_url={partnerAvatarUrl}
          is_online={isPartnerOnline}
          size="md"
        />
        <div>
          <h3 className="text-sm font-black leading-none text-text-primary">
            {partnerFullName || partnerUsername}
          </h3>
          <span className={`text-[10px] font-bold ${isPartnerOnline ? 'text-green-500' : 'text-text-muted'}`}>
            {isPartnerOnline ? '● Online' : 'Offline'}
          </span>
        </div>
      </div>

      {/* Messages stream */}
      <div className="flex-1 overflow-y-auto p-5 space-y-3">
        {messages.length === 0 && (
          <p className="text-center text-xs text-text-muted pt-8 font-semibold">
            Start a wave — say hello to @{partnerUsername}
          </p>
        )}
        {messages.map((msg) => {
          const isMine = msg.sender_id === currentUserId;
          return (
            <div key={msg.id} className={`flex ${isMine ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[70%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed shadow-sm font-medium ${
                  isMine
                    ? 'rounded-br-md bg-gradient-to-br from-ocean to-aqua text-white'
                    : 'rounded-bl-md bg-card-bg text-text-primary border border-card-border'
                }`}
              >
                <p className="break-words">{msg.content}</p>
                <span
                  className={`block mt-1 text-[9px] font-bold ${
                    isMine ? 'text-white/60 text-right' : 'text-text-muted'
                  }`}
                >
                  {formatDistanceToNow(new Date(msg.created_at + (msg.created_at.endsWith('Z') ? '' : 'Z')), { addSuffix: true })}
                  {isMine && (msg.is_read ? ' · Read' : ' · Sent')}
                </span>
              </div>
            </div>
          );
        })}

        {/* Typing indicator */}
        {partnerTyping && (
          <div className="flex items-center gap-2 text-[10px] text-text-muted font-bold select-none">
            <div className="flex gap-1">
              <span className="h-2 w-2 rounded-full bg-primary/30 animate-bounce" style={{ animationDelay: '0ms' }} />
              <span className="h-2 w-2 rounded-full bg-primary/30 animate-bounce" style={{ animationDelay: '150ms' }} />
              <span className="h-2 w-2 rounded-full bg-primary/30 animate-bounce" style={{ animationDelay: '300ms' }} />
            </div>
            <span>@{partnerUsername} is typing…</span>
          </div>
        )}
        <div ref={scrollRef} />
      </div>

      {/* Input bar */}
      <form
        onSubmit={handleSend}
        className="flex items-center gap-3 border-t border-card-border bg-card-bg/60 px-5 py-4 backdrop-blur"
      >
        <input
          type="text"
          value={input}
          onChange={handleInputChange}
          placeholder="Type a message..."
          className="flex-1 rounded-2xl border border-card-border bg-background px-4 py-2.5 text-xs font-bold outline-none focus:border-aqua text-text-primary placeholder-text-muted"
        />
        <button
          type="submit"
          disabled={!input.trim()}
          className="rounded-2xl bg-gradient-to-r from-ocean to-aqua px-5 py-2.5 text-xs font-bold text-white transition-all hover:scale-[1.02] active:scale-95 disabled:opacity-40"
        >
          Send
        </button>
      </form>
    </div>
  );
}

// ─── Conversations sidebar ────────────────────────────────────────────────────

interface ConversationListProps {
  conversations: Conversation[];
  activeId: string | null;
  onSelect: (c: Conversation) => void;
}

function ConversationList({
  conversations,
  activeId,
  onSelect,
}: ConversationListProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [searching, setSearching] = useState(false);

  // Search users in real time
  useEffect(() => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      return;
    }

    const delayDebounce = setTimeout(async () => {
      setSearching(true);
      try {
        const res = await apiRequest(`/explore?q=${encodeURIComponent(searchQuery)}&kind=people&limit=5`);
        if (res.ok) {
          const data = await res.json();
          setSearchResults(data.people || []);
        }
      } catch (err) {
        console.error(err);
      } finally {
        setSearching(false);
      }
    }, 300);

    return () => clearTimeout(delayDebounce);
  }, [searchQuery]);

  const handleSelectSearchResult = (user: any) => {
    // Check if we already have a conversation with this user
    const existing = conversations.find((c) => c.partner_id === user.id);
    if (existing) {
      onSelect(existing);
    } else {
      // Construct a new temporary conversation object
      onSelect({
        partner_id: user.id,
        username: user.username,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        last_message: '',
        last_message_time: new Date().toISOString(),
        unread_count: 0,
        is_online: false,
      });
    }
    setSearchQuery('');
  };

  return (
    <div className="flex flex-col h-full bg-card-bg/60 select-none">
      {/* Header */}
      <div className="border-b border-card-border px-5 py-4 flex flex-col gap-3">
        <h2 className="text-base font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
          Messages
        </h2>
        {/* Search users */}
        <div className="relative">
          <input
            type="text"
            placeholder="Search users to start chat..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-xl border border-card-border bg-background/50 px-3.5 py-2 text-xs font-bold outline-none focus:border-primary text-text-primary placeholder-text-muted"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-primary text-xs"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* List content */}
      <div className="flex-1 overflow-y-auto p-3 space-y-1">
        {/* Search Results Display */}
        {searchQuery.trim() ? (
          <div className="space-y-1.5">
            <span className="block text-[10px] font-black uppercase tracking-wider text-text-muted px-3 mb-1">
              Search Results
            </span>
            {searching ? (
              <p className="text-center text-[10px] text-text-muted font-bold py-4">Searching...</p>
            ) : searchResults.length === 0 ? (
              <p className="text-center text-[10px] text-text-muted font-bold py-4">No matching users found.</p>
            ) : (
              searchResults.map((user) => (
                <button
                  key={user.id}
                  onClick={() => handleSelectSearchResult(user)}
                  className="w-full flex items-center gap-3 rounded-2xl px-4 py-2.5 text-left hover:bg-primary/5 transition-all"
                >
                  <div className="h-8 w-8 rounded-full bg-gradient-to-tr from-secondary to-primary flex items-center justify-center text-white text-xs font-bold overflow-hidden shrink-0">
                    {user.avatar_url ? (
                      <img src={user.avatar_url} alt="Avatar" className="h-full w-full object-cover" />
                    ) : (
                      user.username[0].toUpperCase()
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-bold text-text-primary truncate">{user.full_name || user.username}</p>
                    <p className="text-[9px] text-text-muted font-bold">@{user.username}</p>
                  </div>
                </button>
              ))
            )}
          </div>
        ) : (
          /* Normal Conversations List */
          <>
            {conversations.length === 0 && (
              <p className="text-center text-xs text-text-muted pt-10 font-bold">No conversations yet.</p>
            )}
            {conversations.map((conv) => (
              <button
                key={conv.partner_id}
                onClick={() => onSelect(conv)}
                className={`w-full flex items-center gap-3 rounded-2xl px-4 py-3 text-left transition-all ${
                  activeId === conv.partner_id
                    ? 'bg-primary/10 border border-primary/20 shadow-sm'
                    : 'hover:bg-primary/5 border border-transparent'
                }`}
              >
                <Avatar
                  username={conv.username}
                  avatar_url={conv.avatar_url}
                  is_online={conv.is_online}
                />
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-baseline">
                    <span className="text-xs font-bold truncate text-text-primary">
                      {conv.full_name || conv.username}
                    </span>
                    <span className="text-[9px] text-text-muted font-bold shrink-0 ml-1">
                      {conv.last_message_time
                        ? formatDistanceToNow(new Date(conv.last_message_time + (conv.last_message_time.endsWith('Z') ? '' : 'Z')), { addSuffix: true })
                        : ''}
                    </span>
                  </div>
                  <div className="flex justify-between items-center mt-0.5">
                    <p className="text-[10px] text-text-secondary truncate">{conv.last_message || 'Start typing...'}</p>
                    {conv.unread_count > 0 && (
                      <span className="ml-2 rounded-full bg-aqua px-1.5 py-0.5 text-[9px] font-black text-white shrink-0 shadow-sm shadow-aqua/20">
                        {conv.unread_count}
                      </span>
                    )}
                  </div>
                </div>
              </button>
            ))}
          </>
        )}
      </div>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

function MessagesContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const router = useRouter();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [activeConv, setActiveConv] = useState<Conversation | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  // Open WebSocket on mount & auto-reconnect
  useEffect(() => {
    if (!user) return;
    const token = getAccessToken();
    if (!token) return;

    let socket: WebSocket;
    let heartbeat: ReturnType<typeof setInterval>;
    let reconnectTimeout: ReturnType<typeof setTimeout>;

    const connectWS = () => {
      socket = new WebSocket(
        `ws://localhost:8000/api/v1/ws?token=${encodeURIComponent(token)}`
      );

      socket.onopen = () => {
        heartbeat = setInterval(() => {
          if (socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify({ type: 'ping' }));
          }
        }, 20000);
      };

      socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          // When a message is received, update conversations list
          if (data.type === 'message') {
            const senderId = data.message.sender_id;
            const isMine = senderId === user.id;
            const partnerId = isMine ? data.message.recipient_id : senderId;

            setConversations((prev) => {
              const existingIndex = prev.findIndex((c) => c.partner_id === partnerId);
              let updated = [...prev];

              if (existingIndex !== -1) {
                // Update existing
                const existing = updated[existingIndex];
                updated[existingIndex] = {
                  ...existing,
                  last_message: data.message.content || '',
                  last_message_time: data.message.created_at,
                  unread_count:
                    activeConv?.partner_id === partnerId || isMine
                      ? 0
                      : existing.unread_count + 1,
                };
              } else {
                // Fetch partner details & prepend
                loadConversations();
              }

              // Re-sort
              return updated.sort(
                (a, b) =>
                  new Date(b.last_message_time).getTime() - new Date(a.last_message_time).getTime()
              );
            });
          }
        } catch (e) {
          console.error(e);
        }
      };

      socket.onclose = () => {
        clearInterval(heartbeat);
        reconnectTimeout = setTimeout(connectWS, 3000);
      };

      wsRef.current = socket;
    };

    connectWS();

    return () => {
      if (socket) socket.close();
      clearInterval(heartbeat);
      clearTimeout(reconnectTimeout);
    };
  }, [user, activeConv]);

  // Load conversations list
  const loadConversations = async () => {
    const res = await apiRequest('/messages/conversations/list');
    if (res.ok) {
      setConversations(await res.json());
    }
  };

  useEffect(() => {
    loadConversations();
    const interval = setInterval(loadConversations, 10000);
    return () => clearInterval(interval);
  }, []);

  // Handle ?partner= query param (deep-link into a conversation)
  useEffect(() => {
    const partnerId = searchParams.get('partner');
    if (partnerId) {
      const found = conversations.find((c) => c.partner_id === partnerId);
      if (found) {
        setActiveConv(found);
      } else {
        // Retrieve details of the user and prepend a temp conversation
        const fetchUser = async () => {
          const res = await apiRequest(`/users/${partnerId}/riders`); // use as a lookup or lookup via profile endpoint
          const profileRes = await apiRequest(`/users/me`); // placeholder lookup
        };
        fetchUser();
      }
    }
  }, [searchParams, conversations]);

  // When a message is successfully sent, update local conversations list
  const handleMessageSent = (content: string) => {
    if (!activeConv) return;
    setConversations((prev) => {
      const updated = prev.map((c) =>
        c.partner_id === activeConv.partner_id
          ? {
              ...c,
              last_message: content,
              last_message_time: new Date().toISOString(),
              unread_count: 0,
            }
          : c
      );
      // Prepend active
      const active = updated.find((c) => c.partner_id === activeConv.partner_id);
      if (!active) {
        // Prepend new conversation
        const newConv: Conversation = {
          ...activeConv,
          last_message: content,
          last_message_time: new Date().toISOString(),
        };
        return [newConv, ...updated];
      }
      return [active, ...updated.filter((c) => c.partner_id !== activeConv.partner_id)];
    });
  };

  if (!user) return null;

  return (
    <div className="flex h-[calc(100vh-64px)] overflow-hidden rounded-2xl border border-card-border bg-card-bg/25 shadow-sm">
      {/* Conversation list — hidden on mobile when chat is open */}
      <div
        className={`w-full md:w-80 shrink-0 border-r border-card-border ${
          activeConv ? 'hidden md:flex flex-col' : 'flex flex-col'
        }`}
      >
        <ConversationList
          conversations={conversations}
          activeId={activeConv?.partner_id ?? null}
          onSelect={(c) => {
            setActiveConv(c);
            // Clear unread count locally immediately
            setConversations((prev) =>
              prev.map((item) =>
                item.partner_id === c.partner_id ? { ...item, unread_count: 0 } : item
              )
            );
          }}
        />
      </div>

      {/* Chat pane */}
      <div className={`flex-1 flex flex-col ${!activeConv ? 'hidden md:flex' : 'flex'}`}>
        {activeConv ? (
          <ChatWindow
            partnerId={activeConv.partner_id}
            partnerUsername={activeConv.username}
            partnerFullName={activeConv.full_name}
            partnerAvatarUrl={activeConv.avatar_url}
            isPartnerOnline={activeConv.is_online}
            currentUserId={user.id}
            wsRef={wsRef}
            onBack={() => setActiveConv(null)}
            onMessageSent={handleMessageSent}
          />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-8 space-y-3 select-none">
            <span className="text-5xl animate-pulse">💬</span>
            <h3 className="text-sm font-black text-text-secondary">Select a Conversation</h3>
            <p className="text-xs text-text-muted max-w-xs leading-relaxed font-semibold">
              Choose a rider from the list or search for someone to start sending ripples.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

export default function MessagesPage() {
  return (
    <MainAppLayout>
      <Suspense fallback={<div className="flex h-screen items-center justify-center text-xs font-bold text-text-muted">Tuning waves...</div>}>
        <MessagesContent />
      </Suspense>
    </MainAppLayout>
  );
}
