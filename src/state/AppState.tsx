'use client'

import React, { createContext, useContext, useReducer } from 'react'
import type { AppState } from './AppStateStore.js'

// ─── Defaults ────────────────────────────────────────────────────────────────

const defaultState: AppState = {
  companionReaction: undefined,
  companionPetAt: null,
  footerSelection: null,
}

// ─── Contexts ─────────────────────────────────────────────────────────────────

const AppStateContext = createContext<AppState>(defaultState)
const AppStateSetContext = createContext<
  (updater: (prev: AppState) => AppState) => void
>(() => {})

// ─── Provider ─────────────────────────────────────────────────────────────────

/**
 * Wrap your app (or a subtree) in this provider to make companion state
 * available to all descendants.
 */
export function AppStateProvider({
  children,
}: {
  children: React.ReactNode
}): React.ReactElement {
  const [state, dispatch] = useReducer(
    (prev: AppState, updater: (prev: AppState) => AppState) => updater(prev),
    defaultState,
  )

  return (
    <AppStateContext.Provider value={state}>
      <AppStateSetContext.Provider value={dispatch}>
        {children}
      </AppStateSetContext.Provider>
    </AppStateContext.Provider>
  )
}

// ─── Hooks ───────────────────────────────────────────────────────────────────

/** Read a derived value from app state; re-renders only when the selector result changes. */
export function useAppState<T>(selector: (s: AppState) => T): T {
  return selector(useContext(AppStateContext))
}

/** Returns the state-updater function (stable reference, safe as an effect dep). */
export function useSetAppState(): (
  updater: (prev: AppState) => AppState,
) => void {
  return useContext(AppStateSetContext)
}
