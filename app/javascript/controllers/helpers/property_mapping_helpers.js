// Shared definitions for the Property Mapping editor and show page.
// Every user-facing label lives here in English; render it through
// translate() so the dictionary stays the single source of translations.
import { translate } from "controllers/helpers/ui_helpers"

/**
 * Every dynamic property slot that exists on the resource tables.
 * Counts mirror db/schema.rb: 5 string, 10 integer, 5 decimal, 5 boolean,
 * 5 datetime. A slot is never shown to the user — the key is assigned
 * automatically and submitted as a hidden field.
 */
export const PROPERTY_SLOTS = [
  ...Array.from({ length: 5 }, (_, index) => ({ key: `property_string_${index + 1}`, type: "string" })),
  ...Array.from({ length: 10 }, (_, index) => ({ key: `property_integer_${index + 1}`, type: "integer" })),
  ...Array.from({ length: 5 }, (_, index) => ({ key: `property_decimal_${index + 1}`, type: "decimal" })),
  ...Array.from({ length: 5 }, (_, index) => ({ key: `property_boolean_${index + 1}`, type: "boolean" })),
  ...Array.from({ length: 5 }, (_, index) => ({ key: `property_datetime_${index + 1}`, type: "datetime" }))
]

/**
 * Friendly types shown in the Add Property picker. `storageType` is the real
 * database column family; "enum" is stored as an integer column with
 * input_type=select and an options array.
 */
export const PROPERTY_TYPES = [
  {
    value: "string",
    storageType: "string",
    label: "Text",
    icon: "text_fields",
    description: "Stores letters, numbers and symbols, up to 255 characters.",
    example: "e.g. Skin type, internal code, short note"
  },
  {
    value: "integer",
    storageType: "integer",
    label: "Whole number",
    icon: "numbers",
    description: "Stores whole numbers only — no decimals.",
    example: "e.g. Quantity, loyalty points, number of seats"
  },
  {
    value: "decimal",
    storageType: "decimal",
    label: "Decimal number",
    icon: "calculate",
    description: "Stores numbers with up to 4 decimal places.",
    example: "e.g. Price, weight, volume"
  },
  {
    value: "boolean",
    storageType: "boolean",
    label: "Yes / No",
    icon: "toggle_on",
    description: "Stores a true or false value.",
    example: "e.g. Organic certified, active, includes tester"
  },
  {
    value: "datetime",
    storageType: "datetime",
    label: "Date & time",
    icon: "calendar_month",
    description: "Stores a date and time.",
    example: "e.g. Expiry date, appointment time, last checked"
  },
  {
    value: "enum",
    storageType: "integer",
    label: "Choice list",
    icon: "list",
    description: "Stores one whole-number value from a list of choices you define.",
    example: "e.g. 1 = Gold, 2 = Silver, 3 = Bronze"
  }
]

const TYPE_BY_VALUE = Object.fromEntries(PROPERTY_TYPES.map((type) => [ type.value, type ]))

/**
 * Friendly per-type settings shown in the expandable Setup panel.
 * Only settings that make sense for the type are listed; any other metadata
 * keys are preserved by the backend merge without being shown here.
 */
