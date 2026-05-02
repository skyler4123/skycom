import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Invoices_NewModalController from "controllers/companies/invoices/new_modal_controller";
import Companies_Invoices_ShowModalController from "controllers/companies/invoices/show_modal_controller";

export default class Companies_Invoices_IndexController extends Companies_LayoutController {
  static targets = ["invoicesList"]

  /** @type {(Invoice & { name: string })[]} */
  invoices = []

  async connect() {
    super.connect()
    addAction(this.element, `editable:updateInvoice@window->${this.identifier}#handleUpdate`)
    try {
      /** @type {{ invoices: Invoice[], pagination: any }} */
      const response = await fetchJson()

      this.invoices = response.invoices || []
      this.pagination = response.pagination || {}

      window.poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load invoices" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Invoices_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { invoiceId } = event.params
    window.currentInvoice = findById(this.invoices, invoiceId)
    openModal({ html: `<div data-controller="${identifier(Companies_Invoices_ShowModalController)}"></div>` })
  }

  handleUpdate(event) {
    const { data } = event.detail
    const newInvoice = data.invoice

    if (!newInvoice) return

    this.invoices = mergeObjectArrays(this.invoices, [newInvoice], "id")

    if (window.currentInvoice?.id === newInvoice.id) {
      window.currentInvoice = newInvoice
    }

    this.renderContent()
  }

  contentHTML() {
    const typeFilter = Enums()?.invoice?.business_types || []
    const statusFilter = Enums()?.invoice?.workflow_statuses || []
    const currencyFilter = Enums()?.invoice?.currency_codes || []

    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
                  <select name="business_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(typeFilter, urlParams.get('business_type'), "All Types")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Status</label>
                  <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(statusFilter, urlParams.get('workflow_status'), "All Statuses")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Currency</label>
                  <select name="currency_code" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(currencyFilter, urlParams.get('currency_code'), "All Currencies")}
                  </select>
                </div>

                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <button
                type="button"
                data-action="click->${this.identifier}#openNewModal"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </button>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Invoice #</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Amount</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="invoicesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.invoices.map(invoice => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <span class="font-mono text-slate-600 dark:text-slate-300">${invoice.number || 'N/A'}</span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
                          <span class="material-symbols-outlined text-orange-600 dark:text-orange-400">receipt</span>
                        </div>
                        <div>
                          <p class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline">
                            ${invoice.name}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">
                      ${invoice.total_price ? invoice.currency_code?.toUpperCase() + ' ' + invoice.total_price : 'N/A'}
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        invoice.business_type === 'sales' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300' :
                        invoice.business_type === 'service' ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
                        'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300'
                      }">
                        ${invoice.business_type === 'subscription' ? 'Subscription' : Helpers.capitalize(invoice.business_type || 'sales')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(invoice.workflow_status)}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
                        data-action="click->${this.identifier}#openShowModal"
                        data-${this.identifier}-invoice-id-param="${invoice.id}"
                      >
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}