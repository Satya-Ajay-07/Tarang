'use client';

import React, { useState, useEffect, useRef, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
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

// Avatar is now imported from '@/components/ui' above.

// ─── Chat Window ──────────────────────────────────────────────────────────────

function ChatWindow({
  partnerId,
  partnerUsername,
  partnerFullName,
  partnerAvatarUrl,
  isPartnerOnline,
  currentUserId,
  wsRef,
}: {
  partnerId: string;
  partnerUsername: string;
  partnerFullName: string | null;
  partnerAvatarUrl: string | null;
  isPartnerOnline: boolean;
  currentUserId: string;
  wsRef: React.MutableRefObject<WebSocket | null>;
}) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [partnerTyping, setPartnerTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const typingTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Load message history
  useEffect(() => {
    const load = async () => {
      const res = await apiRequest(`/messages/${partnerId}`);
      if (res.ok) {
        const data = await res.json();
        setMessages(data);
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
      const data = JSON.parse(event.data);
      if (data.type === 'message' && data.message.sender_id === partnerId) {
        setMessages((prev) => [...prev, data.message]);
        setPartnerTyping(false);
      }
      if (data.type === 'typing' && data.sender_id === partnerId) {
        setPartnerTyping(data.typing);
      }
    };
    wsRef.current.addEventListener('message', handleMessage);
    return () => wsRef.current?.removeEventListener('message', handleMessage);
  }, [partnerId, wsRef]);

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
    }
  };

  return (
    <div className="flex flex-col h-full">
      {/* Chat header */}
      <div className="flex items-center gap-3 border-b border-slate-100 bg-white/70 px-5 py-4 backdrop-blur dark:border-slate-800/50 dark:bg-slate-900/70">
        <Avatar
          username={partnerUsername}
          avatar_url={partnerAvatarUrl}
          is_online={isPartnerOnline}
          size="md"
        />
        <div>
          <h3 className="text-sm font-bold leading-none">
            {partnerFullName || partnerUsername}
          </h3>
          <span className={`text-xs ${isPartnerOnline ? 'text-green-400' : 'text-slate-400'}`}>
            {isPartnerOnline ? 'Online' : 'Offline'}
          </span>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-5 space-y-3">
        {messages.length === 0 && (
          <p className="text-center text-xs text-slate-400 pt-8">
            Start a wave — say hello to @{partnerUsername}
          </p>
        )}
        {messages.map((msg) => {
          const isMine = msg.sender_id === currentUserId;
          return (
            <div key={msg.id} className={`flex ${isMine ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[70%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed shadow-sm ${
                  isMine
                    ? 'rounded-br-md bg-gradient-to-br from-ocean to-aqua text-white'
                    : 'rounded-bl-md bg-white text-slate-700 dark:bg-slate-800 dark:text-slate-200 border border-slate-100 dark:border-slate-700'
                }`}
              >
                <p>{msg.content}</p>
                <span
                  className={`block mt-1 text-[9px] ${
                    isMine ? 'text-white/60 text-right' : 'text-slate-400'
                  }`}
                >
                  {formatDistanceToNow(new Date(msg.created_at + "Z"), { addSuffix: true })}
                  {isMine && msg.is_read && ' · Read'}
                </span>
              </div>
            </div>
          );
        })}

        {/* Typing indicator */}
        {partnerTyping && (
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <div className="flex gap-1">
              <span className="h-2 w-2 rounded-full bg-slate-300 dark:bg-slate-600 animate-bounce" style={{ animationDelay: '0ms' }} />
              <span className="h-2 w-2 rounded-full bg-slate-300 dark:bg-slate-600 animate-bounce" style={{ animationDelay: '150ms' }} />
              <span className="h-2 w-2 rounded-full bg-slate-300 dark:bg-slate-600 animate-bounce" style={{ animationDelay: '300ms' }} />
            </div>
            <span>@{partnerUsername} is typing…</span>
          </div>
        )}
        <div ref={scrollRef} />
      </div>

      {/* Input bar */}
      <form
        onSubmit={handleSend}
        className="flex items-center gap-3 border-t border-slate-100 bg-white/60 px-5 py-4 backdrop-blur dark:border-slate-800/50 dark:bg-slate-900/60"
      >
        <input
          type="text"
          value={input}
          onChange={handleInputChange}
          placeholder="Send a ripple…"
          className="flex-1 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm outline-none focus:border-aqua dark:border-slate-700 dark:bg-slate-800"
        />
        <button
          type="submit"
          disabled={!input.trim()}
          className="rounded-2xl bg-gradient-to-r from-ocean to-aqua px-5 py-2.5 text-sm font-bold text-white transition-all hover:scale-[1.02] disabled:opacity-40"
        >
          Send
        </button>
      </form>
    </div>
  );
}

