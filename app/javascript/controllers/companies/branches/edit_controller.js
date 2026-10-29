import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Branches_PaymentMethodAppointmentsModalController from "controllers/companies/branches/payment_method_appointments_modal_controller"

export default class Companies_Branches_EditController extends Companies_LayoutController {
  /** @type {Branch | null} */
  branch = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_branch_path(companyId, recordId)}.json`)
      this.branch = response.branch

      if (this.branch?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.branch.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load branch.")}</div>`
          return true
        }
        return false
      })
    }
  }

  openPaymentMethodsModal() {
    if (!this.branch) return
    openModal({
      html: `<div
        data-controller="${identifier(Companies_Branches_PaymentMethodAppointmentsModalController)}"
        data-${identifier(Companies_Branches_PaymentMethodAppointmentsModalController)}-branch-id-value="${this.branch.id}"
      ></div>`
    })
  }

  contentHTML() {
    const b = this.branch
    if (!b) return `<div class="p-8 text-center">${translate("Branch not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = ENUMS?.branch?.business_types || []
    const workflowStatuses = ENUMS?.branch?.workflow_statuses || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = b[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="branch[${field.key}]" value="false">
                  <input type="checkbox" name="branch[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-line text-primary cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="branch[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="branch[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="branch[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              default:
                inputHTML = `<input type="text" name="branch[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
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
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Branch")}</h2>
        <p class="text-sm text-muted-foreground">${b.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
            <input type="text" name="branch[name]" value="${b.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
            <textarea name="branch[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">${b.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Type")}</label>
            <select name="branch[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(businessTypes, b.business_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Status")}</label>
            <select name="branch[workflow_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(workflowStatuses, b.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === b.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="branch[category_id]" value="${b.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Phone")}</label>
            <input type="text" name="branch[phone_number]" value="${b.phone_number || ''}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Email")}</label>
            <input type="email" name="branch[email]" value="${b.email || ''}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_branch_path(companyId, b.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="button" data-action="click->${this.identifier}#openPaymentMethodsModal"
            class="inline-flex items-center justify-center px-4 py-2 text-sm font-medium bg-muted text-foreground hover:bg-muted rounded-lg transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-[18px]! mr-2">payments</span>
            ${translate("Payment Methods")}
          </button>
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
          action: Helpers.company_branch_path(companyId, b.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
