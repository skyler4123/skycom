import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_EditController extends Companies_LayoutController {
  /** @type {any | null} */ page = null
  /** @type {{ name: string, value: string }[]} */ targetRoles = []
  /** @type {string | null} */ businessType = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_page_path(companyId, recordId)}.json`)
      this.page = response.page
      this.targetRoles = response.target_roles || []
      this.businessType = response.page?.business_type

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load page.")}</div>`
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

    const targetResolutions = [
      { name: translate("Mobile"), value: "mobile" },
      { name: translate("Desktop"), value: "desktop" }
    ]
    const workflowStatuses = [
      { name: translate("Approved"), value: "approved" },
      { name: translate("Pending Review"), value: "pending_review" },
      { name: translate("Deployed"), value: "deployed" }
    ]

    const manifestStr = p.metadata?.layout_manifest
      ? (typeof p.metadata?.layout_manifest === 'object' ? JSON.stringify(p.metadata?.layout_manifest, null, 2) : p.metadata?.layout_manifest)
      : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Page")}</h2>
        <p class="text-sm text-muted-foreground">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
            <input type="text" name="page[name]" value="${p.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Branch")}</label>
            <select name="page[branch_id]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="">${translate("Select Branch")}</option>
              ${branches.map(b =>
                `<option value="${b.id}" ${b.id === p.branch?.id ? 'selected' : ''}>${b.name}</option>`
              ).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Business Type")}</label>
            <input type="text" value="${Helpers.capitalize(this.businessType || p.business_type || '')}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Code")}</label>
            <input type="text" value="${p.code || ''}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="page[code]" value="${p.code || ''}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Target Role")}</label>
            <select name="page[target_role]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(this.targetRoles.map(role => ({ ...role, name: translate(role.name) })), p.target_role)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Target Resolution")}</label>
            <select name="page[target_resolution]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(targetResolutions, p.target_resolution)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Status")}</label>
            <select name="page[workflow_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(workflowStatuses, p.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Lifecycle")}</label>
            <select name="page[lifecycle_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="active" ${p.lifecycle_status === 'active' ? 'selected' : ''}>${translate("Active")}</option>
              <option value="draft" ${p.lifecycle_status === 'draft' ? 'selected' : ''}>${translate("Draft")}</option>
              <option value="archived" ${p.lifecycle_status === 'archived' ? 'selected' : ''}>${translate("Archived")}</option>
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
            <textarea name="page[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">${p.description || ''}</textarea>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Layout Manifest (JSON)")}</label>
            <textarea name="page[metadata][layout_manifest]" rows="4"
              class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none">${manifestStr}</textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_page_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
