import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PaymentMethods_IndexController extends Admin_LayoutController {
  static targets = ["paymentMethodsList"]

  /** @type {Array} */ paymentMethods = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.admin_payment_methods_path())
      this.paymentMethods = response.payment_methods || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load payment methods${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const columns = [
      { key: "name", name: "Name" },
      { key: "code", name: "Code" },
      { key: "business_type", name: "Type" },
      { key: "country", name: "Country" },
      { key: "lifecycle_status", name: "Status" },
      { key: "created_at", name: "Created" }
    ]

    return `
      <div class="p-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-base font-bold text-slate-900 dark:text-white">Payment Methods</h2>
            <a href="${Helpers.new_admin_payment_method_path()}"
              class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[18px]">add</span>
              Add Payment Method
            </a>
          </div>
          <div class="overflow-x-auto">
            ${table({
              rows: this.paymentMethods,
              columns,
              identifier: this.identifier,
              target: "paymentMethodsList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[18px]">payments</span>
                    </div>
                    <a href="${Helpers.edit_admin_payment_method_path(record.id)}"
                      class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                      ${value || 'Unnamed'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`,
                business_type: (value) => {
                  const colors = {
                    b2c: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
                    b2b: 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400'
                  }
                  const colorClass = colors[value] || 'bg-slate-50 text-slate-700'
                  return `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${colorClass}">${value?.toUpperCase() || '—'}</span>`
                },
                country: (value) => {
                  const names = { us: 'US', vn: 'VN' }
                  return `<span class="text-sm text-slate-600 dark:text-slate-400">${names[value] || value || '—'}</span>`
                },
                lifecycle_status: (value) => `${Helpers.statusBadge(value)}`,
                created_at: (value) => value ? `<span class="text-sm text-slate-500">${new Date(value).toLocaleDateString()}</span>` : '—'
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_admin_payment_method_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-slate-200 dark:border-slate-800">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