export const PROPERTY_SETTINGS = {
  string: [
    {
      key: "placeholder", label: "Placeholder", kind: "text", placeholder: "e.g. Enter skin type",
      tooltip: "Hint text shown inside an empty input. Example: Enter skin type."
    },
    {
      key: "default", label: "Default value", kind: "text", placeholder: "e.g. Oily",
      tooltip: "Value filled in automatically for new records. Leave blank for no default."
    },
    {
      key: "prefix", label: "Prefix", kind: "text", placeholder: "e.g. SKU-",
      tooltip: "Text shown before the value. Example: SKU-."
    },
    {
      key: "suffix", label: "Suffix", kind: "text", placeholder: "e.g. ml",
      tooltip: "Text shown after the value. Example: ml."
    }
  ],
  integer: [
    {
      key: "input_type", label: "Display style", kind: "select",
      options: [
        { value: "", label: "Number field" },
        { value: "progress_bar", label: "Progress bar" },
        { value: "slider", label: "Slider" },
        { value: "star", label: "Star rating" }
      ],
      tooltip: "How the field is shown in forms that support it. Number field is the default."
    },
    {
      key: "placeholder", label: "Placeholder", kind: "text", placeholder: "e.g. 150",
      tooltip: "Hint text shown inside an empty input. Example: 150."
    },
    {
      key: "default", label: "Default value", kind: "number", step: "1", placeholder: "e.g. 0",
      tooltip: "Value filled in automatically for new records. Leave blank for no default."
    },
    {
      key: "min", label: "Minimum", kind: "number", step: "1", placeholder: "e.g. 0",
      tooltip: "Smallest allowed value. Example: 0."
    },
    {
      key: "max", label: "Maximum", kind: "number", step: "1", placeholder: "e.g. 9999",
      tooltip: "Largest allowed value. Example: 9999."
    },
    {
      key: "prefix", label: "Prefix", kind: "text", placeholder: "e.g. #",
      tooltip: "Text shown before the value. Example: #."
    },
    {
      key: "suffix", label: "Suffix", kind: "text", placeholder: "e.g. units",
      tooltip: "Text shown after the value. Example: units."
    }
  ],
  decimal: [
    {
      key: "input_type", label: "Display style", kind: "select",
      options: [
        { value: "", label: "Number field" },
        { value: "currency", label: "Currency" },
        { value: "percentage", label: "Percentage" }
      ],
      tooltip: "How the field is shown in forms that support it. Number field is the default."
    },
    {
      key: "placeholder", label: "Placeholder", kind: "text", placeholder: "e.g. 12.50",
      tooltip: "Hint text shown inside an empty input. Example: 12.50."
    },
    {
      key: "default", label: "Default value", kind: "number", step: "any", placeholder: "e.g. 0.00",
      tooltip: "Value filled in automatically for new records. Leave blank for no default."
    },
    {
      key: "currency", label: "Currency", kind: "text", placeholder: "e.g. USD",
      tooltip: "Three-letter currency code used when the display style is Currency. Example: USD or VND."
    },
    {
      key: "precision", label: "Decimal places", kind: "number", step: "1", min: 0, max: 4, placeholder: "e.g. 2",
      tooltip: "Digits after the decimal point, from 0 to 4. Example: 2 for 12.50."
    },
    {
      key: "prefix", label: "Prefix", kind: "text", placeholder: "e.g. $",
      tooltip: "Text shown before the value. Example: $."
    },
    {
      key: "suffix", label: "Suffix", kind: "text", placeholder: "e.g. kg",
      tooltip: "Text shown after the value. Example: kg."
    }
  ],
  boolean: [
    {
      key: "default", label: "Default value", kind: "select",
      options: [
        { value: "", label: "No default" },
        { value: "true", label: "Yes" },
        { value: "false", label: "No" }
      ],
      tooltip: "Value filled in automatically for new records. Leave blank for no default."
    },
    {
      key: "true_label", label: "Yes label", kind: "text", placeholder: "e.g. Active",
      tooltip: "Text shown for a Yes value. Example: Active."
    },
    {
      key: "false_label", label: "No label", kind: "text", placeholder: "e.g. Inactive",
      tooltip: "Text shown for a No value. Example: Inactive."
    }
  ],
  datetime: [
    {
      key: "default", label: "Default value", kind: "datetime-local",
      tooltip: "Value filled in automatically for new records. Leave blank for no default."
    },
    {
      key: "format", label: "Display format", kind: "text", placeholder: "e.g. DD/MM/YYYY HH:mm",
      tooltip: "How dates are displayed. Example: DD/MM/YYYY HH:mm."
    },
    {
      key: "timezone", label: "Timezone", kind: "text", placeholder: "e.g. UTC",
      tooltip: "Timezone used when displaying this date. Example: UTC or Asia/Ho_Chi_Minh."
    }
  ],
  enum: []
}

export const EXTRA_COLUMN_TYPES = PROPERTY_TYPES.filter((type) => type.value !== "enum")

const DISPLAY_STYLE_LABELS = {
  text: "Text",
  toggle: "Yes / No",
  number: "Number field",
  progress_bar: "Progress bar",
  slider: "Slider",
  star: "Star rating",
  currency: "Currency",
  percentage: "Percentage",
  select: "Choice list"
}

/** @returns {object} */
export const propertyTypeFor = (type) => TYPE_BY_VALUE[type] || TYPE_BY_VALUE.string

/** @returns {string} */
export const storageTypeFor = (type) => propertyTypeFor(type).storageType

/**
 * The friendly editor type for one metadata entry. An integer entry with
 * input_type=select is a choice list (enum), not a plain whole number.
 * @returns {string}
 */
export const uiTypeForEntry = (entry) => {
  if (!entry) return "string"
  if (entry.input_type === "select") return "enum"
  if (entry.type) return entry.type

  const match = String(entry.key || "").match(/^property_(string|integer|decimal|boolean|datetime)_\d+$/)
  return match ? match[1] : "string"
}

