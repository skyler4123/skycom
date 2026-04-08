---
name: Skycom Project Guidelines - Part 1
description: Ruby on Rails Project Guidelines & Backend Standards
---

# 1. Ruby on Rails Project Guidelines

This is a standard Ruby on Rails 7+ application configured as a multi-tenant business management platform.

### Project Structure
- `app/models/` - ActiveRecord models (Heavy use of Concerns).
- `app/controllers/` - Controllers (JSON API style).
- `app/services/` - Global/complex cross-cutting business logic.
- `app/jobs/` - Background jobs using **Solid Queue** (PostgreSQL).
- `db/schema.rb` - Always check this first for columns and indexes.
- `app/javascript/controllers/` - Stimulus controllers (Frontend logic).

### Coding Conventions
- **Rails Conventions**: Stick to plural table names and standard RESTful routing.
- **Strict Logic Placement**: 
  - Business logic stays in **Models** or **Concerns** (e.g., `AddressConcern`, `RoleConcern`).
  - **Service Objects** are reserved for complex operations involving multiple models.
- **Data Flow**: Controllers handle `.json` requests. Avoid server-side HTML partials where possible; prefer JSON payloads for the Stimulus "Shell-First" architecture.
- **Safety**: Use `frozen_string_literal: true` and prefer `find_by!` or `find!` when a record is expected to exist.

### Database & Models
- **Database Setup**: PostgreSQL (Primary/Solid Queue), SQLite (Solid Cable/Solid Cache).
- **Associations**: Extensive use of **has_many through** + **polymorphic associations** via appointment-style join tables (e.g., `Employee` belongs to `Department` through `DepartmentAppointment`).
- **N+1 Prevention**: Use `includes`, `eager_load`, or `preload` by default for associated data.

### Rails Controller Naming Convention
Rails controllers must follow the URL nesting structure exactly:
- **URL**: `/companies/:company_id/employees`
- **Controller**: `class Companies::EmployeesController < Companies::ApplicationController`
- **Path**: `app/controllers/companies/employees_controller.rb`

---
name: Skycom Project Guidelines - Part 2
description: Hybrid SPA Architecture & Stimulus Naming Conventions
---

# 2. Skycom Architecture Manifesto (Hybrid SPA)

Skycom uses a **Shell-First Rendering** approach. The server returns a layout shell, and Stimulus controllers hydrate the page using JSON data.

### Tech Stack
- **Backend**: Rails (JSON API)
- **Frontend**: Stimulus + Tailwind CSS + ES6 Template Literals.
- **No Bundler**: Uses **Importmap** (no `node_modules`). Imports must use the importmap name, never relative paths.
  - *Correct*: `import Controller from "controllers/companies/layout_controller"`

### Stimulus Naming & Mapping (CRITICAL)
We maintain a strict mapping between Rails routes and Stimulus controllers to ensure architectural clarity.

1.  **Main Page Controllers**: 
    - A Rails `controller#action` should have a corresponding Stimulus controller.
    - **Naming**: Use **Pascal_Snake_Case**.
    - **Example**: For URL `/companies/:id/employees`, the controller in `app/javascript/controllers/companies/employees/index_controller.js` should be named `Companies_Employees_IndexController`.
2.  **Inheritance**:
    - Page controllers usually inherit from a Layout controller.
    - *Example*: `export default class Companies_EmployeesController extends Companies_LayoutController`
3.  **Support Controllers (Modals/Components)**:
    - Dedicated controllers handle specific UI actions within a view.
    - **Example**: `app/javascript/controllers/companies/employees/new_modal_controller.js` defines `Companies_Employees_NewModalController`.
    - **Backend Link**: This modal must map to a specific Rails action (e.g., `Companies::EmployeesController#create`).

### Stimulus Identifiers
- Generated via `window.identifier(Class)`.
- `Companies_Employees_IndexController` → `companies--employees--index`.
- Child controllers inherit all `static targets` from parents. **Do not redefine them.**

---
name: Skycom Project Guidelines - Part 3
description: Global JS Helpers and AI Prioritization Rules
---

# 3. Global JavaScript Helpers (window.*)

**AI MUST NOT suggest native `fetch()`, `$.ajax`, or plain `<form>` tags.** Use the global `window.Helpers` exposed in `app/javascript/application.js`.

### Core AJAX & Forms
1.  **`fetchJson(url|options, options)`**:
    - Automatically injects `X-CSRF-Token`.
    - Sets `Content-Type: application/json`.
    - Default URL is `window.location.href`.
2.  **`form({ action, method, dataAction, className, html })`**:
    - Defaults `action` to current `pathname()`.
    - Handles Rails **Method Spoofing** (PATCH/DELETE).
    - Injects CSRF `authenticity_token`.
3.  **Security Tags**:
    - `formPostSecurityTags()` / `formPatchSecurityTags()`: For manual HTML strings.

