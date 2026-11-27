// Company Ticket visibility helpers — one source of truth for the two levels
// on the Help Center ticket (company_wide / only_me). The Rails enum owns the
// values; this file owns the labels, icons, tooltip copy, and badge markup.
import { translate, tooltip } from "controllers/helpers/ui_helpers"

const VISIBILITY_META = {
  only_me: {
    labelKey: "Only me",
    descriptionKey: "Only you, the company owner, and Skycom Support can see this ticket.",
    badgeDescriptionKey: "Only the creator, the company owner, and Skycom Support can see this ticket.",
    icon: "lock",
    classes: "bg-muted text-muted-foreground border border-line"
  },
  company_wide: {
    labelKey: "Everyone",
    descriptionKey: "All employees in your company can see this ticket. Skycom Support can always see it.",
    badgeDescriptionKey: "All employees in your company can see this ticket. Skycom Support can always see it.",
    icon: "groups",
    classes: "bg-primary/10 text-primary border border-primary/20"
  }
}

/**
 * @param {string} value
 * @returns {string}
 */
export const companyTicketVisibilityLabel = (value) => {
  const meta = VISIBILITY_META[value]
  return meta ? translate(meta.labelKey) : translate("Unknown")
}

/**
 * @param {string} value
 * @returns {string}
 */
export const companyTicketVisibilityDescription = (value) => {
  const meta = VISIBILITY_META[value]
  return meta ? translate(meta.descriptionKey) : ""
}

/**
 * @param {string} value
 * @returns {string}
 */
export const companyTicketVisibilityBadgeDescription = (value) => {
  const meta = VISIBILITY_META[value]
  return meta ? translate(meta.badgeDescriptionKey) : ""
}

/**
 * @param {string} value
 * @returns {string}
 */
export const companyTicketVisibilityBadge = (value) => {
  const meta = VISIBILITY_META[value] || VISIBILITY_META.only_me
  return `
    <span class="inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-md ${meta.classes}"
      ${tooltip(translate(meta.badgeDescriptionKey))}>
      <span class="material-symbols-outlined text-[14px]">${meta.icon}</span>
      ${translate(meta.labelKey)}
    </span>`
}

/**
 * @returns {{ value: string, label: string, description: string }[]}
 */
export const companyTicketVisibilityOptions = () => [
  {
    value: "only_me",
    label: translate("Only me"),
    description: translate("Only you, the company owner, and Skycom Support can see this ticket.")
  },
  {
    value: "company_wide",
    label: translate("Everyone in company"),
    description: translate("All employees in your company can see this ticket.")
  }
]
