// Dynamic sidebar (custom groups) reader — company-setting level.
//
// Source record: the company-level Setting with code DYNAMIC_SIDEBAR_CODE
// (BE constant in config/initializers/constants.rb, value "DYNAMIC_SIDEBAR").
// Its metadata.sidebar_groups = [{ key, name, items: [{ key, name, url }] }].
// Custom groups render ABOVE the static SIDEBAR_GROUPS in
// companies/sidebars/show_controller.js (see docs/SIDEBAR.md).
//
// Key namespacing: custom group keys are `custom_<slug>`, item keys are
// `custom_item_<slug>`, so favourites + open-group localStorage entries can
// never collide with static SIDEBAR_ITEMS keys.

// Mirrors the BE DYNAMIC_SIDEBAR_CODE value (see comment above).
export const DYNAMIC_SIDEBAR_CODE = "DYNAMIC_SIDEBAR"

export const customSidebarRecord = () => {
  const settings = (typeof currentSettings === "function" ? currentSettings() : []) || []
  return settings.find((s) => s.code === DYNAMIC_SIDEBAR_CODE) || null
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

export const customSidebarGroups = () => {
  const record = customSidebarRecord()
  const raw = record?.metadata?.sidebar_groups || record?.sidebar_groups || []
  if (!Array.isArray(raw)) return []

  return raw
    .filter((g) => g && String(g.name ?? "").trim() !== "")
    .map((g, gi) => {
      const groupKey = `custom_${slugify(g.key || g.name, `group-${gi}`)}`
      const itemsRaw = Array.isArray(g.items) ? g.items : []
      const items = itemsRaw
        .filter((item) => item && String(item.name ?? "").trim() !== "" && isSafeUrl(item.url))
        .map((item, ii) => ({
          key: `custom_item_${slugify(item.key || item.name, `item-${ii}`)}`,
          group: groupKey,
          icon: "link",
          label: String(item.name),
          href: (_cid) => String(item.url),
          custom: true
        }))
      return { key: groupKey, label: String(g.name), items, custom: true }
    })
}

export const customSidebarItems = () => customSidebarGroups().flatMap((g) => g.items)
