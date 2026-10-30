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
      { key: "created_at", name: "Created (UTC)" }
    ]

    return `
      <div class="p-6">
        <div class="bg-card rounded-xl border border-line">
          <div class="flex items-center justify-between px-6 py-4 border-b border-line">
            <h2 class="text-base font-bold text-foreground">Payment Methods</h2>
            <a href="${Helpers.new_admin_payment_method_path()}"
              class="inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">add</span>
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
                    <div class="w-8 h-8 rounded-lg bg-success/10 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-success text-[18px]!">payments</span>
                    </div>
                    <a href="${Helpers.edit_admin_payment_method_path(record.id)}"
                      class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                      ${value || 'Unnamed'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${value || '—'}</span>`,
                business_type: (value) => {
                  const colors = {
                    b2c: 'bg-primary/10 text-primary ',
                    b2b: 'bg-primary/10 text-primary '
                  }
                  const colorClass = colors[value] || 'bg-background text-foreground '
                  return `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${colorClass}">${value?.toUpperCase() || '—'}</span>`
                },
                country: (value) => {
                  const names = { us: 'US', vn: 'VN' }
                  return `<span class="text-sm text-muted-foreground">${names[value] || value || '—'}</span>`
                },
                lifecycle_status: (value) => `${Helpers.statusBadge(value)}`,
                created_at: (value) => value ? `<span class="text-sm text-muted-foreground">${Helpers.timeFormat(value)}</span>` : '—'
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_admin_payment_method_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-line">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
