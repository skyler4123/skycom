import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Services_EditController extends Companies_LayoutController {
  /** @type {Service | null} */
  service = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_service_path(companyId, recordId)}.json`)
      this.service = response.service

      if (this.service?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.service.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load service.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const s = this.service
    if (!s) return `<div class="p-8 text-center">${translate("Service not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = ENUMS?.service?.business_types || []
    const workflowStatuses = ENUMS?.service?.workflow_statuses || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = s[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="service[${field.key}]" value="false">
                  <input type="checkbox" name="service[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-line text-primary cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="service[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="service[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="service[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              default:
                inputHTML = `<input type="text" name="service[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-muted-foreground">${field.name}</label>
                ${inputHTML}
              </div>`
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Service")}</h2>
        <p class="text-sm text-muted-foreground">${s.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
            <input type="text" name="service[name]" value="${s.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
            <textarea name="service[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">${s.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Type")}</label>
            <select name="service[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(businessTypes, s.business_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Status")}</label>
            <select name="service[workflow_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(workflowStatuses, s.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === s.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="service[category_id]" value="${s.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Code")}</label>
            <input type="text" name="service[code]" value="${s.code || ''}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_service_path(companyId, s.id)}"
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
          action: Helpers.company_service_path(companyId, s.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
