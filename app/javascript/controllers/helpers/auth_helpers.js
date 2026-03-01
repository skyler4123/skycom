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
    let [k,v] = el.split('=');
    if (!k) return;
    let value = decodeURIComponent(v);
    value = value.replace("+", ' ');
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
 * Retrieves the list of companies from the 'companies' cookie.
 * @returns {Array<object>} An array of company group objects.
 */
export const currentCompanies = () => {
  const c = Cookie('companies');
  return c ? JSON.parse(c) : [];
}

export const currentUser = () => {
  const c = Cookie('current_user');
  return c ? JSON.parse(c) : null;
}

export const currentCompany = () => {
  const companies = currentCompanies();
  const currentPath = pathname();

  if (!Array.isArray(companies)) {
    return null;
  }
  return companies.find(group => currentPath.includes(String(group.id)));
}


/**
 * Checks if the user is signed in based on the 'is_signed_in' cookie.
 * @returns {boolean} True if signed in, false otherwise.
 */
export const isSignedIn = () => {
  return Cookie('is_signed_in') && Cookie('is_signed_in') === 'true'
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
