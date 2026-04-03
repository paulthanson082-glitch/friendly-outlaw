// Companion types for the AI Town companion sprite system

export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'

export interface Companion {
  id: string
  name: string
  species: string
  rarity: Rarity
  /** The character used for the companion's eyes in sprite art */
  eye: string
}

/** Maps rarity tiers to display colors */
export const RARITY_COLORS: Record<Rarity, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#f59e0b',
}
