import { isDefined } from "controllers/helpers/data_helpers" // Optional: if you want to keep strict modularity

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

export const csrfToken = () => {
  const csrf = document.querySelector('meta[name="csrf-token"]')
  return csrf ? csrf.content : ""
}

export const csrfTokenTag = () => {
  const csrf = csrfToken()
  return `<input type="hidden" name="authenticity_token" value="${csrf}" autocomplete="off">`
}

export const pathFormTag = () => {
  return `<input type="hidden" name="_method" value="patch" autocomplete="off">`
}

export const pathname = () => window.location.pathname
export const href = () => window.location.href
export const origin = () => window.location.origin

export const poll = (callback, { interval = 100, maxAttempts = 10 } = {}) => {
  let attempts = 0;
  const intervalId = setInterval(() => {
    attempts++;
    if (callback() === true || attempts >= maxAttempts) {
      clearInterval(intervalId);
    }
  }, interval);
};
