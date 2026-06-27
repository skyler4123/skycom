import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_ShowController extends Admin_LayoutController {
  /** @type {Object|null} */ company = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[pathParts.length - 1]

    try {
      const response = await fetchJson(`${Helpers.admin_company_path(companyId)}.json`)
      this.company = response.company
    } catch (error) {
      toast({ type: "error", message: "Failed to load company" })
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
    const c = this.company
    if (!c) return '<div class="p-8 text-center text-slate-500">Company not found.</div>'

    const businessTypeColors = {
      retail: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      restaurant: 'bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
      hospital: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
      education: 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
      hotel: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
      fitness: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
    }

    const detailFields = [
      { label: "Business Type", value: c.business_type, type: "badge", badgeClass: businessTypeColors[c.business_type] || 'bg-slate-50 text-slate-700' },
      { label: "Email", value: c.email, type: "link", href: `mailto:${c.email}` },
      { label: "Phone", value: c.phone_number, type: "link", href: `tel:${c.phone_number}` },
      { label: "Website", value: c.website, type: "link", href: c.website },
      { label: "City", value: c.city },
      { label: "Country", value: c.country_code?.toUpperCase() },
      { label: "Employee Count", value: c.employee_count != null ? String(c.employee_count) : null },
      { label: "Registration Number", value: c.registration_number },
      { label: "Tax ID", value: c.tax_id },
      { label: "VAT ID", value: c.vat_id },
      { label: "Ownership", value: c.ownership_type ? c.ownership_type.replace('_', ' ') : null },
      { label: "Currency", value: c.currency_code?.toUpperCase() },
      { label: "Timezone", value: c.timezone != null ? `UTC${c.timezone > 0 ? '+' : ''}${c.timezone}` : null },
      { label: "Description", value: c.description, type: "full" }
    ]

    return `
      <div class="p-6">
        <a href="/admin/companies"
          class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
          <span class="material-symbols-outlined text-[18px]">arrow_back</span>
          Back to Companies
        </a>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
          <!-- Header -->
          <div class="px-6 py-5 border-b border-slate-200 dark:border-slate-800">
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                  <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[24px]">business</span>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-slate-900 dark:text-white">${c.name || 'Unnamed Company'}</h2>
                  <div class="flex items-center gap-2 mt-1">
                    ${c.code ? `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded text-slate-500">${c.code}</span>` : ''}
                    ${Helpers.statusBadge(c.workflow_status)}
                  </div>
                </div>
              </div>
              <div class="text-right text-xs text-slate-400">
                <div>Created ${c.created_at ? new Date(c.created_at).toLocaleDateString() : '—'}</div>
                <div class="mt-0.5">Updated ${c.updated_at ? new Date(c.updated_at).toLocaleDateString() : '—'}</div>
              </div>
            </div>
          </div>

          <!-- Detail Grid -->
          <div class="p-6">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              ${detailFields.map(field => {
                if (field.value == null || field.value === '') return ''

                switch (field.type) {
                  case 'badge':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${field.badgeClass}">${field.value}</span>
                      </div>`
                  case 'link':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <a href="${field.href}" class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 cursor-pointer">${field.value}</a>
                      </div>`
                  case 'full':
                    return `
                      <div class="sm:col-span-2 lg:col-span-3">
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <p class="text-sm text-slate-700 dark:text-slate-300">${field.value}</p>
                      </div>`
                  default:
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <p class="text-sm font-medium text-slate-900 dark:text-white">${field.value}</p>
                      </div>`
                }
              }).join('')}
            </div>
          </div>

          <!-- Owner Section -->
          ${c.user ? `
            <div class="px-6 py-4 border-t border-slate-200 dark:border-slate-800">
              <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-3">Owner</p>
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                  <span class="text-sm font-bold text-blue-600 dark:text-blue-400">${(c.user.name || '?')[0].toUpperCase()}</span>
                </div>
                <div>
                  <p class="text-sm font-medium text-slate-900 dark:text-white">${c.user.name || 'Unknown'}</p>
                  <p class="text-sm text-slate-500">${c.user.email || ''}</p>
                </div>
              </div>
            </div>
          ` : ''}
        </div>
      </div>
    `
  }
}
