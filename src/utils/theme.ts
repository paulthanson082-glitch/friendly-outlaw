/**
 * Theme maps logical color names to CSS color values.
 * The companion sprite uses these keys for `color` props on Text/Box nodes;
 * ink.tsx resolves them to hex before applying to inline styles.
 */
export interface Theme {
  primary: string
  secondary: string
  accent: string
  inactive: string
  autoAccept: string
  success: string
  permission: string
  warning: string
  [key: string]: string
}

export const defaultTheme: Theme = {
  primary: '#3b82f6',
  secondary: '#6b7280',
  accent: '#f59e0b',
  inactive: '#9ca3af',
  autoAccept: '#22c55e',
  success: '#22c55e',
  permission: '#818cf8',
  warning: '#f59e0b',
}
