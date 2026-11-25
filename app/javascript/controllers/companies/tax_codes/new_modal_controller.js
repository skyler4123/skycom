import { Controller } from "@hotwired/stimulus"
import { taxCodeFormHTML } from "controllers/companies/tax_codes/form_fields"

export default class Companies_TaxCodes_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    return form({
      action: Helpers.company_tax_codes_path(currentCompany().id),
      method: "POST",
      attributes: `class="p-8 bg-card rounded-2xl w-[560px] max-w-[95vw] max-h-[90vh] overflow-y-auto shadow-2xl" data-action="submit->${this.identifier}#handleSubmit"`,
      html: taxCodeFormHTML({})
    })
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.company_tax_codes_path(currentCompany().id), {
        method: "POST",
        body: new FormData(event.target)
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save tax code") })
    }
  }
}
