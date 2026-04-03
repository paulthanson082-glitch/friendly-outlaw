/**
 * Shim for `bun:bundle`'s `feature()` when running outside of Bun
 * (e.g. Next.js / Node). Feature flags are backed by GlobalConfig so they
 * can still be toggled at runtime via setGlobalConfig().
 */
import { getGlobalConfig } from '../utils/config.js'

type FeatureName = 'BUDDY' | string

const FEATURE_FLAGS: Record<string, (config: ReturnType<typeof getGlobalConfig>) => boolean> = {
  BUDDY: (config) => config.buddyEnabled,
}

export function feature(name: FeatureName): boolean {
  const fn = FEATURE_FLAGS[name]
  return fn ? fn(getGlobalConfig()) : false
}
