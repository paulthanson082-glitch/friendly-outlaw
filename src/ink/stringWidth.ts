/**
 * Returns the visible character width of a string, stripping ANSI escape codes.
 * Full-width (CJK) character handling is intentionally omitted for simplicity.
 */
export function stringWidth(str: string): number {
  // Strip ANSI SGR sequences
  return str.replace(/\u001b\[[0-9;]*m/g, '').length
}
