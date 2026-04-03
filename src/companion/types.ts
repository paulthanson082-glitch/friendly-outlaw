// Companion types for the AI Town companion sprite system

// ─── Rarity ──────────────────────────────────────────────────────────────────

export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'

/** Ordered from most common to rarest — used by the roll loop. */
export const RARITIES: readonly Rarity[] = [
  'common',
  'uncommon',
  'rare',
  'epic',
  'legendary',
]

export const RARITY_WEIGHTS: Record<Rarity, number> = {
  common: 60,
  uncommon: 25,
  rare: 10,
  epic: 4,
  legendary: 1,
}

/** Maps rarity tiers to display colors */
export const RARITY_COLORS: Record<Rarity, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#f59e0b',
}

// ─── Species / cosmetics ──────────────────────────────────────────────────────

export const SPECIES = ['cat', 'dog', 'bunny', 'fox', 'bear'] as const
export type Species = (typeof SPECIES)[number]

/** Eye characters embedded in sprite art; replacement target during blink. */
export const EYES = ['o', '.', '0', '^', '*', '@'] as const
export type Eye = (typeof EYES)[number]

/** Hat cosmetics — 'none' is the common fallback. */
export const HATS = [
  'none',
  'cap',
  'crown',
  'tophat',
  'beanie',
  'bucket',
] as const
export type Hat = (typeof HATS)[number]

// ─── Stats ───────────────────────────────────────────────────────────────────

export const STAT_NAMES = ['wit', 'luck', 'charm', 'speed', 'grit'] as const
export type StatName = (typeof STAT_NAMES)[number]

// ─── Companion ───────────────────────────────────────────────────────────────

/**
 * Deterministic, re-rolled bones — never persisted to disk.
 * Any change to SPECIES/EYES/etc. regenerates them from the seed.
 */
export interface CompanionBones {
  rarity: Rarity
  species: string
  eye: string
  hat: string
  shiny: boolean
  stats: Record<StatName, number>
}

/**
 * Full companion: bones merged with the persisted "soul" (name, etc.).
 * Soul fields come from config.companion; bones always win on conflict.
 */
export interface Companion extends CompanionBones {
  name: string
}