### Utility & UI Helpers
The following are available globally via the `Helpers` object:
- **Context**: `currentCompany`, `currentBranches`, `currentUser`, `isSignedIn`.
- **Navigation/URL**: `pathname()`, `href()`, `pagination(data)`.
- **UI**: `openModal(html)`, `closeModal()`, `openPopover()`, `toast(message, type)`.
- **Data Handling**: `isPresent(val)`, `isEmpty(val)`, `each(collection, callback)`, `map()`, `sort()`.
- **Storage**: `Cookie.set(name, value)`, `Cookie.get(name)`.

### Development Principles
- **Rendering**: Happens client-side in `contentHTML()` using ES6 Template Literals.
- **Encapsulation**: Use `new_modal_controller.js` to isolate logic for creation forms, ensuring they point back to the correct Rails RESTful action.
- **Identifiers**: Always use the underscored naming convention for file structure that matches the Pascal_Snake_Case class names.




here are some helpers:
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

import Swal from 'sweetalert2';
import dayjs from 'dayjs';
import Toastify from 'toastify-js';
import { capitalize } from "controllers/helpers/data_helpers" 

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

export const toast = (options = {}) => {
Toastify({
  text: options.text || "This is a toast",
  className: options.className || "",
  duration: options.duration || 3000,
  destination: options.destination || "https://github.com/apvarun/toastify-js",
  newWindow: options.newWindow || true,
  close: options.close || true,
  gravity: options.gravity || "top", // `top` or `bottom`
  position: options.position || "right", // `left`, `center` or `right`
  stopOnFocus: options.stopOnFocus || true, // Prevents dismissing of toast on hover
  style: {
    background: "linear-gradient(to right, #00b09b, #96c93d)",
    ...options.style
  },
  onClick: options.onClick || function(){} // Callback after click
}).showToast();
}

# config/routes.rb

Rails.application.routes.draw do
  resources :client_cache, only: [ :index ]
  resources :redirect do
    collection do
      get :companies
    end
  end
  resources :demo, only: [:index] do
    collection do
      get :calendar_events
    end
  end
  resources :companies do
    scope module: :companies do
      resources :branches
      resources :departments
      resources :products
      resources :services
      resources :orders
      resources :bookings
      resources :payments
      resources :employees
      resources :inventories
      resources :customers
      resources :invoices
      resources :schedules
      resources :attendances
      resources :reports
      resources :documents
      resources :announcements
      resources :discounts
      resources :events
      resources :payslips
      resources :tasks
      resources :facilities
      resources :settings
      resources :administrators do
        collection do
          patch :update_permission
        end
      end
      resources :subscriptions
      resources :permissions
    end
  end
  
  resources :home, only: [ :index ] do
    collection do
      get :retail
      get :education
      get :hospital
      get :restaurant
      get :shop
      get :fitness
    end
  end
  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "sign_out", to: "sessions#sign_out"
  # ----------------------------------------------------------------------------------------------------
  # DEFAULTS
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"
  namespace :sessions do
    resource :passwordless, only: [ :new, :edit, :create ]
  end
  resource :invitation, only: [ :new, :create ]
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  # ----------------------------------------------------------------------------------------------------
end


Here is some relative codes:
# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # 1. Apply Filtering Logic
        scope = current_company.employees.includes(:user, :roles, :departments)
        scope = scope.where(departments: { id: params[:department_id] }) if params[:department_id].present?
        scope = scope.joins(:roles).where(roles: { id: params[:role_id] }) if params[:role_id].present?
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(lifecycle_status: params[:status]) if params[:status].present?

        @pagy, @employees_results = pagy(:offset, scope, jsonapi: true)

        # 2. Always provide filter options so the form stays populated
        filter_options = {
          departments: current_company.departments.map { |d| { name: d.name, value: d.id} },
          roles: current_company.roles.map { |r| { name: r.name, value: r.id } },
          statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
          types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
        }

        render json: { 
          employees: format_employees(@employees_results), 
          pagination: @pagy.data_hash,
          filter_options: filter_options
        }
      end
    end
  end

  private

  def format_employees(employees)
    employees.map do |employee|
      employee.as_json(include: { user: { only: :email } }).merge(
        roles: employee.roles.map { |r| { id: r.id, name: r.name } },
        departments: employee.departments.map { |d| { id: d.id, name: d.name } }
      )
    end
  end
end

class Seed::EmployeeService
  def self.create(
    company:,
    branch: nil,
    user: nil,
    name: Faker::Name.name,
    description: "#{Faker::Job.title} in #{Faker::Commerce.department}",
    business_type: Employee.business_types.keys.sample,
    discarded_at: nil
  )
    employee = Employee.create!(
      user: user,
      company: company,
      branch: branch,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end

Above is my rules and code, with the knowledge you got from Skycom project, do this requirement:
- I need action "create" in Companies::EmployeesController, and use Seed::EmployeeService to create new employee, update the routes.rb





I want to create stimulus FormController
it will inject inside attribute of "form" - global method
it will handle submit event
it will handle response by global method "toast"
Method "toast" is from toastify-js
I also need to update the toast method, right now it only send options to Toast, I need it handle the respone from FormController, so I want to display success (green) and error (red) message, So I dont want to pass all options like right now, I want to use like toast({type: "success", message: "..."})
I want toast will have some pattern for: info (blue), error (error), success (green), warning (orang), normal (white)
