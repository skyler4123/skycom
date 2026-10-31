// Currency formatting shared by dashboard/reporting pages.
// Skycom stores USD in cents and VND in whole dong (VND has no subunits), so the
// divisor is currency-aware. All UI money values must go through this helper.

const normalizeCurrency = (currency) => (currency || "usd").toString().toLowerCase()

/** Convert stored minor units to the amount Intl.NumberFormat expects. */
export const minorToMajor = (minorUnits, currency = "usd") => {
  const code = normalizeCurrency(currency)
  const amount = Number(minorUnits || 0)
  return code === "vnd" ? amount : amount / 100
}

/**
 * Format stored money for display.
 * @param {number} minorUnits
 * @param {string} [currency]
 * @param {Intl.NumberFormatOptions} [options]
 * @returns {string}
 */
export const formatMoney = (minorUnits, currency = "usd", options = {}) => {
  const code = normalizeCurrency(currency)
  return new Intl.NumberFormat(code === "vnd" ? "vi-VN" : "en-US", {
    style: "currency",
    currency: code.toUpperCase(),
    maximumFractionDigits: code === "vnd" ? 0 : 2,
    ...options
  }).format(minorToMajor(minorUnits, code))
}

/** Compact number for chart axes and tight cards. */
export const formatCompactNumber = (value, currency = "usd") => {
  const code = normalizeCurrency(currency)
  return new Intl.NumberFormat(code === "vnd" ? "vi-VN" : "en-US", {
    notation: "compact",
    maximumFractionDigits: 1
  }).format(Number(value || 0))
}

/** Chart series use major units, not the stored minor units. */
export const chartAmount = (minorUnits, currency = "usd") => minorToMajor(minorUnits, currency)
