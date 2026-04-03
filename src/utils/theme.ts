/**
 * Theme maps logical color names to CSS color values.
 * The companion sprite uses these keys for `color` props on Text nodes.
 */
export interface Theme {
  primary: string
  secondary: string
  accent: string
  inactive: string
  autoAccept: string
  [key: string]: string
}

export const defaultTheme: Theme = {
  primary: '#3b82f6',
  secondary: '#6b7280',
  accent: '#f59e0b',
  inactive: '#9ca3af',
  autoAccept: '#22c55e',
}
