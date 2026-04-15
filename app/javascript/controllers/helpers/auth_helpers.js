import { pathname } from "controllers/helpers/ui_helpers"

// --- Cookie Logic ---
/**
 * Retrieves a cookie value by name or returns all cookies as an object.
 * @param {string} [name] - The name of the cookie to retrieve.
 * @returns {string|object} The cookie value if name is provided, otherwise an object of all cookies.
 */
export const Cookie = (name) => {
  let cookie = {}
  document.cookie.split(';').forEach(function(el) {
    let [k, v] = el.split('=');
    if (!k || v === undefined) return;
    
    // 1. Replace ALL '+' with spaces first
    // 2. Then decode the URI components
    let value = decodeURIComponent(v.replace(/\+/g, ' '));
    
    cookie[k.trim()] = value;
  })
  
  if (name) {
    return cookie[name]
  } else {
    return cookie
  }
}

/**
 * Sets a cookie with a specified name, value, and expiration in days.
 * @param {string} name - The name of the cookie.
 * @param {string} value - The value of the cookie.
 * @param {number} [days] - Number of days until the cookie expires.
 */
export const setCookie = (name, value, days) => {
  let expires = ""
  if (days) {
    let date = new Date()
    date.setTime(date.getTime() + (days*24*60*60*1000))
    expires = "; expires=" + date.toUTCString()
  }
  document.cookie = name + "=" + value + expires + "; path=/"
}

/**
 * Removes a cookie by setting its expiration date to the past.
 * @param {string} name - The name of the cookie to remove.
 */
export const removeCookie = (name) => {
  // We set the date to Epoch (Jan 1, 1970) to ensure it is expired
  console.log(name)
  document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;"
}

export const getCache = () => {
  const raw = localStorage.getItem('client_cache_data')
  return raw ? JSON.parse(raw) : {}
}

export const currentCompanies = () => {
  return getCache().companies || []
}

export const currentCompany = () => {
  const companies = currentCompanies()
  const path = window.location.pathname
  return companies.find(c => path.includes(String(c.id))) || null
}

export const currentBranches = () => {
  return currentCompany()?.branches || []
}

export const currentDepartments = () => {
  return currentCompany().departments
}

export const currentRoles = () => {
  return currentCompany().roles
}

export const Enums =  () => {
  return getCache().enums
}
/**
 * Retrieves the current user profile from the client cache.
 * @returns {object|null} The user object (id, email, avatar, etc.) or null if not found.
 */
export const currentUser = () => {
  const cache = getCache(); // Uses the getCache helper we defined earlier
  return cache.user || null;
}

export const isSignedIn = () => {
  return Cookie('is_signed_in') && Cookie('is_signed_in') === 'true'
}
