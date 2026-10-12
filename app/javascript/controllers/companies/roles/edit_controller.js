import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Roles_EditController extends Companies_LayoutController {
  // Role edit form — prefilled name + description + business type, delete with confirm.
  // Depends on BE: Companies::RolesController#edit + #update + #destroy
  // Endpoints: GET company_role_path.json, PATCH company_role_path, DELETE company_role_path
  /** @type {any | null} */
  role = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load role.")}</div>`
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
    const r = this.role
    if (!r) return `<div class="p-8 text-center">${translate("Role not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const typeOptions = (Enums()?.role?.business_types || [
      { name: "Administrative", value: "administrative" },
      { name: "Management", value: "management" },
      { name: "Technical", value: "technical" },
      { name: "Support", value: "support" }
    ]).map(t => `<option value="${t.value}" ${t.value === r.business_type ? 'selected' : ''}>${t.name}</option>`).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Role")}</h2>
        <p class="text-sm text-slate-500">${r.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Name")}</label>
            <input type="text" name="role[name]" value="${r.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Business Type")}</label>
            <select name="role[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm cursor-pointer">
              ${typeOptions}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="role[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${r.description || ''}</textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_role_path(companyId, r.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_role_path(companyId, r.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
        <div class="mt-4 flex justify-end">
          ${form({
            action: Helpers.company_role_path(companyId, r.id),
            method: "DELETE",
            attributes: `data-turbo="false" class="inline"`,
            html: `<button type="submit" data-action="click->${this.identifier}#confirmDestroy" class="px-6 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">${translate("Delete Role")}</button>`
          })}
        </div>
      </div>`
  }
}
