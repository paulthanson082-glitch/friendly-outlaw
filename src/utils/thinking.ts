/**
 * Rainbow color cycle used by the /buddy teaser animation.
 * Returns a CSS hex color for the given index, cycling through a
 * perceptually-even hue wheel.
 */
const RAINBOW_COLORS = [
  '#f87171', // red
  '#fb923c', // orange
  '#fbbf24', // amber
  '#a3e635', // lime
  '#34d399', // emerald
  '#38bdf8', // sky
  '#818cf8', // indigo
  '#c084fc', // purple
  '#f472b6', // pink
] as const

export function getRainbowColor(index: number): string {
  return RAINBOW_COLORS[((index % RAINBOW_COLORS.length) + RAINBOW_COLORS.length) % RAINBOW_COLORS.length]!
}
