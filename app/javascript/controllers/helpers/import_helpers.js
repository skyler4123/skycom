// Shared presentation rules for the Import pages.
//
// The CSV header itself must stay exact (it is what the user types into the
// file), but everything around it is shown in a manager's words: friendly
// target names, friendly types, short meanings, and example values. Raw
// storage keys such as `property_string_1` never leave this module.
//
// Docs: docs/IMPORT.md
import { translate } from "controllers/helpers/ui_helpers"
import {
  propertyTypeIcon,
  propertyTypeLabel,
  propertyTypeTooltip
} from "controllers/helpers/property_mapping_helpers"

// Friendly plural labels for the allowlisted target tables. The keys must
// match IMPORTABLE_RESOURCES (the raw table name is only ever a form value).
export const IMPORTABLE_RESOURCE_LABELS = {
  branches: "Branches",
  brands: "Brands",
  customer_profiles: "Customer profiles",
  customer_subprofiles: "Customer subprofiles",
  customers: "Customers",
  departments: "Departments",
  employee_profiles: "Employee profiles",
  employee_subprofiles: "Employee subprofiles",
  employees: "Employees",
  facilities: "Facilities",
  products: "Products",
  services: "Services",
  suppliers: "Suppliers",
  warehouses: "Warehouses"
}

// Short "what it means" copy for standard model columns. Property columns use
// the display name the manager already gave them in Property Mapping.
const COLUMN_MEANINGS = {
  name: "The record's display name.",
  description: "An optional note about this record.",
  code: "A short internal code for this record.",
  title: "A short title for this record.",
  email: "The contact email address.",
  phone_number: "The contact phone number.",
  business_type: "What kind of business this record belongs to.",
  lifecycle_status: "Whether the record is active, inactive, or archived.",
  workflow_status: "The record's workflow state.",
  expiration_date: "When this record expires.",
  external_id: "An ID from another system.",
  price_cents: "Price in the smallest currency unit (for example, cents).",
  quantity: "How many units.",
  currency: "Three-letter currency code.",
  country: "Country code.",
  timezone: "Timezone name.",
  pending: "A pending quantity or count.",
  type: "The record type.",
  lock_version: "Internal version number."
}

const COLUMN_LABELS = {
  name: "Name",
  description: "Description",
  code: "Code",
  title: "Title",
  email: "Email",
  phone_number: "Phone number",
  business_type: "Business type",
  lifecycle_status: "Status",
  workflow_status: "Workflow status",
  expiration_date: "Expires on",
  external_id: "External ID",
  price_cents: "Price (in cents)",
  quantity: "Quantity",
  currency: "Currency",
  country: "Country",
  timezone: "Timezone",
  pending: "Pending",
  type: "Type",
  lock_version: "Version"
}

const TYPE_LABELS = {
  uuid: "Link (ID)"
}

const TYPE_ICONS = {
  uuid: "link"
}

const TYPE_TOOLTIPS = {
  uuid: "A unique ID that links to another record.",
  enum: "Choose one of the listed values."
}

/** @returns {string} */
const humanize = (value) =>
  String(value || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (character) => character.toUpperCase())
    .trim()

// Association model names are CamelCase ("CustomerProfile"); split them so
// the meaning reads like a person wrote it.
/** @returns {string} */
const humanizeModel = (value) =>
  humanize(String(value || "").replace(/([a-z0-9])([A-Z])/g, "$1 $2"))

/** @returns {string} */
export const targetTableLabel = (table) =>
  translate(IMPORTABLE_RESOURCE_LABELS[table] || humanize(table))

/** @returns {string} */
export const columnDisplayName = (header, entry = {}) => {
  if (entry.kind === "property") return header
  if (entry.association?.model) return humanizeModel(entry.association.model)
  return translate(COLUMN_LABELS[header] || humanize(header))
}

/** @returns {string} */
export const columnMeaning = (header, entry = {}) => {
  if (entry.kind === "property") {
    return translate("A field from this category's property setup.")
  }

  if (entry.association?.model) {
    return `${translate("Link to a")} ${humanizeModel(entry.association.model)}. ${translate("Enter the record's ID.")}`
  }

  return translate(COLUMN_MEANINGS[header] || "A value for this column.")
}

/** @returns {string} */
export const columnTypeLabel = (type, entry = {}) => {
  if (entry.association) return translate(TYPE_LABELS.uuid)
  if (type === "uuid") return translate(TYPE_LABELS.uuid)
  return propertyTypeLabel(type)
}

/** @returns {string} */
export const columnTypeIcon = (type, entry = {}) => {
  if (entry.association) return TYPE_ICONS.uuid
  if (type === "uuid") return TYPE_ICONS.uuid
  return propertyTypeIcon(type)
}

