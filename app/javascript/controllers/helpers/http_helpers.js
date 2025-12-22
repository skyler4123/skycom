import { isDefined } from "controllers/helpers/data_helpers" // Optional: if you want to keep strict modularity

/**
 * Fetches JSON data from a URL with built-in support for query params, CSRF tokens, and JSON bodies.
 * Can be called as `fetchJson(url, options)` or `fetchJson(options)` (uses current URL).
 *
 * @param {string|object} url - The URL to fetch or the options object.
 * @param {object} [options={}] - Configuration options for the fetch request.
 * @param {object} [options.params] - Key-value pairs to be appended as query parameters.
 * @param {object} [options.headers] - Custom headers to include in the request.
 * @param {any} [options.body] - The request body. If an object (and not FormData), it's JSON stringified.
 * @returns {Promise<any>} A promise resolving to the JSON response or null (for 204).
 */
export const fetchJson = async (url, options = {}) => {
  if (typeof url === 'object' && url !== null) {
    options = url
    url = window.location.href
  } else if (!url) {
    url = window.location.href
  }

  const { params, headers = {}, body, method = "GET", ...rest } = options

  const requestUrl = new URL(url, window.location.origin)
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (isDefined(value) && value !== null) {
        requestUrl.searchParams.append(key, value)
      }
    })
  }

  const defaultHeaders = {
    "Accept": "application/json"
  }

  if (requestUrl.origin === window.location.origin) {
    defaultHeaders["X-CSRF-Token"] = csrfToken()
  }

  let requestBody = body
  if (body && !(body instanceof FormData) && typeof body === 'object') {
    defaultHeaders["Content-Type"] = "application/json"
    requestBody = JSON.stringify(body)
  }

  const config = {
    method,
    headers: { ...defaultHeaders, ...headers },
    body: requestBody,
    ...rest
  }

  try {
    const response = await fetch(requestUrl, config)
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    if (response.status === 204) return null
    return await response.json()
  } catch (error) {
    console.error("fetchJson error:", error)
    throw error
  }
}

/**
 * Retrieves the CSRF token from the meta tag in the document head.
 * @returns {string} The CSRF token or an empty string if not found.
 */
export const csrfToken = () => {
  const csrf = document.querySelector('meta[name="csrf-token"]')
  return csrf ? csrf.content : ""
}

/**
 * Generates an HTML string for a hidden input field containing the CSRF token.
 * Useful for injecting into forms.
 * @returns {string} The HTML string for the hidden input.
 */
export const csrfTokenTag = () => {
  const csrf = csrfToken()
  return `<input type="hidden" name="authenticity_token" value="${csrf}" autocomplete="off">`
}

/**
 * Generates an HTML string for a hidden input field to simulate a PATCH method.
 * @returns {string} The HTML string for the hidden input.
 */
export const pathFormTag = () => {
  return `<input type="hidden" name="_method" value="patch" autocomplete="off">`
}

/**
 * Returns the current window pathname.
 * @returns {string} window.location.pathname
 */
export const pathname = () => window.location.pathname

/**
 * Returns the current window href.
 * @returns {string} window.location.href
 */
export const href = () => window.location.href

/**
 * Returns the current window origin.
 * @returns {string} window.location.origin
 */
export const origin = () => window.location.origin

/**
 * Polls a callback function repeatedly until it returns true or max attempts are reached.
 * @param {Function} callback - The function to execute. Return `true` to stop polling.
 * @param {object} [options] - Polling configuration.
 * @param {number} [options.interval=100] - Time in ms between attempts.
 * @param {number} [options.maxAttempts=10] - Maximum number of times to call the callback.
 */
export const poll = (callback, { interval = 100, maxAttempts = 10 } = {}) => {
  let attempts = 0;
  const intervalId = setInterval(() => {
    attempts++;
    if (callback() === true || attempts >= maxAttempts) {
      clearInterval(intervalId);
    }
  }, interval);
};
