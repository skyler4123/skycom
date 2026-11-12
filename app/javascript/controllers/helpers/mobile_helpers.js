// Shared chrome, formatters and labels for the Shell-First mobile pages.
// Every /mobile screen renders through these helpers so the browser and the
// native shell see the same structure. Copy goes through translate() (see
// dictionary.js); colors use semantic tokens only (bin/check_colors --strict).
//
// Depends on: controllers/helpers/ui_helpers.js (translate, timeFormat, escapeHtml)
//             controllers/helpers/money_helpers.js (formatMoney)
// Docs: docs/MOBILE.md §2
import { translate, timeFormat, escapeHtml } from "controllers/helpers/ui_helpers"
import { formatMoney } from "controllers/helpers/money_helpers"

// --- Chrome ---------------------------------------------------------------

/**
 * Page container shared by every mobile screen.
 * @param {string} html
 * @param {string} [attributes] extra attributes for <main>
 */
export const mobileMain = (html, attributes = "") => `
  <main class="mx-auto w-full max-w-lg md:max-w-2xl lg:max-w-4xl xl:max-w-5xl px-4 pb-8 pt-4" ${attributes}>
    ${html}
  </main>
`

/**
 * Sticky top bar: brand (or back link) on the left, theme toggle + avatar on
 * the right.
 * @param {object} options
 * @param {string} options.title
 * @param {string|null} [options.backPath]
 * @param {string|null} [options.avatarName]
 * @param {string|null} [options.avatarPath]
 * @param {boolean} [options.replaceNavigation]
 */
export const mobileHeader = ({ title, backPath = null, avatarName = null, avatarPath = null, replaceNavigation = false }) => {
  const navigationAttribute = replaceNavigation ? `data-turbo-action="replace"` : ""
  const left = backPath
    ? `
        <div class="flex min-w-0 items-center gap-1">
          <a href="${backPath}" ${navigationAttribute} aria-label="${translate("Go back")}"
            class="flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted">
            <span class="material-symbols-outlined text-2xl">arrow_back</span>
          </a>
          <h1 class="truncate text-base font-semibold leading-tight text-foreground">${escapeHtml(translate(title))}</h1>
        </div>`
    : `
        <div class="flex min-w-0 items-center gap-2">
          <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground shadow-sm">
            <span class="material-symbols-outlined text-xl">hub</span>
          </div>
          <div class="flex min-w-0 flex-col">
            <span class="text-xs font-semibold uppercase tracking-wider text-primary">${translate("Skycom ERP")}</span>
            <h1 class="truncate text-base font-semibold leading-tight text-foreground">${escapeHtml(translate(title))}</h1>
          </div>
        </div>`

  return `
    <header class="sticky top-0 z-40 border-b border-line bg-card/90 pt-[env(safe-area-inset-top)] backdrop-blur-xl">
      <div class="flex h-16 items-center justify-between gap-2 px-4">
        ${left}
        <div class="flex shrink-0 items-center gap-1">
          <button type="button" data-controller="mobile--theme" data-action="click->mobile--theme#toggle"
            class="flex h-11 w-11 cursor-pointer items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            aria-label="${translate("Toggle dark mode")}">
            <span class="dark:hidden"><span class="material-symbols-outlined text-2xl">dark_mode</span></span>
            <span class="hidden dark:block"><span class="material-symbols-outlined text-2xl">light_mode</span></span>
          </button>
          ${avatarName
            ? `<a href="${avatarPath || "#"}" ${navigationAttribute} aria-label="${translate("Profile")}"
                class="ml-1 flex h-8 w-8 shrink-0 cursor-pointer items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">
                ${escapeHtml(mobileInitials(avatarName))}
              </a>`
            : ""}
        </div>
      </div>
    </header>
  `
}

/**
 * Initials circle (no image dependency).
 * @param {object} options
 * @param {string} options.name
 * @param {string} [options.size]
 */
export const mobileAvatar = ({ name, size = "h-16 w-16 text-xl" }) => `
  <span class="flex shrink-0 items-center justify-center rounded-full bg-primary/10 font-bold text-primary ${size}">
    ${escapeHtml(mobileInitials(name))}
  </span>
`

/**
 * Label / value / hint card.
 * @param {object} options
 * @param {string} options.label
 * @param {string} options.value
 * @param {string|null} [options.hint]
 * @param {string} [options.hintClass]
 * @param {string|null} [options.icon]
 */
