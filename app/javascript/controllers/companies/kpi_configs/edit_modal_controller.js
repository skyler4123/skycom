import { Controller } from "@hotwired/stimulus"
import { kpiConfigFormHTML, prepareKpiFormData } from "controllers/companies/kpi_configs/form_fields"

export default class Companies_KpiConfigs_EditModalController extends Controller {
  connect() {
    /** @type {{ metrics: any[], categories: any[], branches: any[], departments: any[], roles: any[] }} */
    this.options = window.kpiConfigOptions || {}
    /** @type {any | null} */
    this.kpiConfig = window.currentKpiConfig || null
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    return form({
      action: Helpers.company_kpi_config_path(currentCompany().id, this.kpiConfig.id),
      method: "PATCH",
      attributes: `class="p-8 bg-card rounded-2xl w-[720px] max-w-[95vw] max-h-[90vh] overflow-y-auto shadow-2xl" data-action="submit->${this.identifier}#handleSubmit"`,
      html: kpiConfigFormHTML({ config: this.kpiConfig, options: this.options })
    })
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.company_kpi_config_path(currentCompany().id, this.kpiConfig.id), {
        method: "PATCH",
        body: prepareKpiFormData(event.target, this.options)
      })

      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save KPI") })
    }
  }
}
