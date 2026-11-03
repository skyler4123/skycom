import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_NewController extends Companies_LayoutController {
  /** @type {any[]} */ branches = []
  /** @type {{ name: string, value: string }[]} */ targetRoles = []
  /** @type {string | null} */ businessType = null

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.new_company_page_path(companyId)}.json`)
      this.branches = response.branches || []
      this.targetRoles = response.target_roles || []
      this.businessType = response.business_type
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load page.")}${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const targetResolutions = [
      { name: translate("Mobile"), value: "mobile" },
      { name: translate("Desktop"), value: "desktop" }
    ]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Page")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Page Name")}</label>
            <input type="text" name="page[name]" required placeholder="${translate("e.g. Retail POS")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
            <p class="text-xs text-muted-foreground">${translate("The Mobile or Desktop suffix is added automatically.")}</p>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Branch")}</label>
            <select name="page[branch_id]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="">${translate("Select Branch")}</option>
              ${this.branches.map(b => `<option value="${b.id}">${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Business Type")}</label>
            <input type="text" value="${Helpers.capitalize(this.businessType || '')}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Target Role")}</label>
            <select name="page[target_role]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(this.targetRoles.map(role => ({ ...role, name: translate(role.name) })))}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Target Resolution")}</label>
            <select name="page[target_resolution]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(targetResolutions, 'desktop')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Status")}</label>
            <select name="page[workflow_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="approved">${translate("Approved")}</option>
              <option value="pending_review">${translate("Pending Review")}</option>
              <option value="deployed">${translate("Deployed")}</option>
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="page[description]" rows="2" placeholder="${translate("Optional description")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Layout Manifest (JSON)")}</label>
            <textarea name="page[metadata][layout_manifest]" rows="4" placeholder='e.g. {"theme": "default", "columns": 2}'
              class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Page")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_pages_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