export const mobileStatTile = ({ label, value, hint = null, hintClass = "text-muted-foreground", icon = null }) => `
  <div class="flex flex-col justify-between rounded-xl border border-line bg-card p-4 shadow-sm">
    <div class="flex items-center justify-between gap-2">
      <span class="text-xs font-medium text-muted-foreground">${escapeHtml(translate(label))}</span>
      <span class="flex items-center gap-1">
        ${icon ? `<span class="material-symbols-outlined text-xl text-primary">${icon}</span>` : ""}
      </span>
    </div>
    <div class="mt-2">
      <p class="text-lg font-bold leading-tight text-foreground">${value}</p>
      ${hint ? `<p class="mt-0.5 text-xs ${hintClass}">${hint}</p>` : ""}
    </div>
  </div>
`

/**
 * Dashed empty state.
 * @param {object} options
 * @param {string} options.title
 * @param {string} options.hint
 * @param {string} [options.icon]
 */
export const mobileEmptyState = ({ title, hint, icon = "inbox" }) => `
  <div class="flex flex-col items-center gap-2 rounded-xl border border-dashed border-line bg-card p-6 text-center">
    <span class="material-symbols-outlined text-3xl text-muted-foreground">${icon}</span>
    <p class="text-sm font-semibold text-foreground">${escapeHtml(translate(title))}</p>
    <p class="text-xs text-muted-foreground">${escapeHtml(translate(hint))}</p>
  </div>
`

/**
 * Previous/next month bar. The next arrow is disabled on the current month.
 * @param {object} options
 * @param {string} options.label
 * @param {string} options.prevPath
 * @param {string} options.nextPath
 * @param {boolean} [options.nextDisabled]
 */
export const mobileMonthNav = ({ label, prevPath, nextPath, nextDisabled = false }) => `
  <div class="flex items-center justify-between rounded-xl border border-line bg-card p-2 shadow-sm">
    <a href="${prevPath}" aria-label="${translate("Previous month")}"
      class="flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-primary">
      <span class="material-symbols-outlined text-xl">chevron_left</span>
    </a>
    <span class="flex min-w-0 items-center gap-2 px-2 text-sm font-semibold text-foreground">
      <span class="material-symbols-outlined text-lg text-primary">calendar_month</span>
      <span class="truncate">${escapeHtml(label)}</span>
    </span>
    ${nextDisabled
      ? `<span aria-disabled="true" aria-label="${translate("Next month")}"
          class="flex h-10 w-10 shrink-0 cursor-not-allowed items-center justify-center rounded-lg text-muted-foreground/60">
          <span class="material-symbols-outlined text-xl">chevron_right</span>
        </span>`
      : `<a href="${nextPath}" aria-label="${translate("Next month")}"
          class="flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-primary">
          <span class="material-symbols-outlined text-xl">chevron_right</span>
        </a>`}
  </div>
`

/**
 * Full-page fetch failure with a retry button.
 * @param {object} options
 * @param {string} options.message
 */
export const mobileErrorState = ({ message }) => `
  ${mobileMain(`
    <div class="flex flex-col items-center gap-3 rounded-xl border border-danger/20 bg-danger/10 p-6 text-center">
      <span class="material-symbols-outlined text-3xl text-danger">error</span>
      <p class="text-sm font-semibold text-danger">${escapeHtml(message)}</p>
      <button type="button" data-mobile-retry
        class="flex h-10 cursor-pointer items-center justify-center rounded-lg bg-card px-4 text-sm font-semibold text-foreground ring-1 ring-line transition-colors hover:bg-muted">
        ${translate("Retry")}
      </button>
    </div>
  `)}
`

/**
 * Replace a page element with the failure state and wire its retry button.
 * @param {HTMLElement} element
 * @param {Error & { errors?: string[] }} error
 * @param {() => void} retry
 */
export const renderMobileError = (element, error, retry) => {
  const message = error?.errors?.join(", ") || error?.message || translate("Failed to load this page.")
  element.innerHTML = mobileErrorState({ message })
  element.querySelector("[data-mobile-retry]")?.addEventListener("click", retry)
}

// --- Formatters -----------------------------------------------------------

/**
 * Time-appropriate greeting with the first name.
 * @param {string} name
 */
