import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Settings_Tabs_SidebarController from "controllers/companies/settings/tabs/sidebar_controller"

const SETTINGS_TABS = [
  { key: "sidebar", icon: "menu", label: "Sidebar", controller: Companies_Settings_Tabs_SidebarController }
]

export default class Companies_Settings_IndexController extends Companies_LayoutController {
  static values = {
    activeTab: { type: String, default: "sidebar" }
  }

  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  openTab(event) {
    this.activeTabValue = event.params.tab
    this.renderContent()
  }

  activeTab() {
    return SETTINGS_TABS.find(t => t.key === this.activeTabValue) || SETTINGS_TABS[0]
  }

  contentHTML() {
    const tab = this.activeTab()
    return `
      <div class="p-4 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex min-h-[70vh]">
          <aside class="w-56 shrink-0 border-r border-slate-200 dark:border-slate-800 p-3 flex flex-col gap-1">
            ${SETTINGS_TABS.map(t => `
              <button
                type="button"
                data-action="click->${this.identifier}#openTab"
                data-${this.identifier}-tab-param="${t.key}"
                class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors ${this.activeTabValue === t.key ? 'bg-blue-600 text-white' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'}"
              >
                <span class="material-symbols-outlined text-[18px]">${t.icon}</span>
                ${translate(t.label)}
              </button>
            `).join('')}
          </aside>
          <div class="flex-1 min-w-0">
            <div data-controller="${identifier(tab.controller)}"></div>
          </div>
        </div>
      </div>
    `
  }
}