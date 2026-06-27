import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_IndexController extends Admin_LayoutController {
  static targets = ["companiesList"]

  /** @type {Array} */ companies = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.admin_companies_path())
      this.companies = response.companies || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: "Failed to load companies" })
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
      { key: "name", label: "Company Name" },
      { key: "code", label: "Code" },
      { key: "business_type", label: "Type" },
      { key: "email", label: "Email" },
      { key: "phone_number", label: "Phone" },
      { key: "owner", label: "Owner" },
      { key: "workflow_status", label: "Status" },
      { key: "created_at", label: "Created" }
    ]

    return `
      <div class="p-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-base font-bold text-slate-900 dark:text-white">All Companies</h2>
            <span class="text-sm text-slate-500">${this.companies.length} total</span>
          </div>
          <div class="overflow-x-auto">
            ${table({
              rows: this.companies,
              columns,
              identifier: this.identifier,
              target: "companiesList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[18px]">business</span>
                    </div>
                    <a href="${Helpers.admin_company_path(record.id)}"
                      class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                      ${value || 'Unnamed'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`,
                business_type: (value) => {
                  const colors = {
                    retail: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
                    restaurant: 'bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
                    hospital: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
                    education: 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
                    hotel: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
                    fitness: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                  }
                  const colorClass = colors[value] || 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
                  return `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${colorClass}">${value || '—'}</span>`
                },
                email: (value) => value ? `<span class="text-sm text-slate-600 dark:text-slate-400">${value}</span>` : '<span class="text-slate-300 dark:text-slate-700">—</span>',
                phone_number: (value) => value ? `<span class="text-sm text-slate-600 dark:text-slate-400">${value}</span>` : '<span class="text-slate-300 dark:text-slate-700">—</span>',
                owner: (value, record) => record.user?.name || '<span class="text-slate-300 dark:text-slate-700">—</span>',
                workflow_status: (value) => `${Helpers.statusBadge(value)}`,
                created_at: (value) => value ? `<span class="text-sm text-slate-500">${new Date(value).toLocaleDateString()}</span>` : '—'
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.admin_company_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">visibility</span>
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