/** @returns {string} */
export const propertyTypeLabel = (type) => translate(propertyTypeFor(type).label)

/** @returns {string} */
export const propertyTypeIcon = (type) => propertyTypeFor(type).icon

/** @returns {string} */
export const propertyTypeDescription = (type) => translate(propertyTypeFor(type).description)

/** @returns {string} */
export const propertyTypeExample = (type) => translate(propertyTypeFor(type).example)

/** @returns {string} */
export const propertyTypeTooltip = (type) => `${propertyTypeDescription(type)} ${propertyTypeExample(type)}`

/** @returns {Array<{key: string, type: string}>} */
export const propertySlotsForType = (type) => {
  const storageType = storageTypeFor(type)
  return PROPERTY_SLOTS.filter((slot) => slot.type === storageType)
}

/** @returns {Array<{key: string, type: string}>} */
export const propertySlotsExcluding = (type, entries = [], usedHistory = []) => {
  const used = new Set([
    ...entries.map((entry) => entry.key),
    ...(Array.isArray(usedHistory) ? usedHistory : [])
  ])
  return propertySlotsForType(type).filter((slot) => !used.has(slot.key))
}

/** @returns {number} */
export const slotsRemaining = (type, entries = [], usedHistory = []) =>
  propertySlotsExcluding(type, entries, usedHistory).length

/** @returns {{key: string, type: string} | null} */
export const nextAvailableSlot = (type, entries = [], usedHistory = []) =>
  propertySlotsExcluding(type, entries, usedHistory)[0] || null

/** @returns {Array} */
export const propertySettingsFor = (type) => PROPERTY_SETTINGS[type] || []

/** @returns {Array} */
export const enumOptionsFor = (entry) => (Array.isArray(entry?.options) ? entry.options : [])

/** @returns {number} */
export const nextEnumValue = (entry) => {
  const values = enumOptionsFor(entry)
    .map((option) => Number(option.value))
    .filter((value) => Number.isFinite(value))
  return values.length > 0 ? Math.max(...values) + 1 : 1
}

/** Short summary shown in the Setup column and on the show page. */
export const propertySettingsSummary = (entry) => {
  if (!entry) return translate("No extra settings")

  if (uiTypeForEntry(entry) === "enum") {
    const options = enumOptionsFor(entry)
    if (options.length === 0) return translate("No choices yet")
    const labels = options.map((option) => option.label).filter(Boolean).slice(0, 3)
    const more = options.length > labels.length ? ` +${options.length - labels.length}` : ""
    const countLabel = options.length === 1 ? translate("choice") : translate("choices")
    const defaultOption = options.find((option) => String(option.value) === String(entry.default))
    const defaultText = defaultOption ? ` · ${translate("Default")}: ${defaultOption.label || defaultOption.value}` : ""
    return `${options.length} ${countLabel}${labels.length > 0 ? `: ${labels.join(", ")}${more}` : ""}${defaultText}`
  }

  const parts = []
  const style = DISPLAY_STYLE_LABELS[entry.input_type]
  if (style) parts.push(translate(style))
  if (entry.min !== undefined && entry.min !== null && entry.min !== "") parts.push(`${translate("Min")} ${entry.min}`)
  if (entry.max !== undefined && entry.max !== null && entry.max !== "") parts.push(`${translate("Max")} ${entry.max}`)
  if (entry.currency) parts.push(String(entry.currency).toUpperCase())
  if (entry.precision !== undefined && entry.precision !== null && entry.precision !== "") {
    parts.push(`${entry.precision} ${translate("decimal places")}`)
  }
  if (entry.true_label || entry.false_label) {
    parts.push(`${entry.true_label || translate("Yes")} / ${entry.false_label || translate("No")}`)
  }
  if (entry.format) parts.push(entry.format)
  if (entry.timezone) parts.push(entry.timezone)
  if (entry.placeholder) parts.push(`${translate("Placeholder")}: ${entry.placeholder}`)
  if (entry.default !== undefined && entry.default !== null && entry.default !== "") {
    let defaultValue = entry.default
    if (entry.default === true || entry.default === "true") defaultValue = translate("Yes")
    if (entry.default === false || entry.default === "false") defaultValue = translate("No")
    parts.push(`${translate("Default")}: ${defaultValue}`)
  }
  if (entry.prefix) parts.push(`${translate("Prefix")}: ${entry.prefix}`)
  if (entry.suffix) parts.push(`${translate("Suffix")}: ${entry.suffix}`)

  return parts.length > 0 ? parts.join(" · ") : translate("No extra settings")
}
