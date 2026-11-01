import { Controller } from "@hotwired/stimulus"
import { kpiConfigFormHTML, prepareKpiFormData } from "controllers/companies/kpi_configs/form_fields"

export default class Companies_KpiConfigs_NewModalController extends Controller {
  connect() {
    /** @type {{ metrics: any[], categories: any[], branches: any[], departments: any[], roles: any[] }} */
    this.options = window.kpiConfigOptions || {}
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    return form({
      action: Helpers.create_company_kpi_configs_path(currentCompany().id),
      method: "POST",
      attributes: `class="p-8 bg-card rounded-2xl w-[720px] max-w-[95vw] max-h-[90vh] overflow-y-auto shadow-2xl" data-action="submit->${this.identifier}#handleSubmit"`,
      html: kpiConfigFormHTML({ options: this.options })
    })
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.create_company_kpi_configs_path(currentCompany().id), {
        method: "POST",
        body: prepareKpiFormData(event.target, this.options)
      })

      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save KPI") })
    }
  }
}
