// Per-company sidebar favourites + group open-state, stored in localStorage.
// Plain flat keys (same pattern as "open-cache-sidebar" / "languageCode") so
// ClientCacheController.sync() never touches them. New browser/laptop = empty
// lists by design (browser-level config, see docs/SIDEBAR.md).

const favouritesKey = (companyId) => `sidebar_favourites_${companyId}`
const openGroupsKey = (companyId) => `sidebar_open_groups_${companyId}`

const read = (key) => {
  try {
    return JSON.parse(localStorage.getItem(key)) || []
  } catch {
    return []
  }
}

const write = (key, value) => {
  localStorage.setItem(key, JSON.stringify(value))
}

/** @returns {string[]} favourite item keys for the company */
export const favourites = (companyId) => read(favouritesKey(companyId))

export const isFavourite = (companyId, key) => favourites(companyId).includes(key)

/** Toggles the key; returns the new list. */
export const toggleFavourite = (companyId, key) => {
  const current = favourites(companyId)
  const next = current.includes(key) ? current.filter(k => k !== key) : [...current, key]
  write(favouritesKey(companyId), next)
  return next
}

/** @returns {string[]} keys of groups currently open */
export const openGroups = (companyId) => read(openGroupsKey(companyId))

export const isGroupOpen = (companyId, key) => openGroups(companyId).includes(key)

export const setGroupOpen = (companyId, key, open) => {
  const current = openGroups(companyId)
  const next = open ? [...new Set([...current, key])] : current.filter(k => k !== key)
  write(openGroupsKey(companyId), next)
  return next
}
