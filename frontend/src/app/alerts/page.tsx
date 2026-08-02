'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { formatDistanceToNow } from 'date-fns';

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAlerts = async () => {
    try {
      const res = await apiRequest('/alerts');
      if (res.ok) {
        const data = await res.json();
        setAlerts(data);
      }
      
      // Mark all as read after fetching
      await apiRequest('/alerts/read', { method: 'POST' });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
  }, []);

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'ripple': return '💙';
      case 'join': return '💬';
      case 'spread': return '🔁';
      case 'follow': return '👤';
      default: return '🌊';
    }
  };

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6">
        <header className="sticky top-0 z-20 border-b border-slate-200/50 bg-white/70 backdrop-blur-md dark:border-slate-850 dark:bg-slate-900/70 p-4">
          <h1 className="text-xl font-black bg-gradient-to-r from-ocean to-aqua bg-clip-text text-transparent">
            Wave Alerts
          </h1>
        </header>

        <div className="p-4 md:p-6 space-y-4">
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-14 w-full rounded-2xl bg-slate-100 dark:bg-slate-900/40 animate-pulse" />
              ))}
            </div>
          ) : alerts.length === 0 ? (
            <div className="text-center py-16 space-y-2">
              <span className="text-4xl">🔔</span>
              <h3 className="text-sm font-bold text-slate-500">The ocean is calm</h3>
              <p className="text-xs text-slate-400">No new ripples or alerts have reached you yet.</p>
            </div>
          ) : (
            <div className="space-y-2">
              {alerts.map((alert) => (
                <div
                  key={alert.id}
                  className={`flex items-start gap-4 p-4 rounded-2xl border transition-all ${
                    alert.is_read
                      ? 'border-slate-100/40 bg-white/40 dark:border-slate-850 dark:bg-slate-900/10'
                      : 'border-aqua/20 bg-aqua/5 dark:border-aqua/10 dark:bg-aqua/5 shadow-sm'
                  }`}
                >
                  <span className="text-xl">{getAlertIcon(alert.type)}</span>
                  <div className="flex-1 space-y-1">
                    <p className="text-sm text-slate-700 dark:text-slate-200">
                      {alert.content}
                    </p>
                    <span className="text-[10px] text-slate-400 block font-medium">
                      {formatDistanceToNow(new Date(alert.created_at), {
                        addSuffix: true,
                      })}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </MainAppLayout>
  );
}