// ─── Conversations sidebar ────────────────────────────────────────────────────

function ConversationList({
  conversations,
  activeId,
  onSelect,
}: {
  conversations: Conversation[];
  activeId: string | null;
  onSelect: (c: Conversation) => void;
}) {
  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-slate-100 px-5 py-4 dark:border-slate-800/50">
        <h2 className="text-lg font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
          Messages
        </h2>
      </div>
      <div className="flex-1 overflow-y-auto p-3 space-y-1">
        {conversations.length === 0 && (
          <p className="text-center text-xs text-slate-400 pt-10">No conversations yet.</p>
        )}
        {conversations.map((conv) => (
          <button
            key={conv.partner_id}
            onClick={() => onSelect(conv)}
            className={`w-full flex items-center gap-3 rounded-2xl px-4 py-3 text-left transition-all ${
              activeId === conv.partner_id
                ? 'bg-aqua/10 dark:bg-aqua/5'
                : 'hover:bg-slate-100/50 dark:hover:bg-slate-800/40'
            }`}
          >
            <Avatar
              username={conv.username}
              avatar_url={conv.avatar_url}
              is_online={conv.is_online}
            />
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-baseline">
                <span className="text-xs font-bold truncate">
                  {conv.full_name || conv.username}
                </span>
                <span className="text-[9px] text-slate-400 shrink-0 ml-1">
                  {conv.last_message_time
                    ? formatDistanceToNow(new Date(conv.last_message_time), { addSuffix: true })
                    : ''}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <p className="text-[10px] text-slate-400 truncate">{conv.last_message || ''}</p>
                {conv.unread_count > 0 && (
                  <span className="ml-2 rounded-full bg-aqua px-1.5 py-0.5 text-[9px] font-bold text-white shrink-0">
                    {conv.unread_count}
                  </span>
                )}
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

function MessagesContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [activeConv, setActiveConv] = useState<Conversation | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  // Open WebSocket on mount
  useEffect(() => {
    if (!user) return;
    const token = getAccessToken();
    if (!token) return;

    const ws = new WebSocket(
      `ws://localhost:8000/api/v1/ws?token=${encodeURIComponent(token)}`
    );

    ws.onopen = () => {
      // Start heartbeat ping every 30 s to keep presence alive
      const heartbeat = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'ping' }));
      }, 30000);
      ws.addEventListener('close', () => clearInterval(heartbeat));
    };

    wsRef.current = ws;
    return () => {
      ws.close();
    };
  }, [user]);

  // Load conversations
  useEffect(() => {
    const load = async () => {
      const res = await apiRequest('/messages/conversations/list');
      if (res.ok) setConversations(await res.json());
    };
    load();
    const interval = setInterval(load, 15000);
    return () => clearInterval(interval);
  }, []);

  // Handle ?partner= query param (deep-link into a conversation)
  useEffect(() => {
    const partnerId = searchParams.get('partner');
    if (partnerId && conversations.length > 0) {
      const found = conversations.find((c) => c.partner_id === partnerId);
      if (found) setActiveConv(found);
    }
  }, [searchParams, conversations]);

  if (!user) return null;

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Conversation list — hidden on mobile when chat is open */}
      <div
        className={`w-80 shrink-0 border-r border-slate-100 bg-white/60 backdrop-blur dark:border-slate-800/50 dark:bg-slate-900/50 ${
          activeConv ? 'hidden md:flex flex-col' : 'flex flex-col w-full md:w-80'
        }`}
      >
        <ConversationList
          conversations={conversations}
          activeId={activeConv?.partner_id ?? null}
          onSelect={setActiveConv}
        />
      </div>

      {/* Chat pane */}
      <div className="flex-1 flex flex-col">
        {activeConv ? (
          <ChatWindow
            partnerId={activeConv.partner_id}
            partnerUsername={activeConv.username}
            partnerFullName={activeConv.full_name}
            partnerAvatarUrl={activeConv.avatar_url}
            isPartnerOnline={activeConv.is_online}
            currentUserId={user.id}
            wsRef={wsRef}
          />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-8 space-y-3 select-none">
            <span className="text-5xl">🌊</span>
            <h3 className="text-base font-bold text-slate-500">Select a conversation</h3>
            <p className="text-xs text-slate-400 max-w-xs">
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
      <Suspense fallback={<div className="flex h-screen items-center justify-center text-sm text-slate-400">Loading…</div>}>
        <MessagesContent />
      </Suspense>
    </MainAppLayout>
  );
}
