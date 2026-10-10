// Per-employee sidebar favourites + group open-state, stored in localStorage.
// Keys are scoped by company + user so two employees sharing one browser never
// see each other's stars. Plain flat keys (same pattern as "open-cache-sidebar" /
// "languageCode") so ClientCacheController.sync() never touches them. New
// browser/laptop = empty lists by design (browser-level config, see docs/SIDEBAR.md).
// Legacy per-company keys (without user suffix) are migrated once on first read.

const favouritesKey = (companyId, userId) => userId
  ? `sidebar_favourites_${companyId}_${userId}`
  : `sidebar_favourites_${companyId}`
const legacyFavouritesKey = (companyId) => `sidebar_favourites_${companyId}`
const openGroupsKey = (companyId, userId) => userId
  ? `sidebar_open_groups_${companyId}_${userId}`
  : `sidebar_open_groups_${companyId}`
const legacyOpenGroupsKey = (companyId) => `sidebar_open_groups_${companyId}`

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

const readWithMigration = (key, legacyKey) => {
  const current = read(key)
  if (current.length > 0 || !legacyKey || key === legacyKey) return current
  const legacy = read(legacyKey)
  if (legacy.length > 0) write(key, legacy)
  return legacy
}

/** @returns {string[]} favourite item keys for the company + user */
export const favourites = (companyId, userId) => readWithMigration(
  favouritesKey(companyId, userId), userId ? legacyFavouritesKey(companyId) : null
)

export const isFavourite = (companyId, key, userId) => favourites(companyId, userId).includes(key)

/** Toggles the key; returns the new list. */
export const toggleFavourite = (companyId, key, userId) => {
  const current = favourites(companyId, userId)
  const next = current.includes(key) ? current.filter(k => k !== key) : [...current, key]
  write(favouritesKey(companyId, userId), next)
  return next
}

/** @returns {string[]} keys of groups currently open */
export const openGroups = (companyId, userId) => readWithMigration(
  openGroupsKey(companyId, userId), userId ? legacyOpenGroupsKey(companyId) : null
)

export const isGroupOpen = (companyId, key, userId) => openGroups(companyId, userId).includes(key)

export const setGroupOpen = (companyId, key, open, userId) => {
  const current = openGroups(companyId, userId)
  const next = open ? [...new Set([...current, key])] : current.filter(k => k !== key)
  write(openGroupsKey(companyId, userId), next)
  return next
}
