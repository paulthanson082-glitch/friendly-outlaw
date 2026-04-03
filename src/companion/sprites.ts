import type { Companion } from './types.js'

// Each species has an array of animation frames (each frame is an array of lines).
const SPRITES: Record<string, string[][]> = {
  cat: [
    [' /\\_/\\ ', '( o.o )', ' > ^ < '], // rest
    [' /\\_/\\ ', '( -.- )', ' > ^ < '], // fidget
    [' /\\_/\\ ', '( ^.^ )', ' >~^~< '], // wiggle
  ],
  dog: [
    [' /^ ^\\ ', '( o.o )', '  /|\\  '], // rest
    [' /^ ^\\ ', '( ^.^ )', '  /|\\  '], // fidget
    [' /^ ^\\ ', '( ~.~ )', ' \\-|-/ '], // wiggle
  ],
  bunny: [
    [' (\\/) ', '( >.< )', '(")_(")'], // rest
    [' (\\/) ', '( -.^ )', '(")_(")'], // fidget
    [' (\\/) ', '( ^.^ )', '(")_(")'], // wiggle
  ],
  default: [
    ['  o_o  ', ' (___) ', '  | |  '], // rest
    ['  o_o  ', ' (._.) ', '  | |  '], // fidget
    ['  o_o  ', ' (^_^) ', '  | |  '], // wiggle
  ],
}

const FACES: Record<string, string> = {
  cat: '(=^.^=)',
  dog: '(o ^_^ o)',
  bunny: '(>.< )',
  default: '(o_o)',
}

/** Returns a one-line face string for narrow terminal rendering. */
export function renderFace(companion: Companion): string {
  return FACES[companion.species] ?? FACES['default']!
}

/** Returns the sprite lines for the given animation frame. */
export function renderSprite(companion: Companion, frame: number): string[] {
  const frames = SPRITES[companion.species] ?? SPRITES['default']!
  return frames[frame % frames.length]!
}

/** Returns how many animation frames the species has. */
export function spriteFrameCount(species: string): number {
  const frames = SPRITES[species] ?? SPRITES['default']!
  return frames.length
}
