'use client'

import React, { createContext, useCallback, useContext, useState } from 'react'

export interface Notification {
  key: string
  jsx: React.ReactNode
  priority?: 'immediate' | 'normal' | 'low'
  timeoutMs?: number
}

interface NotificationsContextValue {
  notifications: Notification[]
  addNotification: (notification: Notification) => void
  removeNotification: (key: string) => void
}

const NotificationsContext = createContext<NotificationsContextValue | null>(null)

export function NotificationsProvider({
  children,
}: {
  children: React.ReactNode
}): React.ReactElement {
  const [notifications, setNotifications] = useState<Notification[]>([])

  const addNotification = useCallback((notification: Notification): void => {
    setNotifications(prev => {
      // Replace if key already exists
      const idx = prev.findIndex(n => n.key === notification.key)
      if (idx !== -1) {
        const next = [...prev]
        next[idx] = notification
        return next
      }
      if (notification.priority === 'immediate') {
        return [notification, ...prev]
      }
      return [...prev, notification]
    })
  }, [])

  const removeNotification = useCallback((key: string): void => {
    setNotifications(prev => prev.filter(n => n.key !== key))
  }, [])

  return (
    <NotificationsContext.Provider
      value={{ notifications, addNotification, removeNotification }}
    >
      {children}
    </NotificationsContext.Provider>
  )
}

export function useNotifications(): NotificationsContextValue {
  const ctx = useContext(NotificationsContext)
  if (!ctx) {
    throw new Error('useNotifications must be used within NotificationsProvider')
  }
  return ctx
}