export const mobileGreeting = (name) => {
  const firstName = String(name || "").trim().split(/\s+/).filter(Boolean)[0] || translate("there")
  const hour = new Date().getHours()
  const salutation =
    hour >= 5 && hour < 12
      ? translate("Good morning")
      : hour >= 12 && hour < 18
        ? translate("Good afternoon")
        : translate("Good evening")
  return `${salutation}, ${escapeHtml(firstName)}`
}

/**
 * First letter of the first two name parts.
 * @param {string} name
 */
export const mobileInitials = (name) => {
  const parts = String(name || "").trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return "?"
  return parts.map((part) => part[0]).join("").slice(0, 2).toUpperCase()
}

/**
 * "160h 00m" from minutes.
 * @param {number} minutes
 */
export const mobileDuration = (minutes) => {
  const total = Number(minutes || 0)
  return `${Math.floor(total / 60)}h ${String(total % 60).padStart(2, "0")}m`
}

/**
 * "8h 00m" from stored seconds.
 * @param {number} seconds
 */
export const mobileDurationFromSeconds = (seconds) => mobileDuration(Math.floor(Number(seconds || 0) / 60))

/**
 * "09:00 AM" in UTC or a numeric hour offset.
 * @param {string|Date} value
 * @param {number|null} [offsetHours]
 */
export const mobileTime = (value, offsetHours = null) => {
  if (offsetHours === null || offsetHours === undefined) return timeFormat(value, "hh:mm A", "UTC")
  return timeFormat(value, "hh:mm A", Number(offsetHours))
}

/** "05 November 2026" */
export const mobileDate = (value) => timeFormat(value, "DD MMMM YYYY", "UTC")

/** "Wed" */
export const mobileWeekday = (value) => timeFormat(value, "ddd", "UTC")

/** "30 Nov" */
export const mobileShortDate = (value) => timeFormat(value, "DD MMM", "UTC")

/** "November 2026" */
export const mobileMonthLabel = (value) => timeFormat(value, "MMMM YYYY", "UTC")

/** Stored cents to "$1,234.56" / "1.234.567 ₫". */
export const mobileMoney = (cents, currency) => formatMoney(cents, currency)

/** "90.9%" for a month summary, or "—" when no record exists. */
export const mobileAttendanceRate = (month) => {
  if (!month || !month.total_records) return "—"
  return `${((Number(month.total_present_days || 0) / Number(month.total_records)) * 100).toFixed(1)}%`
}

/**
 * Ruby-style humanize for enum keys: "half_day" -> "Half day".
 * @param {string} value
 */
export const mobileHumanize = (value) => {
  const text = String(value || "").replace(/_/g, " ").trim()
  if (!text) return "—"
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase()
}

const attendanceBadgeClass = (status) => {
  switch (status) {
    case "present":
      return "bg-success/10 text-success"
    case "half_day":
    case "missing_checkout":
      return "bg-warning/10 text-warning"
    case "late":
      return "bg-danger/10 text-danger"
    default:
      return "bg-muted text-muted-foreground"
  }
}

/** Attendance status pill. */
export const mobileAttendanceBadge = (status) => `
  <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${attendanceBadgeClass(status)}">
    ${escapeHtml(mobileHumanize(status))}
  </span>
`

const payrollBadgeClass = (status) => {
  switch (status) {
    case "draft":
      return "bg-warning/10 text-warning"
    case "approved":
      return "bg-info/10 text-info"
    case "paid":
      return "bg-success/10 text-success"
    default:
      return "bg-muted text-muted-foreground"
  }
}

/** Payroll status pill. */
export const mobilePayrollBadge = (status) => `
  <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${payrollBadgeClass(status)}">
    ${escapeHtml(mobileHumanize(status))}
  </span>
`

const EMPLOYEE_TYPE_LABELS = {
  owner: "Owner",
  full_time: "Full-Time",
  part_time: "Part-Time",
  contractor: "Contractor",
  intern: "Intern"
}

const BUSINESS_TYPE_LABELS = {
  onsite_miss: "Onsite Miss",
  remote_work: "Remote Work",
  field_work: "Field Work"
}

/** Employee type label ("Full-Time"). */
export const mobileEmployeeTypeLabel = (type) => translate(EMPLOYEE_TYPE_LABELS[type] || mobileHumanize(type))

/** Attendance business type label ("Onsite Miss"). */
export const mobileBusinessTypeLabel = (type) => translate(BUSINESS_TYPE_LABELS[type] || mobileHumanize(type))