/** @returns {string} */
export const columnTypeTooltip = (type, entry = {}) => {
  if (entry.association || type === "uuid") return translate(TYPE_TOOLTIPS.uuid)

  if (type === "enum") {
    const values = entry.enum || []
    if (values.length === 0) return translate(TYPE_TOOLTIPS.enum)

    const preview = values.slice(0, 8).join(", ")
    const more = values.length > 8 ? ` +${values.length - 8}` : ""
    return `${translate(TYPE_TOOLTIPS.enum)} ${preview}${more}`
  }

  return propertyTypeTooltip(type)
}

/** @returns {string} */
export const columnExample = (header, entry = {}, sampleRows = []) => {
  const sample = (sampleRows || []).find((row) => row && row[header] !== undefined && row[header] !== null && row[header] !== "")
  if (sample) return String(sample[header])

  const type = entry.association ? "uuid" : entry.type

  switch (type) {
    case "enum": {
      const values = entry.enum || []
      return String(values.includes("utc") ? "utc" : values[0] || "value")
    }
    case "uuid":
      return "00000000-0000-0000-0000-000000000000"
    case "boolean":
      return "true"
    case "datetime":
      return "2026-01-31T00:00:00Z"
    case "integer":
      return "0"
    case "decimal":
      return "0.00"
    default:
      return "Example text"
  }
}

/** @returns {string} */
export const requiredLabel = (required) =>
  required ? translate("Required") : translate("Optional")

/** @returns {string} */
export const statusBadgeClasses = (workflowStatus) => {
  switch (workflowStatus) {
    case "completed":
      return "bg-success/10 text-success"
    case "failed":
      return "bg-danger/10 text-danger"
    case "approved":
    case "processing":
    case "rolling_back":
      return "bg-primary/10 text-primary"
    default:
      return "bg-muted text-muted-foreground"
  }
}

/** @returns {string} */
export const statusLabel = (workflowStatus) => {
  const labels = {
    draft: translate("Draft"),
    approved: translate("Approved"),
    processing: translate("Processing"),
    completed: translate("Completed"),
    failed: translate("Failed"),
    rolling_back: translate("Rolling back"),
    rolled_back: translate("Rolled back")
  }
  return labels[workflowStatus] || workflowStatus
}

// The first step that still needs the manager's attention.
/** @returns {number} */
export const activeStep = (importRecord) => {
  if (!importRecord) return 1
  if (importRecord.setup_locked) return 4
  if (!importRecord.schema) return 1
  if (!importRecord.source_filename) return 2
  if (importRecord.dry_run_result?.passed !== true) return 3
  return 4
}

/**
 * One of "done" | "current" | "next" | "locked".
 * "next" means the step is available but the previous step is the primary
 * action (for example, upload is ready while the manager is still preparing
 * the file).
 * @returns {string}
 */
export const stepState = (importRecord, step) => {
  if (!importRecord) return step === 1 ? "current" : "locked"
  if (importRecord.setup_locked) return step === 4 ? "current" : "done"

  const schemaReady = Boolean(importRecord.schema)
  const hasFile = Boolean(importRecord.source_filename)
  const checkPassed = importRecord.dry_run_result?.passed === true

  if (step === 1) return schemaReady ? "done" : "current"
  if (step === 2) return schemaReady ? (hasFile ? "done" : "current") : "locked"
  if (step === 3) {
    if (!schemaReady) return "locked"
    if (checkPassed) return "done"
    return hasFile ? "current" : "next"
  }

  return checkPassed ? "current" : "locked"
}

/** @returns {string} */
export const stepStateLabel = (state) => {
  const labels = {
    done: "Done",
    current: "Next",
    next: "Ready",
    locked: "Locked"
  }
  return translate(labels[state] || "Locked")
}

/** @returns {string} */
export const stepLockedReason = (step) => {
  if (step === 4) return translate("Upload and check your file first.")
  return translate("Save step 1 first.")
}

const csvCell = (value) => {
  const text = String(value ?? "")
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}

/** Builds a starter CSV with the exact headers and one example/blank row. */
export const generateStarterCsv = (schema, sampleRows = []) => {
  const headers = (schema?.headers || []).map((entry) => entry.header)
  const sample = (sampleRows || [])[0] || {}
  const row = headers.map((header) => sample[header] ?? "")
  return [ headers, row ].map((cells) => cells.map(csvCell).join(",")).join("\n")
}

/** Builds a CSV of the row numbers and errors from a dry run. */
export const generateProblemRowsCsv = (dryRunResult) => {
  const rows = dryRunResult?.row_errors || []
  const lines = [
    [ translate("Row"), translate("Errors") ],
    ...rows.map((row) => [ row.row, (row.errors || []).join(" ") ])
  ]
  return lines.map((cells) => cells.map(csvCell).join(",")).join("\n")
}

/** Triggers a browser download for a CSV string. */
export const downloadCsv = (filename, content) => {
  const blob = new Blob([ content ], { type: "text/csv;charset=utf-8;" })
  const url = URL.createObjectURL(blob)
  const link = document.createElement("a")
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  setTimeout(() => URL.revokeObjectURL(url), 0)
}
