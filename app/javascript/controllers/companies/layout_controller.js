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
   
    categoryId: { type: String, default: "" },
    propertyMappingId: { type: String, default: "" },
    tableConfigId: { type: String, default: "" }
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

  currentCategory() {
    return currentCategories().find(category => category.id === this.categoryIdValue)
  }

  currentPropertyMapping() {
    return currentPropertyMappings().find(mapping => mapping.id === this.propertyMappingIdValue)
  }

  currentTableConfig() {
    return currentTableConfigs().find(config => config.id === this.tableConfigIdValue)
  }

  sidebarItems() {
    const cid = currentCompany().id
    const link = (featureKey, href, icon, label) => {
      if (featureKey && !featureEnabled(featureKey)) return ''
      return `
        <a
          class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
          href="${href}"
          ${openByPathname()}
        >
          <span class="material-symbols-outlined">${icon}</span>
          <p class="text-sm font-medium leading-normal">${label}</p>
        </a>
      `
    }

    return [
      link(null, Helpers.company_dashboards_path(cid), 'dashboard', translate('Dashboard')),
      link('multi_branch', Helpers.company_branches_path(cid), 'apartment', translate('Branches')),
      link(null, Helpers.company_departments_path(cid), 'family_group', translate('Departments')),
      link(null, Helpers.company_categories_path(cid), 'category', translate('Categories')),
      link(null, Helpers.company_property_mappings_path(cid), 'settings_applications', translate('Dynamic Properties')),
      link(null, Helpers.company_table_configs_path(cid), 'table', translate('Dynamic Tables')),
      link('inventory_basic', Helpers.company_products_path(cid), 'inventory_2', translate('Products')),
      link('inventory_basic', Helpers.company_brands_path(cid), 'diamond', translate('Brands')),
      link('inventory_basic', Helpers.company_services_path(cid), 'concierge', translate('Services')),
      link('pos_basic', Helpers.company_orders_path(cid), 'order_approve', translate('Orders')),
      link('hrm_attendance', Helpers.company_employees_path(cid), 'groups', translate('Employees')),
      link('hrm_attendance', Helpers.company_shift_templates_path(cid), 'schedule', translate('Shift Templates')),
      link('hrm_attendance', Helpers.company_scheduled_shifts_path(cid), 'calendar_month', translate('Shifts')),
      link('hrm_attendance', Helpers.company_attendance_days_path(cid), 'badge', translate('Attendance Days')),
      link('hrm_attendance', Helpers.company_attendance_policies_path(cid), 'gps_fixed', translate('Attendance Policies')),
      link('hrm_attendance', Helpers.company_attendance_logs_path(cid), 'receipt_long', translate('Attendance Logs')),
      link('hrm_attendance', Helpers.company_attendance_months_path(cid), 'calendar_view_month', translate('Attendance Months')),
      link('inventory_basic', Helpers.company_stocks_path(cid), 'inventory', translate('Stocks')),
      link('inventory_advanced', Helpers.company_stock_transfers_path(cid), 'swap_horiz', translate('Stock Transfers')),
      link('inventory_basic', Helpers.company_stock_imports_path(cid), 'download', translate('Stock Imports')),
      link('inventory_basic', Helpers.company_stock_exports_path(cid), 'upload', translate('Stock Exports')),
      link('crm_basic', Helpers.company_customers_path(cid), 'person_add', translate('Customers')),
      link('finance_basic', Helpers.company_invoices_path(cid), 'receipt_long', translate('Invoices')),
      link('custom_roles', Helpers.company_policies_path(cid), 'security', translate('Policies')),
      link(null, Helpers.company_pages_path(cid), 'description', translate('Pages')),
      link(null, Helpers.company_payment_method_appointments_path(cid), 'payments', translate('Payment Methods')),
      link('custom_roles', Helpers.company_permissions_path(cid), 'shield', translate('Permissions')),
      link(null, Helpers.company_billing_path(cid), 'account_balance_wallet', translate('Billing')),
      link('analytics_dashboard', Helpers.company_analytics_path(cid), 'insights', translate('Analytics')),
      link(null, Helpers.company_facilities_path(cid), 'warehouse', translate('Facilities')),
    ].join('\n')
  }

  renderTableTitle() {
    const config = this.currentTableConfig()
    const category = this.currentCategory()
    if (!config || !category) return ''

    const companyId = currentCompany()?.id
    const resourceName = this.identifier
      .split('--')[1]
      .replace(/-/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase())

    return `
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-bold text-slate-900 dark:text-white">
          ${resourceName} - ${category.name}
        </h2>
        <a href="${Helpers.edit_company_table_config_path(companyId, config.id)}"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-600 dark:text-slate-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors cursor-pointer"
          ${tooltip(translate("Edit table configuration"))}
        >
          <span class="material-symbols-outlined text-[18px]">edit</span>
          ${translate("Edit")}
        </a>
      </div>
    `
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
      <div class="min-w-0 flex flex-1 font-display bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200">
        <!-- Flex Container: Sidebar + Main -->
        <div class="min-w-0 flex flex-1">
          <!-- Sidebar -->
          <aside
            class="w-64 hidden open:flex flex-col shrink-0 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800"
            ${addOpenListener({group: "sidebar", key: "sidebar", cache: true})}
          >
            <!-- Sidebar Navigation Links -->
            <nav class="w-full p-4">
              <div role="navigation" class="flex flex-col gap-2">
                ${this.sidebarItems()}
              </div>
            </nav>

          </aside>
          <!-- End Sidebar -->
          <!-- Main Content Wrapper -->
          <main class="min-w-0 flex-1 flex flex-col overflow-y-auto overflow-x-hidden">
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
                              <div class="flex items-center justify-between px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 ${currentCompany().id === company.id ? 'bg-gray-100 dark:bg-gray-800' : ''}">
                                <a href="${Helpers.company_dashboards_path(company.id)}" 
                                  class="flex items-center gap-3 flex-1 min-w-0 text-gray-800 dark:text-gray-200 ${currentCompany().id === company.id ? 'font-bold' : ''}">
                                  <span class="text-sm truncate">${company.name}</span>
                                </a>
                                <a href="${Helpers.edit_company_company_path(company.id, company.id)}"
                                  class="flex items-center justify-center p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg cursor-pointer shrink-0"
                                  ${tooltip(translate("Edit company"))}>
                                  <span class="material-symbols-outlined text-[16px]">edit</span>
                                </a>
                              </div>`).join("")}
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
                      placeholder="${translate("Search for products, customers...")}" value="" />
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
                          vi: "Tiếng Việt"
                        };

                        return `
                          <div class="flex flex-col min-w-[140px] py-1">
                            ${["en", "vi"].map(lang => `
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
