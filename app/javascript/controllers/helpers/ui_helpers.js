import Swal from 'sweetalert2';
import dayjs from 'dayjs';
import Toastify from 'toastify-js';
import { capitalize, isDefined } from "controllers/helpers/data_helpers" 

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
 * Formats a given time using dayjs.
 * @param {string | number | Date | dayjs.Dayjs} time - The time to format.
 * @param {string} [format="DD/MM/YYYY"] - The format string for dayjs.
 * @returns {string} The formatted time string.
 */
export const timeFormat = (time, format = "DD/MM/YYYY") => {
  return dayjs(time).format(format)
}

/**
 * Generates an HTML string for a status badge.
 * The color of the badge is determined by the status string.
 * @param {string} status - The status string (e.g., "active", "pending").
 * @returns {string} The HTML string for the badge, or an empty string if status is falsy.
 */
export const statusBadge = (status) => {
  if (!status) return ""
  const statusKey = String(status).toLowerCase()
  let color = "slate"

  switch (statusKey) {
    case "active":
    case "confirmed":
    case "completed":
    case "paid":
      color = "green"; break
    case "in_progress":
      color = "blue"; break
    case "pending":
    case "suspended":
      color = "yellow"; break
    case "deleted":
    case "failed":
    case "refunded":
    case "cancelled":
      color = "red"; break
  }

  const styles = {
    green: { badge: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800", dot: "bg-green-600" },
    slate: { badge: "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700", dot: "bg-slate-500" },
    yellow: { badge: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800", dot: "bg-yellow-600" },
    red: { badge: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800", dot: "bg-red-600" },
    blue: { badge: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800", dot: "bg-blue-600" }
  }

  const style = styles[color] || styles.slate
  const label = capitalize(statusKey.replace(/_/g, " "))

  return `
    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${style.badge}">
      <span class="w-1.5 h-1.5 rounded-full ${style.dot}"></span> ${label}
    </span>
  `
}

/**
 * Toggles the 'open' attribute on a given DOM element.
 * If the element has the attribute, it's removed. If not, it's added.
 * @param {HTMLElement} element - The element to toggle the attribute on.
 */
export const toggleOpenAttribute = (element) => {
  if (element.hasAttribute('open')) {
    element.removeAttribute('open')
  } else {
    element.setAttribute('open', '')
  }
}

/**
 * Adds a Stimulus action to an element's 'data-action' attribute, preventing duplicates.
 * @param {HTMLElement} element - The element to add the action to.
 * @param {string} action - The action string to add (e.g., "click->controller#action").
 */
export const addAction = (element, action) => {
  const existingActions = element.getAttribute("data-action") || "";
  const actionSet = new Set(existingActions.split(" ").filter(Boolean));
  actionSet.add(action);
  element.setAttribute("data-action", Array.from(actionSet).join(" "));
}

/**
 * Adds a value to a space-separated attribute on an element, preventing duplicates.
 * @param {HTMLElement} element - The element to modify.
 * @param {string} attribute - The attribute name (e.g., "data-my-attribute").
 * @param {string} value - The value to add to the attribute.
 */
export const addAttribute = (element, attribute, value) => {
  const existingAttributes = element.getAttribute(attribute) || "";
  const attributeSet = new Set(existingAttributes.split(" ").filter(Boolean));
  attributeSet.add(value);
  element.setAttribute(attribute, Array.from(attributeSet).join(" "));
}

/**
 * Opens a SweetAlert2 modal.
 * @param {object} config - The configuration for the modal.
 * @param {string} [config.html="Model!"] - The HTML content of the modal.
 * @param {object} [config.customClass={}] - Custom classes for the modal elements.
 * @param {object} [config.options={}] - Other SweetAlert2 options.
 */
export const openModal = ({html = "Model!", customClass = {}, options = {}}) => {
  Swal.fire({
    html: html,
    showConfirmButton: false,
    showCloseButton: false,
    backdrop: true,
    target: document.querySelector('main'),
    customClass: {
      container: '!bg-transparent',
      popup: '!p-0 !bg-transparent !w-fit',
      htmlContainer: '!p-0 !overflow-visible',
      ...customClass
    },
    ...options,
  });
}

/**
 * Opens a SweetAlert2 popover positioned relative to a parent element.
 * @param {object} config - The configuration for the popover.
 * @param {HTMLElement} config.parentElement - The element to position the popover against.
 * @param {string} [config.html="Dialog content"] - The HTML content of the popover.
 * @param {('top-left'|'top-right'|'top-center'|'bottom-left'|'bottom-right'|'bottom-center'|'left-center'|'right-center'|'center-center')} [config.position='bottom-center'] - The position of the popover relative to the parent.
 * @param {string} [config.className=""] - Additional CSS classes for the popover.
 */
export const openPopover = ({parentElement, html = "Dialog content", position = 'bottom-center', className = ""}) => {
  const parentRect = parentElement.getBoundingClientRect();
  const parentTop = parentRect.top;
  const parentBottom = parentRect.bottom;
  const parentLeft = parentRect.left;
  const parentRight = parentRect.right;
  const parentWidth = parentRect.width;
  const parentHeight = parentRect.height;
    
  Swal.fire({
    html: html,
    position: 'top-start',
    showConfirmButton: false,
    showCloseButton: false,
    customClass: {
      container: '!bg-transparent',
      popup: ' swal2-container-custom w-fit! h-fit! p-0! rounded-none! bg-transparent! ' + className,
      htmlContainer: '!p-0',
    },
    showClass: { popup: `animate__animated animate__fadeInUp animate__faster` },
    hideClass: { popup: `animate__animated animate__fadeOutDown animate__faster` },
    didOpen: (popupElement) => {
      const swalContainer = document.querySelector('.swal2-container-custom');
      swalContainer.style.position = 'absolute';
      
      switch (position) {
        case 'top-left':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'top-right':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'top-center':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
        case 'bottom-left':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'bottom-right':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'bottom-center':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
        case 'left-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'right-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'center-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
      }
    },
  });
}

/**
 * Closes any open SweetAlert2 modal or popover.
 */
export const closeSwal = () => Swal.close()

/**
 * Closes any open SweetAlert2 modal or popover. Alias for closeSwal.
 */
export const closeModal = () => Swal.close()

export const closeModalAction = () => `data-action="click->modal#close"`

/**
 * Returns the data-controller attribute string for the darkmode controller.
 * @returns {string} `data-controller="darkmode"`
 */
export const darkmodeTrigger = () => `data-darkmode-target="trigger"`

/**
 * Returns the data-link-target attribute string for opening links by pathname.
 * @returns {string} `data-link-target="openByPathname"`
 */
export const openByPathname = () => `data-link-target="openByPathname"`

/**
 * Returns a data-language-key attribute string for translation.
 * @param {string} key - The translation key.
 * @returns {string} `data-language-key="..."`
 */
export const translate = (key) => `data-language-key="${key}"`

/**
 * Returns the data-language-target attribute string for the language dropdown trigger.
 * @returns {string} `data-language-target="triggerDropdown"`
 */
export const triggerLanguageDropdown = () => `data-language-target="triggerDropdown"`

/**
 * Returns the data-language-target attribute string for the language code text.
 * @returns {string} `data-language-target="codeText"`
 */
export const languageCodeTextTarget = () => `data-language-target="codeText"`

/**
 * Returns the data attributes for a Stimulus 'open' controller trigger.
 * @param {string} key - The key to identify a group of listeners.
 * @param {string|number} index - The index to identify a specific listener within the group.
 * @returns {string} The full data attribute string for an open trigger.
 */
export const addOpenTrigger = (key, index) => `data-open-target="trigger" data-action="click->open#click" data-open-key-param="${key}" data-open-index-param="${index}"`

/**
 * Returns the data attributes for a Stimulus 'open' controller listener.
 * @param {string} key - The key to identify this listener group.
 * @param {string|number} index - The index to uniquely identify this listener.
 * @returns {string} The full data attribute string for an open listener.
 */
export const addOpenListener = (key, index) => `data-open-target="listener" data-open-key-param="${key}" data-open-index-param="${index}"`

export const pagination = (dataValue, classNames = "") => `
  <div
    class="${classNames}"
    data-controller="pagination"
    data-pagination-data-value='${JSON.stringify(dataValue)}' 
  >
  </div>
`

/**
 * Displays a themed toast notification using Tailwind CSS classes.
 * @param {object} options 
 * @param {('success'|'error'|'info'|'warning'|'normal')} options.type - The status type.
 * @param {string} options.message - The text to display.
 */
export const toast = ({ type = "normal", message = "" }) => {
  const themes = {
    success: "bg-green-600 text-white border-green-700 shadow-lg",
    error:   "bg-red-600 text-white border-red-700 shadow-lg",
    info:    "bg-blue-600 text-white border-blue-700 shadow-lg",
    warning: "bg-amber-500 text-white border-amber-600 shadow-lg",
    normal:  "bg-slate-800 text-white border-slate-900 shadow-lg"
  }

  const themeClasses = themes[type] || themes.normal

  Toastify({
    text: message || (type === "success" ? "Success!" : "Notice"),
    duration: 3000,
    gravity: "top",
    position: "right",
    stopOnFocus: true,
    // Inject Tailwind classes here. Note: we reset 'style' to empty 
    // to prevent Toastify's default vanilla styles from interfering.
    className: `rounded-lg px-4 py-3 border font-medium ${themeClasses}`,
    style: { background: "unset" } 
  }).showToast();
}

/**
 * Generates a Rails-compatible form wrapper.
 * @param {object} options
 * @param {string} [options.action=pathname()] - Form action URL.
 * @param {string} [options.method="POST"] - HTTP method.
 * @param {string} [options.dataController="form"] - The Stimulus controller to attach. Pass null to skip.
 * @param {string} [options.dataAction="submit->form#submit"] - Stimulus actions.
 * @param {string} [options.className="flex flex-col gap-4"] - Tailwind CSS classes.
 * @param {string} [options.html=""] - Inner HTML content.
 * @returns {string} The HTML form string.
 */
export const form = ({ 
  action = pathname(), 
  method = "POST", 
  dataController = "form",
  dataAction = "submit->form#submit", 
  // className = "flex flex-col gap-4",
  className = "", 
  html = "" 
}) => {
  const upperMethod = method.toUpperCase()
  const isGet = upperMethod === "GET"
  
  let methodTags = ""
  let formMethod = upperMethod

  // Rails method spoofing & CSRF
  if (!isGet) {
    formMethod = "POST"
    if (upperMethod === "PATCH") {
      methodTags = formPatchSecurityTags()
    } else if (upperMethod === "DELETE") {
      methodTags = `<input type="hidden" name="_method" value="delete" autocomplete="off">` + formPostSecurityTags()
    } else {
      methodTags = formPostSecurityTags()
    }
  }

  // Conditional Controller & Action strings
  const controllerAttr = dataController ? `data-controller="${dataController}"` : ""
  const actionAttr = (dataController && dataAction) ? `data-action="${dataAction}"` : ""

  return `
    <form 
      action="${action}" 
      method="${formMethod}" 
      ${controllerAttr}
      ${actionAttr}
      class="${className}"
    >
      ${methodTags}
      ${html}
    </form>
  `
}