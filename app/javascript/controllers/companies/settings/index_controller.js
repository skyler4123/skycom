// Settings page shell — placeholder for future settings modules.
// The old Sidebar tab was removed: sidebar configuration is FE-only
// (localStorage favourites, see docs/SIDEBAR.md).
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Settings_IndexController extends Companies_LayoutController {
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

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-10 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 text-center">
          <span class="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600">settings</span>
          <h2 class="mt-3 text-lg font-bold text-slate-900 dark:text-white">${translate("Settings")}</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">${translate("Settings are coming soon")}</p>
        </div>
      </div>
    `
  }
}
