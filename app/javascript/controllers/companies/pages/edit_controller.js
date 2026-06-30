import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_EditController extends Companies_LayoutController {
  /** @type {any | null} */ page = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_page_path(companyId, recordId)}.json`)
      this.page = response.page

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load page.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const p = this.page
    if (!p) return `<div class="p-8 text-center">${translate("Page not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const branches = currentBranches()

    const targetRoles = [
      { name: translate("Retail Cashier"), value: "retail_cashier" },
      { name: translate("Retail Store Manager"), value: "retail_store_manager" }
    ]
    const targetResolutions = [
      { name: translate("Mobile Portrait"), value: "mobile_portrait" },
      { name: translate("Tablet Landscape"), value: "tablet_landscape" },
      { name: translate("Desktop Widescreen"), value: "desktop_widescreen" }
    ]
    const businessTypes = [
      { name: translate("Retail"), value: "retail" }
    ]
    const workflowStatuses = [
      { name: translate("Approved"), value: "approved" },
      { name: translate("Pending Review"), value: "pending_review" },
      { name: translate("Deployed"), value: "deployed" }
    ]

    const manifestStr = p.layout_manifest
      ? (typeof p.layout_manifest === 'object' ? JSON.stringify(p.layout_manifest, null, 2) : p.layout_manifest)
      : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Page")}</h2>
        <p class="text-sm text-slate-500">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Name")}</label>
            <input type="text" name="page[name]" value="${p.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Branch")}</label>
            <select name="page[branch_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">${translate("Select Branch")}</option>
              ${branches.map(b =>
                `<option value="${b.id}" ${b.id === p.branch?.id ? 'selected' : ''}>${b.name}</option>`
              ).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Business Type")}</label>
            <select name="page[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(businessTypes, p.business_type || 'retail')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Code")}</label>
            <input type="text" value="${p.code || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="page[code]" value="${p.code || ''}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Target Role")}</label>
            <select name="page[target_role]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(targetRoles, p.target_role)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Target Resolution")}</label>
            <select name="page[target_resolution]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(targetResolutions, p.target_resolution)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Status")}</label>
            <select name="page[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(workflowStatuses, p.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Lifecycle")}</label>
            <select name="page[lifecycle_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="active" ${p.lifecycle_status === 'active' ? 'selected' : ''}>${translate("Active")}</option>
              <option value="draft" ${p.lifecycle_status === 'draft' ? 'selected' : ''}>${translate("Draft")}</option>
              <option value="archived" ${p.lifecycle_status === 'archived' ? 'selected' : ''}>${translate("Archived")}</option>
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="page[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">${p.description || ''}</textarea>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Layout Manifest (JSON)")}</label>
            <textarea name="page[layout_manifest]" rows="4"
              class="w-full px-3 py-2 font-mono text-xs border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">${manifestStr}</textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_page_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_page_path(companyId, p.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
