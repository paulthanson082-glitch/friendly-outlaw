import type { StoredCompanion } from '../companion/types.js'

export interface GlobalConfig {
  /** When true the companion sprite is hidden globally. */
  companionMuted: boolean
  /** Feature flag: enables the companion/buddy system. */
  buddyEnabled: boolean
  /** OAuth account info when signed in. */
  oauthAccount?: { accountUuid: string }
  /** Fallback user identifier when no OAuth account is present. */
  userID?: string
  /**
   * Persisted companion "soul" (name, etc.). Bones are always re-rolled from
   * the seed on top of this, so species / rarity can never be faked here.
   */
  companion?: StoredCompanion
}

let _config: GlobalConfig = {
  companionMuted: false,
  buddyEnabled: true,
}

/** Returns the current global config object. */
export function getGlobalConfig(): GlobalConfig {
  return _config
}

/** Merges a partial config patch into the global config. */
export function setGlobalConfig(patch: Partial<GlobalConfig>): void {
  _config = { ..._config, ...patch }
}
