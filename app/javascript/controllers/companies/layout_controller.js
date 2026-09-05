//  https://fonts.google.com/icons

import { Controller } from "@hotwired/stimulus"
import { SIDEBAR_ITEMS, hiddenSidebarKeys } from "controllers/companies/sidebar_items"

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

  // Dynamic tables render whatever columns are configured in the TableConfig —
  // property_* slots plus defined properties (name, code, workflow_status, ...).
  // BE validation (TableConfig.columns_metadata_must_conform_to_schema) is the gate.
  dynamicColumns() {
    const columns = this.currentTableConfig()?.metadata?.columns || []
    return columns.filter(col => col.visible !== false)
  }

  dynamicTableHTML({ rows, target, mappingLookup = {}, renderers = {}, renderActions }) {
    const columns = this.dynamicColumns()
    if (columns.length === 0) {
      return `<div class="py-12 text-center text-sm text-slate-400 dark:text-slate-500">${translate("No columns configured")}</div>`
    }
    return table({ rows, columns, identifier: this.identifier, target, mappingLookup, renderers, renderActions })
  }

  sidebarItems() {
    const hidden = hiddenSidebarKeys()
    const visible = SIDEBAR_ITEMS.filter(item => !hidden.has(item.key))

    const sectionHeading = (label) => `
      <p class="px-3 pt-1 pb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">${label}</p>
    `

    const divider = `<div class="my-3 border-t border-gray-200 dark:border-gray-700"></div>`

    const group = (name, items) => `
      <div class="flex flex-col gap-2" data-sidebar-group="${name}">
        ${sectionHeading(translate(name === "company" ? "Company" : "System"))}
        ${items.join("\n")}
      </div>
    `

    const linkHTML = (item) => {
      const cid = currentCompany().id
      return `
        <a
          class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
          href="${item.href(cid)}"
          ${openByPathname()}
        >
          <span class="material-symbols-outlined">${item.icon}</span>
          <p class="text-sm font-medium leading-normal">${translate(item.label)}</p>
        </a>
      `
    }

    const companyItems = visible.filter(i => i.group === "company").map(linkHTML)
    const systemItems  = visible.filter(i => i.group === "system").map(linkHTML)

    return [
      group("company", companyItems),
      divider,
      group("system", systemItems)
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
