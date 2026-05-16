//  https://fonts.google.com/icons

import { Controller } from "@hotwired/stimulus"

export default class Companies_LayoutController extends Controller {
  static targets = ["content", "profileDropdown"]
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
    isOpenProfileDropdown: { type: Boolean, default: false },
    openHeaderSubmenuName: { type: String, default: "" },
    
  }

  connect() {
    this.id = randomId()
    this.element.id = this.id
    
    poll(() => {
      if (currentCompanies() && currentCompany()) {
        this.renderLayout();
        return true; // Stop polling
      }
      return false; // Keep polling
    });
  }

  renderLayout() {
    this.element.className = 'min-h-screen flex flex-col';
    this.element.innerHTML = this.layoutHTML();
  }

  renderContent() {
    if (!this.hasContentTarget) return;
    this.contentTarget.innerHTML = this.contentHTML();
  }


  layoutHTML() {
    // If retail isn't loaded yet, return an empty string or a loader
    if (!currentCompany()) return `<div class="p-4">Loading...</div>`;
    
    return `
      <!-- Layout Wrapper: Font, Background, Colors -->
      <div class="flex flex-1 font-display bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200">
        <!-- Flex Container: Sidebar + Main -->
        <div class="flex flex-1">
          <!-- Sidebar -->
          <aside
            class="w-64 hidden open:flex flex-col shrink-0 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800"
            ${addOpenListener({group: "sidebar", key: "sidebar", cache: true})}
          >
            <!-- Sidebar Navigation Links -->
            <nav class="w-full p-4">
              <div role="navigation" class="flex flex-col gap-2">
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_dashboards_path(currentCompany().id)}"
                  ${openByPathname()}
                  ${tooltip({
                    html: "Dashboard",
                    classes: "bg-gray-900 text-white dark:bg-gray-100 dark:text-gray-900 px-2 py-1 text-xs"
                  })}
                >
                  <span class="material-symbols-outlined">dashboard</span>
                  <p class="text-sm font-medium leading-normal">${translate("Dashboard")}</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_branches_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">apartment</span>
                  <p class="text-sm font-medium leading-normal">Branches</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_departments_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">family_group</span>
                  <p class="text-sm font-medium leading-normal">Departments</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_products_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">inventory_2</span>
                  <p class="text-sm font-medium leading-normal">Products</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_services_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">concierge</span>
                  <p class="text-sm font-medium leading-normal">Services</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_orders_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">order_approve</span>
                  <p class="text-sm font-medium leading-normal">Orders</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_bookings_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">calendar_month</span>
                  <p class="text-sm font-medium leading-normal">Bookings</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_payments_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">payments</span>
                  <p class="text-sm font-medium leading-normal">Payments</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_employees_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">groups</span>
                  <p class="text-sm font-medium leading-normal">Employees</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_stocks_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">inventory</span>
                  <p class="text-sm font-medium leading-normal">Stocks</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_stock_transfers_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">swap_horiz</span>
                  <p class="text-sm font-medium leading-normal">Stock Transfers</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_stock_imports_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">download</span>
                  <p class="text-sm font-medium leading-normal">Stock Imports</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_stock_exports_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">upload</span>
                  <p class="text-sm font-medium leading-normal">Stock Exports</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_customers_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">person_add</span>
                  <p class="text-sm font-medium leading-normal">Customers</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_invoices_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">receipt_long</span>
                  <p class="text-sm font-medium leading-normal">Invoices</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_schedules_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">calendar_month</span>
                  <p class="text-sm font-medium leading-normal">Schedules</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_attendances_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">fact_check</span>
                  <p class="text-sm font-medium leading-normal">Attendances</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_reports_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">report_problem</span>
                  <p class="text-sm font-medium leading-normal">Reports</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_documents_path(currentCompany().id)}
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">description</span>
                  <p class="text-sm font-medium leading-normal">Documents</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_announcements_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">campaign</span>
                  <p class="text-sm font-medium leading-normal">Announcements</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_events_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">event</span>
                  <p class="text-sm font-medium leading-normal">Events</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_discounts_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">percent</span>
                  <p class="text-sm font-medium leading-normal">Discounts</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_subscriptions_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                   <span class="material-symbols-outlined">loyalty</span>
                   <p class="text-sm font-medium leading-normal">Subscriptions</p>
                </a>
                  <a
                    class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                    href="${Helpers.company_policies_path(currentCompany().id)}"
                    ${openByPathname()}
                  >
                    <span class="material-symbols-outlined">security</span>
                    <p class="text-sm font-medium leading-normal">Policies</p>
                  </a>
                  <a
                    class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                    href="${Helpers.company_permissions_path(currentCompany().id)}"
                    ${openByPathname()}
                  >
                    <span class="material-symbols-outlined">shield</span>
                    <p class="text-sm font-medium leading-normal">Permissions</p>
                  </a>
                <a
                   class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                   href="${Helpers.company_tasks_path(currentCompany().id)}"
                   ${openByPathname()}
                 >
                  <span class="material-symbols-outlined">check_box</span>
                  <p class="text-sm font-medium leading-normal">Tasks</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_payslips_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">receipt</span>
                  <p class="text-sm font-medium leading-normal">Payslips</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="${Helpers.company_facilities_path(currentCompany().id)}"
                  ${openByPathname()}
                >
                  <span class="material-symbols-outlined">warehouse</span>
                  <p class="text-sm font-medium leading-normal">Facilities</p>
                </a>
              </div>
            </nav>
            <!-- Sidebar Footer (Settings Link) -->
            <div class="p-4 border-t border-gray-200 dark:border-gray-800">
              <div class="flex flex-col gap-2">
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  ${openByPathname()}
                  href="${Helpers.company_settings_path(currentCompany().id)}"
                >
                  <span class="material-symbols-outlined">settings</span>
                  <p class="text-sm font-medium leading-normal">Settings</p>
                </a>
              </div>
            </div>
          </aside>
          <!-- End Sidebar -->
          <!-- Main Content Wrapper -->
          <main class="flex-1 flex flex-col overflow-auto">
            <!-- Header -->
            <header
              class="shrink-0 flex flex-wrap items-center justify-between gap-4 border-b border-gray-200 dark:border-gray-800 px-4 md:px-8 py-4 bg-white dark:bg-gray-900">
              <!-- Header Left: Company Name, Toggle, Search -->
              <div class="flex flex-wrap items-center gap-3 md:gap-6">
                <div class="flex items-center gap-3 dark:border-gray-800">
                  <div class="bg-primary/20 text-primary p-2 rounded-lg">
                    <span class="material-symbols-outlined">storefront</span>
                  </div>
                  <div class="flex flex-col">
                    <h1
                      class="text-gray-900 dark:text-white text-base font-medium leading-normal cursor-pointer"
                      ${popover({
                        classes: "bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl p-2",
                        html: `
                          <div class="flex flex-col gap-y-1 w-64">
                            ${currentCompanies().map((company) => `
                              <a href="${Helpers.company_dashboards_path(company.id)}" 
                                class="flex items-center gap-3 px-3 py-2 rounded-lg text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 ${currentCompany().id === company.id ? 'bg-gray-100 dark:bg-gray-800 font-bold' : ''}">
                                <span class="text-sm">${company.name}</span>
                              </a>`).join("")}
                          </div>
                        `
                      })}
                    >
                      ${currentCompany().name}
                    </h1>
                  </div>
                </div>

                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300" id="sidebar-toggle"
                  ${addOpenTrigger({group: "sidebar", key: "sidebar", toggle: true, cache: true})}
                >
                  <span class="material-symbols-outlined">menu</span>
                </button>
                
                <label class="flex flex-col min-w-40 h-10! w-full md:w-80">
                  <div class="flex w-full flex-1 items-stretch rounded-lg h-full">
                    <div
                      class="text-gray-500 flex bg-gray-100 dark:bg-gray-800 items-center justify-center pl-4 rounded-l-lg border-r-0">
                      <span class="material-symbols-outlined">search</span>
                    </div>
                    <input
                      class="form-input flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-gray-900 dark:text-white focus:outline-0 focus:ring-0 border-none bg-gray-100 dark:bg-gray-800 h-full placeholder:text-gray-500 px-4 rounded-l-none border-l-0 pl-2 text-base font-normal leading-normal"
                      placeholder="Search for products, customers..." value="" />
                  </div>
                </label>
              </div>
              <!-- Header Right: Actions (Dark Mode, Language, Notifications, Avatar) -->
              <div class="flex flex-wrap justify-end gap-2 md:gap-4 items-center">
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 p-2 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300"
                  ${Helpers.darkmodeTrigger()}
                >
                </button>
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300"
                  ${popover({
                    classes: "bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-xl overflow-hidden",
                    html: `
                      ${(() => {
                        // Define the display names for each code
                        const languageNames = {
                          en: "English",
                          es: "Español",
                          fr: "Français",
                          de: "Deutsch",
                          vi: "Tiếng Việt"
                        };

                        return `
                          <div class="flex flex-col min-w-[140px] py-1">
                            ${["en", "es", "fr", "de", "vi"].map(lang => `
                              <a data-language-code-param="${lang}" 
                                data-action="click->language#changeLanguage" 
                                class="flex items-center px-4 py-2 text-sm text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors"
                              >
                                ${languageNames[lang] || lang.toUpperCase()}
                              </a>
                            `).join("")}
                          </div>
                        `;
                      })()}
                    `
                  })}
                >
                  <span>${(localStorage.getItem("languageCode") || "en").toUpperCase()}</span>
                </button>
                <button
                  class="hidden md:flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined">notifications</span>
                </button>
                <button
                  class="hidden md:flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined">settings</span>
                </button>
                ${avatar({
                  url: currentUser()?.avatar,
                  className: "size-12 cursor-pointer",
                  // 2. Middle attributes (e.g., for your popover controller)
                  innerAttributes: popover({
                    position: "bottom",
                    html: `<div data-controller="users--avatar-popover"></div>`
                  })
                })}
              </div>
            </header>
            <!-- End Header -->
            <!-- Dynamic Content Area (injected by child controllers) -->
            <div data-${this.identifier}-target="content"></div>
            <!-- End Dynamic Content Area -->
          </main>
          <!-- End Main Content Wrapper -->
        </div>
      </div>
    `
  }

}
