import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Products_NewModalController from "controllers/companies/products/new_modal_controller";
import Companies_Products_ShowModalController from "controllers/companies/products/show_modal_controller";

export default class Companies_Products_IndexController extends Companies_LayoutController {
  // 1. Change target name to point to the mount container instead of tbody
  static targets = ["tableContainer"]

  /** @type {(Product & { name: string })[]} */
  products = []

  async connect() {
    super.connect()
    try {
      /** @type {{ products: Product[], pagination: any }} */
      const response = await fetchJson()

      this.products = response.products || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          // 2. Initialize the dynamic pure-HTML table after layout injection
          this.initTable()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load products" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Products_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { productId } = event.params
    window.currentProduct = findById(this.products, productId)
    openModal({ html: `<div data-controller="${identifier(Companies_Products_ShowModalController)}"></div>` })
  }

  initTable() {
    if (!this.hasTableContainerTarget) return

    table(this.tableContainerTarget, {
      data: this.products,
      columns: [
        {
          title: "Product Name",
          field: "name",
          formatter: (value) => `
            <div class="flex items-center gap-4">
              <div class="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400">inventory_2</span>
              </div>
              <div>
                <p class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline">
                  ${value}
                </p>
              </div>
            </div>
          `
        },
        {
          title: "SKU",
          field: "sku",
          formatter: (value) => `<span class="font-mono text-slate-600 dark:text-slate-300">${value || 'N/A'}</span>`
        },
        {
          title: "Type",
          field: "business_type",
          formatter: (value) => {
            const type = value || 'physical'
            const badgeClass = 
              type === 'physical' ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
              type === 'digital' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300' :
              'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300';
            
            return `
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badgeClass}">
                ${Helpers.capitalize(type)}
              </span>
            `
          }
        },
        {
          title: "Status",
          field: "workflow_status",
          formatter: (value) => Helpers.statusBadge(value)
        },
        {
          title: "Actions",
          align: "right",
          formatter: (_value, row) => `
            <button
              class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
              data-action="click->${this.identifier}#openShowModal"
              data-${this.identifier}-product-id-param="${row.id}"
            >
              <span class="material-symbols-outlined text-[20px]">edit</span>
            </button>
          `
        }
      ]
    })
  }
  
  contentHTML() {
    const typeFilter = Enums()?.product?.business_types || []
    const workflowStatusFilter = Enums()?.product?.workflow_statuses || []
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
                    ${selectOptionsHTML(workflowStatusFilter, urlParams.get('workflow_status'), "All Statuses")}
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

          <div data-${this.identifier}-target="tableContainer"></div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}