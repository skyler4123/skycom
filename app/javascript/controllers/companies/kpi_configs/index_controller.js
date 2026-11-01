import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_KpiConfigs_NewModalController from "controllers/companies/kpi_configs/new_modal_controller"
import Companies_KpiConfigs_EditModalController from "controllers/companies/kpi_configs/edit_modal_controller"

export default class Companies_KpiConfigs_IndexController extends Companies_LayoutController {
  // KPI settings — owner-only when the company keeps the seeded permissions.
  // Depends on BE: Companies::KpiConfigsController#index/create/update/destroy
  // Endpoints: GET /companies/:company_id/kpi_configs.json,
  //            POST/PATCH/DELETE /companies/:company_id/kpi_configs
  // Docs: docs/KPI.md

  /** @type {any[]} */
  kpiConfigs = []

  /** @type {{ metrics: any[], categories: any[], branches: any[], departments: any[], roles: any[] }} */
  options = { metrics: [], categories: [], branches: [], departments: [], roles: [] }

  canManage = false

  connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    try {
      const response = await fetchJson(`${Helpers.company_kpi_configs_path(currentCompany().id)}.json`)
      this.kpiConfigs = response.kpi_configs || []
      this.options = response.options || this.options
      this.canManage = response.can_manage === true
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load KPI list.") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    }, { maxAttempts: 500 })
  }

  openNewModal() {
    window.kpiConfigOptions = this.options
    openModal({ html: `<div data-controller="${identifier(Companies_KpiConfigs_NewModalController)}"></div>` })
  }

  openEditModal(event) {
    const config = this.kpiConfigs.find((candidate) => candidate.id === event.currentTarget.dataset.kpiConfigId)
    if (!config) return

    window.kpiConfigOptions = this.options
    window.currentKpiConfig = config
    openModal({ html: `<div data-controller="${identifier(Companies_KpiConfigs_EditModalController)}"></div>` })
  }

  deleteConfig(event) {
    const config = this.kpiConfigs.find((candidate) => candidate.id === event.currentTarget.dataset.kpiConfigId)
    if (!config) return

    Helpers.confirmAction({
      title: translate("Delete KPI"),
      text: translate("Scores are recalculated without this rule. Orders are not affected."),
      confirmButtonText: translate("Delete"),
      cancelButtonText: translate("Cancel")
    }).then(async (result) => {
      if (!result.isConfirmed) return

      try {
        const response = await fetchJson(Helpers.company_kpi_config_path(currentCompany().id, config.id), {
          method: "DELETE"
        })
        reloadThenToast({ type: "success", message: response.message })
      } catch (error) {
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete KPI.") })
      }
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div>
              <h2 class="text-xl font-bold text-foreground">${translate("KPI Settings")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Rules the company uses to score employee performance.")}</p>
            </div>
            <div class="flex items-center gap-2">
              <a href="${Helpers.company_performance_index_path(currentCompany().id)}"
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-muted-foreground border border-line rounded-lg hover:bg-muted">
                <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
                ${translate("Performance")}
              </a>
              ${this.canManage ? `
                <button type="button" data-action="click->${this.identifier}#openNewModal"
                  class="inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
                  <span class="material-symbols-outlined text-[20px]">add</span>
                  ${translate("Add KPI")}
                </button>
              ` : ""}
            </div>
          </div>

          ${this.kpiConfigs.length ? this.tableHTML() : this.emptyHTML()}
        </div>
      </div>
    `
  }

  tableHTML() {
    return `
      <div class="overflow-x-auto border border-line rounded-xl">
        <table class="w-full text-sm">
          <thead class="bg-muted/50 text-muted-foreground">
            <tr>
              <th class="text-left font-semibold px-4 py-3">${translate("Name")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Metric")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Target")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Weight")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Period")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Scope")}</th>
              ${this.canManage ? `<th class="text-right font-semibold px-4 py-3">${translate("Actions")}</th>` : ""}
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${this.kpiConfigs.map((config) => this.rowHTML(config)).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  rowHTML(config) {
    return `
      <tr data-kpi-config-id="${config.id}">
        <td class="px-4 py-3">
          <p class="font-medium text-foreground">${escapeHtml(config.name)}</p>
          ${config.description ? `<p class="text-xs text-muted-foreground mt-0.5">${escapeHtml(config.description)}</p>` : ""}
        </td>
        <td class="px-4 py-3 text-muted-foreground">${this.metricLabel(config)}</td>
        <td class="px-4 py-3 font-mono text-foreground">${this.targetLabel(config)}</td>
        <td class="px-4 py-3 font-mono text-muted-foreground">${config.weight}</td>
        <td class="px-4 py-3 text-muted-foreground">${translate(this.periodLabel(config))}</td>
        <td class="px-4 py-3 text-muted-foreground">${escapeHtml(this.scopeLabel(config))}</td>
        ${this.canManage ? `
          <td class="px-4 py-3 text-right whitespace-nowrap">
            <button type="button" data-action="click->${this.identifier}#openEditModal"
              data-kpi-config-id="${config.id}" ${tooltip("Edit KPI")}
              class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg">
              <span class="material-symbols-outlined text-[20px]">edit</span>
            </button>
            <button type="button" data-action="click->${this.identifier}#deleteConfig"
              data-kpi-config-id="${config.id}" ${tooltip("Delete KPI")}
              class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg">
              <span class="material-symbols-outlined text-[20px]">delete</span>
            </button>
          </td>
        ` : ""}
      </tr>
    `
  }

  emptyHTML() {
    return `
      <div class="text-center py-12 border border-line rounded-xl">
        <span class="material-symbols-outlined text-[40px] text-muted-foreground/60">leaderboard</span>
        <p class="text-sm font-medium text-foreground mt-3">${translate("No KPI configured yet.")}</p>
        <p class="text-sm text-muted-foreground mt-1">${translate("Create the first KPI to start measuring employee performance.")}</p>
        ${this.canManage ? `
          <button type="button" data-action="click->${this.identifier}#openNewModal"
            class="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
            <span class="material-symbols-outlined text-[20px]">add</span>
            ${translate("Add KPI")}
          </button>
        ` : ""}
      </div>
    `
  }

  metricLabel(config) {
    const metric = this.options.metrics.find((candidate) => candidate.key === config.metric_key)
    return translate(metric?.label || config.metric_key)
  }

  targetLabel(config) {
    if (config.target_value === null || config.target_value === undefined) return "—"
    if (config.unit === "currency_cents") {
      return Helpers.formatMoney(config.target_value, currentCompany()?.currency || "usd")
    }

    return Number(config.target_value).toLocaleString()
  }

  periodLabel(config) {
    return { month: "Month", quarter: "Quarter", year: "Year" }[config.period_type] || "Month"
  }

  scopeLabel(config) {
    const parts = [ config.category?.name, config.branch?.name, config.department?.name, config.role?.name ].filter(Boolean)
    return parts.length ? parts.join(", ") : translate("All employees")
  }
}
