import { pathname } from "controllers/helpers/http_helpers"

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

/**
 * Retrieves the current user profile from the client cache.
 * @returns {object|null} The user object (id, email, avatar, etc.) or null if not found.
 */
export const currentUser = () => {
  const cache = getCache(); // Uses the getCache helper we defined earlier
  return cache.user || null;
}

export const isSignedIn = () => {
  return !!currentUser(); // Returns true if user data exists in LocalStorage
}

// --- Paths ---
/**
 * Returns the sign-in path.
 * @returns {string} "/sign_in"
 */
export const signInPath = () => `/sign_in`

/**
 * Returns the sign-up path.
 * @returns {string} "/sign_up"
 */
export const signUpPath = () => `/sign_up`

/**
 * Returns the sign-out path.
 * @returns {string} "/sign_out"
 */
export const signOutPath = () => `/sign_out`
