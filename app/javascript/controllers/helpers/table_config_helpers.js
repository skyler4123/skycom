// Shared presentation helpers for the Table Config editor and show page.
// Column labels are never edited here: standard and computed labels come from
// the resource catalog sent by the backend, property/extra labels come from the
// Property Mapping. See docs/COMPUTED_COLUMNS.md.
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
  pending: "Pending"
}

// Keep in sync with TableConfig::STANDARD_COLUMN_TYPES (app/models/table_config.rb).
export const STANDARD_COLUMN_TYPES = {
  name: "string",
  description: "string",
  code: "string",
  title: "string",
  quantity: "integer",
  pending: "integer"
}

const SEARCHABLE_STANDARD_KEYS = [ "name", "description", "code", "title" ]

const FILTER_LABELS = {
  range: "Range",
  enum: "Choice list",
  boolean: "Yes / No",
  date: "Date"
}

/** @returns {object | null} */
const entryForKey = (key, entries = []) =>
  (entries || []).find((entry) => entry?.key === key) || null

/**
 * Source resolution mirrors the backend (TableConfig#column_source):
 * a real DB column wins over a computed method with the same key.
 *
 * @param {string} key
 * @param {{ standard?: Array<object> | null, computed?: Array<object> }} [catalog]
 * @returns {"standard" | "computed" | "property" | "extra" | "other"}
 */
export const columnSource = (key, catalog = {}) => {
  const value = String(key || "")
  const standard = Array.isArray(catalog.standard) ? catalog.standard : null
  const computed = catalog.computed || []

  if (standard) {
    if (entryForKey(value, standard)) return "standard"
    if (entryForKey(value, computed)) return "computed"
    if (value.startsWith("property_")) return "property"
    if (value.startsWith("extra_")) return "extra"
    return "other"
  }

  // Legacy fallback for configs rendered before the server catalog existed.
  if (STANDARD_COLUMN_NAMES[value]) return "standard"
  if (value.startsWith("property_")) return "property"
  if (value.startsWith("extra_")) return "extra"
  return "other"
}

/** @returns {string | null} */
export const columnType = (key, propertyEntries = [], extraColumns = [], catalog = {}) => {
  const value = String(key || "")
  const source = columnSource(value, catalog)

  if (source === "standard") {
    return entryForKey(value, catalog.standard || [])?.type || STANDARD_COLUMN_TYPES[value] || null
  }

  if (source === "computed") {
    return entryForKey(value, catalog.computed || [])?.type || null
  }

  if (source === "property") {
    const entry = entryForKey(value, propertyEntries)
    if (entry) return uiTypeForEntry(entry)

    const match = value.match(/^property_(string|integer|decimal|boolean|datetime)_\d+$/)
    return match ? match[1] : null
  }

  if (source === "extra") {
    return entryForKey(value, extraColumns)?.type || null
  }

  return null
}

/** @returns {string} */
export const columnName = (key, propertyEntries = [], extraColumns = [], fallback = "", catalog = {}) => {
  const value = String(key || "")
  const source = columnSource(value, catalog)

  if (source === "standard") {
    const entry = entryForKey(value, catalog.standard || [])
    return translate(entry?.name || STANDARD_COLUMN_NAMES[value] || fallback || value)
  }

  if (source === "computed") {
    const entry = entryForKey(value, catalog.computed || [])
    return translate(entry?.name || fallback || value)
  }

  if (source === "property") {
    return entryForKey(value, propertyEntries)?.name || fallback || value
  }

  if (source === "extra") {
    return entryForKey(value, extraColumns)?.name || fallback || value
  }

  return fallback || value
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
  if (source === "computed") return translate("Computed")
  if (source === "property" || source === "extra") return translate("Property Mapping")
  return translate("Other")
}

/** @returns {boolean} */
export const isSearchableColumn = (key, catalog = {}) => {
  const value = String(key || "")
  const source = columnSource(value, catalog)

  if (source === "computed" || source === "extra" || source === "other") return false
  if (source === "property") return value.startsWith("property_string_")

  return SEARCHABLE_STANDARD_KEYS.includes(value)
}

/** @returns {Array<{ value: string, label: string }>} */
export const filterTypeOptions = (key, propertyEntries = [], extraColumns = [], catalog = {}) => {
  // Computed and extra columns are presentation-only: the backend filter
  // validator does not allow them.
  const source = columnSource(key, catalog)
  if (source === "computed" || source === "extra" || source === "other") return []

  const type = columnType(key, propertyEntries, extraColumns, catalog)
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
export const canFilter = (key, propertyEntries = [], extraColumns = [], catalog = {}) =>
  filterTypeOptions(key, propertyEntries, extraColumns, catalog).length > 0

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
