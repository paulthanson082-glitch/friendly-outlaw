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

// ─── Species — exported as const so sprites.ts can use them in switch/Record ──

export const duck = 'duck' as const
export const goose = 'goose' as const
export const blob = 'blob' as const
export const cat = 'cat' as const
export const dragon = 'dragon' as const
export const octopus = 'octopus' as const
export const owl = 'owl' as const
export const penguin = 'penguin' as const
export const turtle = 'turtle' as const
export const snail = 'snail' as const
export const ghost = 'ghost' as const
export const axolotl = 'axolotl' as const
export const capybara = 'capybara' as const
export const cactus = 'cactus' as const
export const robot = 'robot' as const
export const rabbit = 'rabbit' as const
export const mushroom = 'mushroom' as const
export const chonk = 'chonk' as const

export const SPECIES = [
  duck,
  goose,
  blob,
  cat,
  dragon,
  octopus,
  owl,
  penguin,
  turtle,
  snail,
  ghost,
  axolotl,
  capybara,
  cactus,
  robot,
  rabbit,
  mushroom,
  chonk,
] as const
export type Species = (typeof SPECIES)[number]

// ─── Eyes ─────────────────────────────────────────────────────────────────────

/** Characters used as the `{E}` eye placeholder in sprite art. */
export const EYES = ['o', '.', '0', '^', '*', '@'] as const
export type Eye = (typeof EYES)[number]

// ─── Hats ─────────────────────────────────────────────────────────────────────

export const HATS = [
  'none',
  'crown',
  'tophat',
  'propeller',
  'halo',
  'wizard',
  'beanie',
  'tinyduck',
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
  species: Species
  eye: Eye
  hat: Hat
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
