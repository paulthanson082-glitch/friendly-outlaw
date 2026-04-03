/** Shape of the global application state consumed by useAppState. */
export interface AppState {
  /** The text the companion is currently saying; undefined when silent. */
  companionReaction: string | undefined
  /** Timestamp (ms) of the last "pet" interaction, or null if never petted. */
  companionPetAt: number | null
  /** Which footer element is currently keyboard-focused. */
  footerSelection: string | null
}
