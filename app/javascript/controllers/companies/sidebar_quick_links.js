// Dynamic sidebar (Quick Links) reader — company level only.
//
// Source record: the company's ACTIVE CompanySetting with
// business_type "sidebar_groups" (BE: app/models/company_setting.rb),
// read from currentSettings() (the company_settings client-cache payload).
// Its metadata.sidebar_groups = [{ key, name, items: [{ key, name, url }] }].
// The record is spread between Operations and My Profile by sidebarGroups()
// in companies/sidebars/show_controller.js (see docs/SIDEBAR.md).
//
// Key namespacing: group keys are `custom_<slug>` (items `custom_item_<slug>`),
// so favourites + open-group localStorage entries can never collide with static
// SIDEBAR_ITEMS keys.

export const quickLinksRecord = () => {
  const settings = (typeof currentSettings === "function" ? currentSettings() : []) || []
  const sidebar = settings.filter((s) => s.business_type === "sidebar_groups" || s.business_type === 0)
  return sidebar.find((s) => s.workflow_status === "active" || s.workflow_status === 1)
    || sidebar[0] || null
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

// Prefixes stay `custom_` / `custom_item_` for localStorage compatibility with
// saved favourites and open-group state.
export const quickLinksGroups = () => groupsFromRecord(quickLinksRecord(), "custom", "custom_item")

export const quickLinksItems = () => quickLinksGroups().flatMap((g) => g.items)

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
          quickLink: true
        }))
      return { key: groupKey, label: String(g.name), items, quickLink: true }
    })
}
