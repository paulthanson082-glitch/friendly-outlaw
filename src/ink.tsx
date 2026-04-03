'use client'

/**
 * Minimal web-compatible re-implementation of the Ink terminal UI primitives
 * (Box and Text). Uses inline CSS so the companion sprite renders correctly
 * in a browser without any extra dependencies.
 */

import React, { type CSSProperties } from 'react'

// ─── Box ─────────────────────────────────────────────────────────────────────

export interface BoxProps {
  flexDirection?: 'row' | 'column'
  alignItems?: 'center' | 'flex-start' | 'flex-end'
  alignSelf?: 'center' | 'flex-start' | 'flex-end' | 'auto'
  justifyContent?: 'center' | 'flex-start' | 'flex-end' | 'space-between'
  paddingX?: number
  paddingRight?: number
  marginRight?: number
  /** Width in character-width units (1 unit ≈ 1 ch) */
  width?: number
  flexShrink?: number
  borderStyle?: 'round' | 'single'
  borderColor?: string
  children?: React.ReactNode
}

export function Box({
  flexDirection = 'row',
  alignItems,
  alignSelf,
  justifyContent,
  paddingX,
  paddingRight,
  marginRight,
  width,
  flexShrink,
  borderStyle,
  borderColor,
  children,
}: BoxProps): React.ReactElement {
  const style: CSSProperties = {
    display: 'flex',
    flexDirection,
    fontFamily: 'monospace',
    whiteSpace: 'pre',
    lineHeight: 1.2,
    ...(alignItems && { alignItems }),
    ...(alignSelf && { alignSelf }),
    ...(justifyContent && { justifyContent }),
    ...(paddingX !== undefined && { paddingInline: `${paddingX}ch` }),
    ...(paddingRight !== undefined && { paddingRight: `${paddingRight}ch` }),
    ...(marginRight !== undefined && { marginRight: `${marginRight}ch` }),
    ...(width !== undefined && { width: `${width}ch` }),
    ...(flexShrink !== undefined && { flexShrink }),
    ...(borderStyle && {
      border: `1px solid ${borderColor ?? 'currentColor'}`,
      borderRadius: borderStyle === 'round' ? '4px' : '0',
      padding: '2px 4px',
    }),
  }
  return <div style={style}>{children}</div>
}

// ─── Text ─────────────────────────────────────────────────────────────────────

export interface TextProps {
  /** Named theme key or any CSS color value */
  color?: string
  bold?: boolean
  italic?: boolean
  /** Reduces opacity to signal a secondary/inactive state */
  dimColor?: boolean
  /** Inverts foreground/background using the provided color */
  inverse?: boolean
  children?: React.ReactNode
}

export function Text({
  color,
  bold,
  italic,
  dimColor,
  inverse,
  children,
}: TextProps): React.ReactElement {
  const style: CSSProperties = {
    fontFamily: 'monospace',
    whiteSpace: 'pre',
    ...(color && !inverse && { color }),
    ...(bold && { fontWeight: 'bold' }),
    ...(italic && { fontStyle: 'italic' }),
    ...(dimColor && { opacity: 0.4 }),
    ...(inverse && {
      backgroundColor: color ?? 'currentColor',
      color: '#000',
    }),
  }
  return <span style={style}>{children}</span>
}
