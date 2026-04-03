export interface GlobalConfig {
  /** When true the companion sprite is hidden globally. */
  companionMuted: boolean
  /** Feature flag: enables the companion/buddy system. */
  buddyEnabled: boolean
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
