// Time display helpers — the one place where UTC wire values become the
// friendly clock a user reads. See docs/TIME_DISPLAY.md.
//
// The wire is always UTC. The screen always uses the timezone that owns the
// record:
//   - operation pages  -> the appointment Branch/Warehouse (`locationTime`)
//   - company/mobile   -> the Company (`companyTime`)
//   - admin            -> UTC (`utcTime`)
//   - date-only values -> `dateOnly` (never timezone-converted)
//
// Depends on: controllers/helpers/ui_helpers.js (timeFormat)
//             controllers/helpers/auth_helpers.js (currentCompany)
// Docs: docs/TIME_DISPLAY.md
import dayjs from "dayjs"
import utc from "dayjs/plugin/utc"
import { timeFormat } from "controllers/helpers/ui_helpers"
import { currentCompany } from "controllers/helpers/auth_helpers"

dayjs.extend(utc)

export const TIMESTAMP_FORMAT = "DD MMM YYYY, HH:mm"
export const DATE_FORMAT = "DD MMM YYYY"
export const TIME_FORMAT = "HH:mm"
export const MONTH_FORMAT = "MMMM YYYY"
export const DATETIME_LOCAL_FORMAT = "YYYY-MM-DDTHH:mm"

/**
 * Converts a timezone value into a numeric UTC offset in hours.
 * Accepts a Rails enum key ("plus_7", "minus_5", "utc"), a number, or an object
 * with `utc_offset` (seconds) or `timezone`.
 * @param {string|number|object|null|undefined} value
 * @returns {number|null}
 */
export const timezoneOffsetHours = (value) => {
  if (value === null || value === undefined || value === "") return null
  if (typeof value === "number") return value
  if (typeof value === "object") {
    if (value.utc_offset !== null && value.utc_offset !== undefined) return Number(value.utc_offset) / 3600
    return timezoneOffsetHours(value.timezone)
  }

  const text = String(value).trim().toLowerCase()
  const enumMatch = text.match(/^(minus|plus)_(\d{1,2})$/)
  if (enumMatch) return enumMatch[1] === "minus" ? -Number(enumMatch[2]) : Number(enumMatch[2])
  if (text === "utc" || text === "utc+0" || text === "utc-0") return 0

  const numeric = Number(text)
  return Number.isNaN(numeric) ? null : numeric
}

/**
 * The current company's UTC offset in hours.
 * @returns {number|null}
 */
export const companyOffsetHours = () => timezoneOffsetHours(currentCompany()?.timezone)

/**
 * Renders `plus_7` as `UTC+7`; never show the raw enum key.
 * @param {string|number|object|null|undefined} value
 * @returns {string}
 */
export const timezoneLabel = (value) => {
  const offset = timezoneOffsetHours(value)
  if (offset === null) return "—"
  if (offset === 0) return "UTC"
  return `UTC${offset > 0 ? "+" : ""}${offset}`
}

/**
 * Admin display: always UTC.
 * @param {string|number|Date|null|undefined} value
 * @param {string} [format]
 * @returns {string}
 */
export const utcTime = (value, format = TIMESTAMP_FORMAT) => timeFormat(value, format, "UTC")

/**
 * Company display: the tenant's local clock.
 * @param {string|number|Date|null|undefined} value
 * @param {string} [format]
 * @returns {string}
 */
export const companyTime = (value, format = TIMESTAMP_FORMAT) => {
  const offset = companyOffsetHours()
  return timeFormat(value, format, offset === null ? "UTC" : offset)
}

/**
 * Operation display: the Branch/Warehouse clock that owns the console.
 * @param {string|number|Date|null|undefined} value
 * @param {string} [format]
 * @param {object|string|number|null} [location] appointment location or timezone
 * @returns {string}
 */
export const locationTime = (value, format = TIMESTAMP_FORMAT, location = null) => {
  const offset = timezoneOffsetHours(location) ?? companyOffsetHours()
  return timeFormat(value, format, offset === null ? "UTC" : offset)
}

/**
 * Calendar date display. Date-only strings are rendered as-is so they never
 * shift a day; full timestamps are converted with the owning timezone.
 * @param {string|number|Date|null|undefined} value
 * @param {string} [format]
 * @param {object|string|number|null} [location]
 * @returns {string}
 */
export const dateOnly = (value, format = DATE_FORMAT, location = null) => {
  if (value === null || value === undefined || value === "") return "—"
  const text = String(value)
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return dayjs(`${text}T12:00:00`).format(format)
  return locationTime(value, format, location)
}

/**
 * "Now" at the owning location, as a dayjs instance carrying that offset.
 * @param {object|string|number|null} [location]
 * @returns {dayjs.Dayjs}
 */
export const locationNow = (location = null) => {
  const offset = timezoneOffsetHours(location) ?? companyOffsetHours() ?? 0
  return dayjs().utc().utcOffset(offset * 60)
}

/**
 * Location-local calendar day, e.g. "2026-11-17".
 * @param {object|string|number|null} [location]
 * @returns {string}
 */
export const localToday = (location = null) => locationNow(location).format("YYYY-MM-DD")

/**
 * Location-local month, e.g. "2026-11".
 * @param {object|string|number|null} [location]
 * @returns {string}
 */
export const localMonth = (location = null) => locationNow(location).format("YYYY-MM")

/**
 * Wall-clock time display for `time` columns. These values have no date and no
 * timezone, so they are rendered as-is, never converted.
 * @param {string|null|undefined} value
 * @param {string} [format]
 * @returns {string}
 */
export const timeOnly = (value, format = TIME_FORMAT) => {
  if (value === null || value === undefined || value === "") return "—"
  const match = String(value).match(/(\d{2}):(\d{2})(?::\d{2})?/)
  if (!match) return "—"
  return dayjs(`2000-01-01T${match[1]}:${match[2]}:00`).format(format)
}

/**
 * Seeds a `datetime-local` input with the owning location's wall clock.
 * @param {string|number|Date|null|undefined} value
 * @param {object|string|number|null} [location]
 * @returns {string}
 */
export const datetimeLocalValue = (value, location = null) => {
  if (value === null || value === undefined || value === "") return ""
  const formatted = locationTime(value, DATETIME_LOCAL_FORMAT, location)
  return formatted === "—" ? "" : formatted
}

/**
 * Converts a `datetime-local`/wall-clock value back to a UTC ISO string.
 * @param {string|null|undefined} value
 * @param {object|string|number|null} [location]
 * @returns {string|null}
 */
export const fromDatetimeLocal = (value, location = null) => {
  if (!value) return null
  const offset = timezoneOffsetHours(location) ?? companyOffsetHours() ?? 0
  return dayjs(value).utcOffset(offset * 60, true).utc().toISOString()
}
