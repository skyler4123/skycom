// Chart colors read from the live semantic tokens, so charts follow a rebrand
// and the light/dark switch without a separate palette. Values are resolved at
// render time from :root / .dark in app/assets/tailwind/application.css.
//
// Usage:
//   import { chartPalette, tokenColor } from "controllers/helpers/chart_colors"
//   colors: chartPalette()

const FALLBACKS = {
  primary: "#4f46e5",
  success: "#059669",
  warning: "#d97706",
  danger: "#dc2626",
  info: "#2563eb",
  "muted-foreground": "#64748b",
  line: "#e2e8f0",
  card: "#ffffff"
}

/**
 * Resolve one semantic token to a CSS color string.
 * @param {string} token - token name without the `--` prefix (e.g. "primary").
 * @returns {string}
 */
export const tokenColor = (token) => {
  const fallback = FALLBACKS[token] || "#6366f1"
  if (typeof document === "undefined") return fallback
  const value = getComputedStyle(document.documentElement).getPropertyValue(`--${token}`).trim()
  return value || fallback
}

/**
 * Ordered series palette derived from the semantic tokens.
 * @param {number} [count] - repeat the palette when more series are needed.
 * @returns {string[]}
 */
export const chartPalette = (count = 0) => {
  const palette = ["primary", "success", "warning", "danger", "info"].map(tokenColor)
  if (count <= palette.length) return palette.slice(0, count || palette.length)
  return Array.from({ length: count }, (_, i) => palette[i % palette.length])
}

/**
 * Same token at a given opacity, as a CSS color usable by SVG/canvas.
 * @param {string} token
 * @param {number} percent
 * @returns {string}
 */
export const tokenColorAlpha = (token, percent) =>
  `color-mix(in oklab, ${tokenColor(token)} ${percent}%, transparent)`

/** Axis / legend label color. */
export const chartLabelColor = () => tokenColor("muted-foreground")

/** Grid line color. */
export const chartGridColor = () => tokenColor("line")
