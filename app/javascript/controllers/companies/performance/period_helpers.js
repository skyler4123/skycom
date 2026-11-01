export const PERIOD_PRESETS = [
  { key: "this_month", label: "This month" },
  { key: "last_month", label: "Last month" },
  { key: "this_quarter", label: "This quarter" },
  { key: "last_quarter", label: "Last quarter" },
  { key: "this_year", label: "This year" },
  { key: "custom", label: "Custom" }
]

export const periodQueryParams = ({ period, from, to }) => {
  const params = { period }
  if (period === "custom") {
    params.from = from
    params.to = to
  }
  return params
}

export const periodSelectorHTML = ({ identifierName, period, from, to }) => {
  const options = PERIOD_PRESETS.map((preset) => `
    <option value="${preset.key}" ${preset.key === period ? "selected" : ""}>${translate(preset.label)}</option>
  `).join("")

  return `
    <div class="flex flex-col gap-3 sm:flex-row sm:items-end">
      <div class="space-y-1">
        <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Period")}</label>
        <select data-period-select data-action="change->${identifierName}#onPeriodChange"
          class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
          ${options}
        </select>
      </div>

      ${period === "custom" ? `
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("From")}</label>
          <input type="date" value="${from || ""}" data-period-from
            class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground">
        </div>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("To")}</label>
          <input type="date" value="${to || ""}" data-period-to
            class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground">
        </div>
        <button type="button" data-action="click->${identifierName}#applyCustom"
          class="h-[38px] px-4 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
          ${translate("Apply")}
        </button>
      ` : ""}
    </div>
  `
}

export const formatAchievement = (value) => {
  if (value === null || value === undefined) return "—"
  return `${Number(value).toFixed(1)}%`
}

export const compositeTone = (value) => {
  if (value === null || value === undefined) return "text-muted-foreground"
  if (Number(value) >= 100) return "text-success"
  if (Number(value) >= 70) return "text-warning"
  return "text-danger"
}
