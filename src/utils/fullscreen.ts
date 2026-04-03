/**
 * Returns true when the browser's Fullscreen API reports an active element.
 * Safe to call during SSR (returns false).
 */
export function isFullscreenActive(): boolean {
  return (
    typeof document !== 'undefined' && document.fullscreenElement !== null
  )
}
