// Shared presentation helpers for the Table Config editor and show page.
// Column labels are never edited here: standard labels are fixed below and
// property/extra labels come from the Property Mapping.
import { translate } from "controllers/helpers/ui_helpers"
import {
  enumOptionsFor,
  propertyTypeIcon,
  propertyTypeLabel,
  propertyTypeTooltip,
  uiTypeForEntry
} from "controllers/helpers/property_mapping_helpers"

// Keep in sync with TableConfig::STANDARD_COLUMN_NAMES (app/models/table_config.rb).
export const STANDARD_COLUMN_NAMES = {
  name: "Name",
  description: "Description",
  code: "Code",
  title: "Title",
  quantity: "Quantity",
  pending: "Pending",
  workflow_status: "Status",
  brand: "Brand",
  price_cents: "Price",
  cost_cents: "Cost",
  stock_quantity: "Stock on hand",
  unit_of_measure: "Unit"
}

export const STANDARD_COLUMN_TYPES = {
  name: "string",
  description: "string",
  code: "string",
  title: "string",
  quantity: "integer",
  pending: "integer",
  workflow_status: "string",
  brand: "string",
  price_cents: "integer",
  cost_cents: "integer",
  stock_quantity: "integer",
  unit_of_measure: "string"
}

// Mirrors TableConfig::PRODUCT_STANDARD_KEYS. Offered only for product configs.
export const PRODUCT_STANDARD_KEYS = [ "brand", "price_cents", "cost_cents", "stock_quantity", "unit_of_measure" ]

// Mirrors TableConfig::FILTERABLE_STANDARD_KEYS — the only standard keys with a Meilisearch filter.
const FILTERABLE_STANDARD_KEYS = [ "quantity", "pending" ]

const SEARCHABLE_STANDARD_KEYS = [ "name", "description", "code", "title" ]

/** Standard keys the Table Config editor may offer for one resource. */
export const standardColumnKeysFor = (resourceName) => {
  const productOnly = resourceName === "products" ? [] : PRODUCT_STANDARD_KEYS
  return Object.keys(STANDARD_COLUMN_NAMES).filter((key) => !productOnly.includes(key))
}

const FILTER_LABELS = {
  range: "Range",
  enum: "Choice list",
  boolean: "Yes / No",
  date: "Date"
}

/** @returns {object | null} */
const entryForKey = (key, entries = []) =>
  (entries || []).find((entry) => entry?.key === key) || null

/** @returns {"standard" | "property" | "extra" | "other"} */
export const columnSource = (key) => {
  const value = String(key || "")
  if (STANDARD_COLUMN_NAMES[value]) return "standard"
  if (value.startsWith("property_")) return "property"
  if (value.startsWith("extra_")) return "extra"
  return "other"
}

/** @returns {string | null} */
export const columnType = (key, propertyEntries = [], extraColumns = []) => {
  const source = columnSource(key)

  if (source === "standard") return STANDARD_COLUMN_TYPES[key] || null

  if (source === "property") {
    const entry = entryForKey(key, propertyEntries)
    if (entry) return uiTypeForEntry(entry)

    const match = String(key || "").match(/^property_(string|integer|decimal|boolean|datetime)_\d+$/)
    return match ? match[1] : null
  }

  if (source === "extra") {
    return entryForKey(key, extraColumns)?.type || null
  }

  return null
}

/** @returns {string} */
export const columnName = (key, propertyEntries = [], extraColumns = [], fallback = "") => {
  const source = columnSource(key)

  if (source === "standard") return translate(STANDARD_COLUMN_NAMES[key])

  if (source === "property") {
    return entryForKey(key, propertyEntries)?.name || fallback || String(key)
  }

  if (source === "extra") {
    return entryForKey(key, extraColumns)?.name || fallback || String(key)
  }

  return fallback || String(key)
}

/** @returns {string} */
export const columnTypeLabel = (type) => (type ? propertyTypeLabel(type) : "")

/** @returns {string} */
export const columnTypeIcon = (type) => (type ? propertyTypeIcon(type) : "help")

/** @returns {string} */
export const columnTypeTooltip = (type) =>
  type
    ? `${propertyTypeTooltip(type)} ${translate("Search and filter options depend on this type.")}`
    : translate("No type information is available for this column.")

/** @returns {string} */
export const columnSourceLabel = (source) => {
  if (source === "standard") return translate("Standard")
  if (source === "property" || source === "extra") return translate("Property Mapping")
  return translate("Other")
}

/** @returns {boolean} */
export const isSearchableColumn = (key) => {
  const value = String(key || "")
  return SEARCHABLE_STANDARD_KEYS.includes(value) || value.startsWith("property_string_")
}

/** @returns {Array<{ value: string, label: string }>} */
export const filterTypeOptions = (key, propertyEntries = [], extraColumns = []) => {
  // Extra columns are presentation-only today: the backend filter validator
  // does not resolve their type, so they must stay non-filterable.
  if (columnSource(key) === "extra") return []

  // Standard columns are filterable only when the Meilisearch index exposes them.
  if (columnSource(key) === "standard" && !FILTERABLE_STANDARD_KEYS.includes(String(key))) return []

  const type = columnType(key, propertyEntries, extraColumns)
  const options = []

  if (type === "integer" || type === "enum") {
    options.push({ value: "range", label: "Range" })
    if (entryForKey(key, propertyEntries)?.input_type === "select") {
      options.push({ value: "enum", label: "Choice list" })
    }
  } else if (type === "decimal") {
    options.push({ value: "range", label: "Range" })
  } else if (type === "boolean") {
    options.push({ value: "boolean", label: "Yes / No" })
  } else if (type === "datetime") {
    options.push({ value: "date", label: "Date" })
  }

  return options
}

/** @returns {boolean} */
export const canFilter = (key, propertyEntries = [], extraColumns = []) =>
  filterTypeOptions(key, propertyEntries, extraColumns).length > 0

/** @returns {Array} */
export const enumChoicesFor = (key, propertyEntries = []) =>
  enumOptionsFor(entryForKey(key, propertyEntries))

/** @returns {string} */
export const filterTypeLabel = (type) => (FILTER_LABELS[type] ? translate(FILTER_LABELS[type]) : translate("None"))

/** @returns {string} */
export const filterSummary = (col) => {
  const filter = col?.filter
  if (!filter?.type || !FILTER_LABELS[filter.type]) return translate("No filter")

  const parts = [ filterTypeLabel(filter.type) ]

  if (filter.type === "range" || filter.type === "date") {
    const count = Array.isArray(filter.buckets) ? filter.buckets.length : 0
    if (filter.type === "range") {
      parts.push(`${count} ${translate(count === 1 ? "bucket" : "buckets")}`)
    } else {
      parts.push(`${count} ${translate(count === 1 ? "year bucket" : "year buckets")}`)
    }
  }

  parts.push(translate(filter.active === false ? "Inactive" : "Active"))
  return parts.join(" · ")
}
