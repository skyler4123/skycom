import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Roles_ShowController extends Companies_LayoutController {
  // Role detail — read-only fields + edit/delete (owner role is fully read-only).
  // Delete asks for confirmation: the paired "All <Role>" tag goes with the role.
  // Depends on BE: Companies::RolesController#show + #destroy
  // Endpoints: GET company_role_path.json, DELETE company_role_path
  /** @type {any | null} */
  role = null

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_role_path(companyId, recordId)}.json`)
      this.role = response.role

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load role.")}</div>`
          return true
        }
        return false
      })
    }
  }

  confirmDestroy(event) {
    const r = this.role
    if (!confirm(`${translate("Delete role")} '${r.name}'? ${translate("Its notification tag will be removed also — subscribers will stop receiving role broadcasts!")}`)) {
      event.preventDefault()
      event.stopPropagation()
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  showHTML() {
    const r = this.role
    if (!r) return `<div class="p-8 text-center">${translate("Role not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const isOwner = r.name === "owner"

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_roles_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Roles")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-primary/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">badge</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${r.name}</h2>
              <p class="font-semibold text-primary">${r.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-muted-foreground uppercase">${r.business_type || ''}</span>
                <span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-muted-foreground uppercase">${r.paired_tag_name || ''}</span>
              </div>
            </div>
          </div>

          ${isOwner ? '' : `
          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            ${form({
              action: Helpers.company_role_path(companyId, r.id),
              method: "DELETE",
              attributes: `data-turbo="false" class="inline"`,
              html: `<button type="submit" data-action="click->${this.identifier}#confirmDestroy" class="inline-flex items-center px-6 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">${translate("Delete Role")}</button>`
            })}
            <a href="${Helpers.edit_company_role_path(companyId, r.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Role")}
            </a>
          </div>`}
        </div>
      </div>`
  }
}
