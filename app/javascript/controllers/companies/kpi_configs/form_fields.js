// Shared KPI config form markup + submit normalization for the new/edit modals.
// Target values for currency metrics are entered in major units and sent to the
// backend in minor units (cents), matching Kpi::Metrics::OrdersRevenueCents.

const scopeSelect = ({ name, label, items = [], selectedId = null }) => {
  const options = items.map((item) => `
    <option value="${item.id}" ${String(item.id) === String(selectedId) ? "selected" : ""}>${escapeHtml(item.name || "")}</option>
  `).join("")

  return `
    <div class="space-y-1">
      <label class="text-xs font-medium text-muted-foreground">${translate(label)}</label>
      <select name="kpi_config[${name}]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
        <option value="">${translate("All employees")}</option>
        ${options}
      </select>
    </div>
  `
}

const isVnd = () => (currentCompany()?.currency || "usd").toLowerCase() === "vnd"

const targetValue = (config, metric) => {
  if (config?.target_value === null || config?.target_value === undefined) return ""
  if (metric?.unit === "currency_cents" && !isVnd()) return (Number(config.target_value) / 100).toFixed(2)

  return config.target_value
}

export const kpiConfigFormHTML = ({ config = null, options = {} } = {}) => {
  const metrics = options.metrics || []
  const metricKey = config?.metric_key || metrics[0]?.key || ""
  const metric = metrics.find((candidate) => candidate.key === metricKey)
  const isCurrency = metric?.unit === "currency_cents"
  const currency = (currentCompany()?.currency || "usd").toUpperCase()

  const metricOptions = metrics.map((candidate) => `
    <option value="${candidate.key}" ${candidate.key === metricKey ? "selected" : ""}>${translate(candidate.label)}</option>
  `).join("")

  return `
    <div class="space-y-5">
      <div>
        <h2 class="text-xl font-bold text-foreground">${config ? translate("Edit KPI") : translate("Add KPI")}</h2>
        <p class="text-sm text-muted-foreground mt-1">${translate("One rule: a metric, a target, and the employees it applies to.")}</p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="col-span-2 space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
          <input type="text" name="kpi_config[name]" required value="${escapeHtml(config?.name || "")}"
            placeholder="${translate("e.g. Orders sold this month")}"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
        </div>

        <div class="col-span-2 space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
          <textarea name="kpi_config[description]" rows="2"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">${escapeHtml(config?.description || "")}</textarea>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Metric")}</label>
          <select name="kpi_config[metric_key]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
            ${metricOptions}
          </select>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Target")}</label>
          <input type="number" step="0.01" min="0" name="kpi_config[target_value]"
            value="${targetValue(config, metric)}"
            placeholder="${isCurrency ? translate("Amount in") + " " + currency : translate("Optional")}"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          <p class="text-[11px] text-muted-foreground">${isCurrency ? translate("Entered in") + " " + currency : translate("Leave blank to show the number without scoring")}</p>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Weight")}</label>
          <input type="number" step="0.1" min="0.1" name="kpi_config[weight]"
            value="${config?.weight ?? 1}"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Period")}</label>
          <select name="kpi_config[period_type]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
            ${selectOptionsHTML([
              { name: translate("Month"), value: "month" },
              { name: translate("Quarter"), value: "quarter" },
              { name: translate("Year"), value: "year" }
            ], config?.period_type || "month")}
          </select>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Direction")}</label>
          <select name="kpi_config[direction]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
            ${selectOptionsHTML([
              { name: translate("Higher is better"), value: "higher_better" },
              { name: translate("Lower is better"), value: "lower_better" }
            ], config?.direction || "higher_better")}
          </select>
        </div>
      </div>

      <div class="border-t border-line pt-4">
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3">${translate("Who it applies to")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${scopeSelect({ name: "category_id", label: "Category", items: options.categories, selectedId: config?.category_id })}
          ${scopeSelect({ name: "branch_id", label: "Branch", items: options.branches, selectedId: config?.branch_id })}
          ${scopeSelect({ name: "department_id", label: "Department", items: options.departments, selectedId: config?.department_id })}
          ${scopeSelect({ name: "role_id", label: "Role", items: options.roles, selectedId: config?.role_id })}
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-2">
        <button type="button" data-action="click->modal#close"
          class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg">
          ${translate("Cancel")}
        </button>
        <button type="submit"
          class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm">
          ${translate("Save KPI")}
        </button>
      </div>
    </div>
  `
}

export const prepareKpiFormData = (form, options = {}) => {
  const formData = new FormData(form)
  const metricKey = formData.get("kpi_config[metric_key]")
  const metric = (options.metrics || []).find((candidate) => candidate.key === metricKey)
  const rawTarget = formData.get("kpi_config[target_value]")

  if (metric?.unit === "currency_cents" && rawTarget) {
    const minorFactor = isVnd() ? 1 : 100
    formData.set("kpi_config[target_value]", String(Math.round(Number(rawTarget) * minorFactor)))
  }

  return formData
}
