'use client';

import React, { useState, useEffect } from 'react';
import MainAppLayout from '@/layouts/MainAppLayout';
import { apiRequest } from '@/services/api';
import { formatDistanceToNow } from 'date-fns';
import { Skeleton, Card } from '@/components/ui';

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
    switch (type?.toLowerCase()) {
      case 'ripple': return '💙';
      case 'join': return '💬';
      case 'spread': return '🔁';
      case 'follow': return '👤';
      case 'reply': return '✉️';
      case 'mention': return '🏷️';
      case 'poll': return '📊';
      case 'system': return '⚙️';
      default: return '🌊';
    }
  };

  // Group alerts by time periods
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfYesterday = new Date(startOfToday.getTime() - 24 * 60 * 60 * 1000);

  const todayAlerts = alerts.filter(a => new Date(a.created_at) >= startOfToday);
  const yesterdayAlerts = alerts.filter(a => {
    const d = new Date(a.created_at);
    return d >= startOfYesterday && d < startOfToday;
  });
  const earlierAlerts = alerts.filter(a => new Date(a.created_at) < startOfYesterday);

  const renderAlertGroup = (title: string, list: any[]) => {
    if (list.length === 0) return null;
    return (
      <div className="space-y-3">
        <h3 className="text-[10px] font-black uppercase tracking-wider text-text-muted select-none pl-1">
          {title}
        </h3>
        <div className="space-y-2">
          {list.map((alert) => (
            <div
              key={alert.id}
              className={`flex items-start gap-4 p-4 rounded-card border transition-all duration-200 hover:scale-[1.005] ${
                alert.is_read
                  ? 'border-card-border bg-card-bg/40'
                  : 'border-primary/25 bg-primary/5 shadow-sm'
              }`}
            >
              <span className="text-lg leading-none select-none shrink-0">{getAlertIcon(alert.type)}</span>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-text-primary leading-relaxed font-semibold">
                  {alert.content}
                </p>
                <span className="text-[9px] text-text-muted font-bold block mt-1 select-none">
                  {formatDistanceToNow(new Date(alert.created_at), { addSuffix: true })}
                </span>
              </div>
              {!alert.is_read && (
                <span className="h-2 w-2 rounded-full bg-primary shrink-0 mt-1.5 animate-pulse" />
              )}
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <MainAppLayout>
      <div className="flex flex-col min-h-screen bg-transparent pb-20 md:pb-6 font-body">
        {/* Sticky Top Header */}
        <header className="sticky top-16 z-20 flex flex-col border-b border-card-border bg-background/80 backdrop-blur-md p-4 sm:p-5">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-black bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent font-display select-none">
              Wave Alerts
            </h1>
          </div>
        </header>

        {/* Content stream area */}
        <div className="p-4 sm:p-6 space-y-6">
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="rounded-card border border-card-border bg-card-bg/40 p-4 animate-pulse flex items-center gap-3">
                  <Skeleton variant="circle" width={28} height={28} />
                  <div className="space-y-2 flex-1">
                    <Skeleton variant="rect" width="70%" height={12} />
                    <Skeleton variant="rect" width="30%" height={9} />
                  </div>
                </div>
              ))}
            </div>
          ) : alerts.length === 0 ? (
            <div className="text-center py-16 space-y-3.5 border border-dashed border-card-border rounded-card bg-card-bg/25 select-none">
              <div className="text-4xl animate-bounce">🔔</div>
              <h3 className="text-sm font-bold text-text-secondary font-display">The ocean is calm</h3>
              <p className="text-xs text-text-muted max-w-xs mx-auto">
                No new ripples, joins, or follow alerts have reached your timeline yet.
              </p>
            </div>
          ) : (
            <div className="space-y-6 animate-in fade-in duration-200">
              {renderAlertGroup('Today', todayAlerts)}
              {renderAlertGroup('Yesterday', yesterdayAlerts)}
              {renderAlertGroup('Earlier', earlierAlerts)}
            </div>
          )}
        </div>
      </div>
    </MainAppLayout>
  );
}
