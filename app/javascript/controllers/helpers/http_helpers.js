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
export const formPostSecurityTags = () => {
  const csrf = csrfToken()
  return `<input type="hidden" name="authenticity_token" value="${csrf}" autocomplete="off">`
}

/**
 * Generates HTML strings for hidden input fields to simulate a PATCH method and include the CSRF token.
 * @returns {string} The HTML string for the hidden inputs.
 */
export const formPatchSecurityTags = () => {
  const csrf = csrfToken()
  return `
    <input type="hidden" name="_method" value="patch" autocomplete="off">
    <input type="hidden" name="authenticity_token" value="${csrf}" autocomplete="off">
  `
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
 * Generates a Rails-compatible form wrapper.
 * * @param {object} options
 * @param {string} [options.action=pathname()] - Form action URL.
 * @param {string} [options.method="POST"] - HTTP method (GET, POST, PATCH, DELETE).
 * @param {string} [options.dataAction=""] - Stimulus actions (e.g. "submit->controller#submit").
 * @param {string} [options.className=""] - CSS classes.
 * @param {string} [options.html=""] - Inner HTML content (fields).
 * @returns {string} The HTML form string.
 */
export const form = ({ 
  action = pathname(), 
  method = "POST", 
  dataAction = "", 
  className = "", 
  html = "" 
}) => {
  const upperMethod = method.toUpperCase()
  const isGet = upperMethod === "GET"
  
  // Rails method spoofing
  let methodTags = ""
  let formMethod = upperMethod

  if (!isGet) {
    formMethod = "POST" // Browser forms only support GET/POST
    if (upperMethod === "PATCH") {
      methodTags = formPatchSecurityTags()
    } else if (upperMethod === "DELETE") {
      methodTags = `<input type="hidden" name="_method" value="delete" autocomplete="off">` + formPostSecurityTags()
    } else {
      methodTags = formPostSecurityTags()
    }
  }

  return `
    <form 
      action="${action}" 
      method="${formMethod}" 
      data-action="${dataAction}" 
      class="${className}"
    >
      ${methodTags}
      ${html}
    </form>
  `
}