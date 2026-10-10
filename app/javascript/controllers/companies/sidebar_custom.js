// Dynamic sidebar (custom groups) reader — company-setting level + personal level.
//
// Source records:
// - Shared: the company-level Setting with code DYNAMIC_SIDEBAR_CODE
//   (BE constant in config/initializers/constants.rb, value "DYNAMIC_SIDEBAR").
//   Its metadata.sidebar_groups = [{ key, name, items: [{ key, name, url }] }].
// - Personal: the employee-level Setting with code PERSONAL_SIDEBAR_CODE
//   (value "PERSONAL_SIDEBAR", appoint_to = current employee), read from the
//   top-level personal_settings client-cache payload. Same shape.
// Shared groups render first, then personal, then static SIDEBAR_GROUPS in
// companies/sidebars/show_controller.js (see docs/SIDEBAR.md).
//
// Key namespacing: shared group keys are `custom_<slug>`, personal group keys
// are `personal_<slug>` (items `custom_item_` / `personal_item_`), so
// favourites + open-group localStorage entries can never collide with static
// SIDEBAR_ITEMS keys or with each other.

// Mirrors the BE DYNAMIC_SIDEBAR_CODE / PERSONAL_SIDEBAR_CODE values (see comment above).
export const DYNAMIC_SIDEBAR_CODE = "DYNAMIC_SIDEBAR"
export const PERSONAL_SIDEBAR_CODE = "PERSONAL_SIDEBAR"

export const customSidebarRecord = () => {
  const settings = (typeof currentSettings === "function" ? currentSettings() : []) || []
  return settings.find((s) => s.code === DYNAMIC_SIDEBAR_CODE) || null
}

export const personalSidebarRecord = () => {
  if (typeof currentPersonalSetting === "function") {
    const direct = currentPersonalSetting()
    if (direct) return direct
  }
  const all = (typeof currentPersonalSettings === "function" ? currentPersonalSettings() : null)
    ?? (typeof getCache === "function" ? (getCache().personal_settings || []) : [])
  if (!Array.isArray(all)) return null
  const employeeId = (typeof currentEmployeeId === "function" ? currentEmployeeId() : null)
    || (typeof currentUser === "function" ? null : null)
  if (employeeId) {
    return all.find((s) => s.code === PERSONAL_SIDEBAR_CODE && String(s.appoint_to_id) === String(employeeId)) || null
  }
  return all.find((s) => s.code === PERSONAL_SIDEBAR_CODE) || null
}

const slugify = (value, fallback) => {
  const slug = String(value ?? "").trim().toLowerCase()
    .replace(/[^a-z0-9-_]+/g, "-").replace(/^-+|-+$/g, "")
  return slug || fallback
}

const isSafeUrl = (url) => {
  const trimmed = String(url ?? "").trim()
  return trimmed !== "" && !trimmed.toLowerCase().startsWith("javascript:")
}

export const customSidebarGroups = () => groupsFromRecord(customSidebarRecord(), "custom", "custom_item")

export const customSidebarItems = () => customSidebarGroups().flatMap((g) => g.items)

export const personalSidebarGroups = () => groupsFromRecord(personalSidebarRecord(), "personal", "personal_item")

export const personalSidebarItems = () => personalSidebarGroups().flatMap((g) => g.items)

const groupsFromRecord = (record, groupPrefix, itemPrefix) => {
  const raw = record?.metadata?.sidebar_groups || record?.sidebar_groups || []
  if (!Array.isArray(raw)) return []

  return raw
    .filter((g) => g && String(g.name ?? "").trim() !== "")
    .map((g, gi) => {
      const groupKey = `${groupPrefix}_${slugify(g.key || g.name, `group-${gi}`)}`
      const itemsRaw = Array.isArray(g.items) ? g.items : []
      const items = itemsRaw
        .filter((item) => item && String(item.name ?? "").trim() !== "" && isSafeUrl(item.url))
        .map((item, ii) => ({
          key: `${itemPrefix}_${slugify(item.key || item.name, `item-${ii}`)}`,
          group: groupKey,
          icon: "link",
          label: String(item.name),
          href: (_cid) => String(item.url),
          custom: true
        }))
      return { key: groupKey, label: String(g.name), items, custom: true }
    })
}
