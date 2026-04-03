import type { Companion } from './types.js'

// All rest frames use 'o' as the canonical eye placeholder so that
// renderSprite can substitute companion.eye, and CompanionSprite's blink
// logic (replaceAll(companion.eye, '-')) works on frame 0 without ambiguity.
const SPRITES: Record<string, string[][]> = {
  cat: [
    [' /\\_/\\ ', '( o.o )', ' > ^ < '], // rest   — eyes = o
    [' /\\_/\\ ', '( -.- )', ' > ^ < '], // fidget — eyes closed
    [' /\\_/\\ ', '( ^.^ )', ' >~^~< '], // wiggle — excited
  ],
  dog: [
    [' /^ ^\\ ', '( o.o )', '  /|\\  '], // rest
    [' /^ ^\\ ', '( -.* )', '  /|\\  '], // fidget
    [' /^ ^\\ ', '( ~.~ )', ' \\-|-/ '], // wiggle
  ],
  bunny: [
    ['  (\\/)  ', ' ( o.o )', ' (")_(")', ], // rest
    ['  (\\/)  ', ' ( -.^ )', ' (")_(")', ], // fidget
    ['  (\\/)  ', ' ( ^.^ )', ' (")_(")', ], // wiggle
  ],
  fox: [
    [' /\\ /\\ ', '( o.o )', ' \\_V_/ '], // rest
    [' /\\ /\\ ', '( -.* )', ' \\_V_/ '], // fidget
    [' /\\ /\\ ', '( ^.^ )', ' \\_~_/ '], // wiggle
  ],
  bear: [
    [' (o) (o)', '( o.o  )', ' \\___/  '], // rest
    [' (o) (o)', '( -.o  )', ' \\___/  '], // fidget
    [' (o) (o)', '( ^.^  )', ' \\~_~/  '], // wiggle
  ],
  default: [
    ['  o_o  ', ' (___) ', '  | |  '], // rest
    ['  o_o  ', ' (._.) ', '  | |  '], // fidget
    ['  o_o  ', ' (^_^) ', '  | |  '], // wiggle
  ],
}

// One-line face strings for narrow viewport mode, also authored with 'o'.
const FACES: Record<string, string> = {
  cat: '(=o.o=)',
  dog: '(o ^_^ o)',
  bunny: '(o.o )',
  fox: '(/o.o\\)',
  bear: '(o.o )',
  default: '(o_o)',
}

/** Returns a one-line face string for narrow viewport rendering. */
export function renderFace(companion: Companion): string {
  const face = FACES[companion.species] ?? FACES['default']!
  return companion.eye === 'o'
    ? face
    : face.replaceAll('o', companion.eye)
}

/**
 * Returns the sprite lines for the given animation frame, with the canonical
 * 'o' eye placeholder replaced by companion.eye.
 */
export function renderSprite(companion: Companion, frame: number): string[] {
  const frames = SPRITES[companion.species] ?? SPRITES['default']!
  const lines = frames[frame % frames.length]!
  return companion.eye === 'o'
    ? lines
    : lines.map(l => l.replaceAll('o', companion.eye))
}

/** Returns how many animation frames the species has. */
export function spriteFrameCount(species: string): number {
  const frames = SPRITES[species] ?? SPRITES['default']!
  return frames.length
}
