import { Controller } from "@hotwired/stimulus"

export default class Companies_Invoices_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.create_company_invoices_path(currentCompany().id), {
        method: "POST",
        body: new FormData(event.target)
      })
      /** @type {Invoice} */
      const newInvoice = response.invoice
      reloadThenToast({
        type: "success",
        message: `${newInvoice.name || 'Invoice'} created successfully`
      })
    } catch (error) {
      toast({
        type: "error",
        message: error.errors || "Failed to create invoice"
      })
    }
  }

  modalHTML() {
    const typeOptions = (Enums()?.invoice?.business_types || []).map(t =>
      `<option value="${t.value}">${t.name === 'subscription' ? 'Subscription' : t.name}</option>`
    ).join('')

    const currencyOptions = (Enums()?.invoice?.currency_codes || []).map(c =>
      `<option value="${c.value}">${c.name.toUpperCase()}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Invoice</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Invoice Name</label>
            <input type="text" name="invoice[name]" required placeholder="e.g. Invoice for Order #12345"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Invoice Number</label>
            <input type="text" name="invoice[number]" required placeholder="e.g. INV-001"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Total Price</label>
            <input type="number" name="invoice[total_price]" step="0.01" placeholder="e.g. 100.00"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Invoice Type</label>
            <select name="invoice[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Currency</label>
            <select name="invoice[currency_code]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${currencyOptions}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Due Date</label>
            <input type="date" name="invoice[due_date]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Description</label>
          <textarea name="invoice[description]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
            Cancel
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-all shadow-lg shadow-blue-500/30">
            Save Invoice
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl border border-slate-100 dark:border-slate-800"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}