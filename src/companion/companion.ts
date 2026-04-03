import type { Companion } from './types.js'

let _companion: Companion | null = null

/** Returns the currently active companion, or null if none is set. */
export function getCompanion(): Companion | null {
  return _companion
}

/** Sets (or clears) the active companion. */
export function setCompanion(companion: Companion | null): void {
  _companion = companion
}
