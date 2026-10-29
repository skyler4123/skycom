import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Roles_NewController extends Companies_LayoutController {
  // Role creation form — name + description + business type.
  // Depends on BE: Companies::RolesController#create
  // Endpoints: POST create_company_roles_path
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
    const typeOptions = (ENUMS?.role?.business_types || [
      { name: "Administrative", value: "administrative" },
      { name: "Management", value: "management" },
      { name: "Technical", value: "technical" },
      { name: "Support", value: "support" }
    ]).map(t => `<option value="${t.value}">${t.name}</option>`).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Role")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="role[name]" required placeholder="${translate("e.g. Cashier")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Business Type")}</label>
            <select name="role[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground cursor-pointer">
              ${typeOptions}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="role[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground"></textarea>
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Role")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_roles_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }
}
