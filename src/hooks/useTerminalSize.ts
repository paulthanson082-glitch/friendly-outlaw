'use client'

import { useEffect, useState } from 'react'

export interface TerminalSize {
  columns: number
  rows: number
}

/**
 * Returns the viewport width (columns) and height (rows) in pixels,
 * updating on every resize. Defaults to 120×40 during SSR.
 */
export function useTerminalSize(): TerminalSize {
  const [size, setSize] = useState<TerminalSize>(() => ({
    columns: typeof window !== 'undefined' ? window.innerWidth : 120,
    rows: typeof window !== 'undefined' ? window.innerHeight : 40,
  }))

  useEffect(() => {
    const handleResize = () =>
      setSize({ columns: window.innerWidth, rows: window.innerHeight })
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  return size
}
