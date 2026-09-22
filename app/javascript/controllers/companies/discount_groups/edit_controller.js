import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_DiscountGroups_EditController extends Companies_LayoutController {
  // Campaign edit — prefilled HTML-redirect form (PATCH). No generation here;
  // "Generate More Codes" lives on the show page / rich new page.
  // Depends on BE: Companies::DiscountGroupsController#edit + #update
  // Endpoints: GET edit_company_discount_group_path.json, PATCH company_discount_group_path (HTML redirect)
  // Docs: docs/DISCOUNTS.md, docs/superpowers/specs/2026-09-22-discounts-frontend-design.md

  /** @type {any | null} */
  group = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const groupId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.company_discount_group_path(companyId, groupId)}.json`)
      this.group = response.discount_group

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Campaign not found.")}</div>`
          return true
        }
        return false
      })
    }
  }

  baseClass() {
    return "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
  }

  labelClass() {
    return "text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider"
  }

  currencies() {
    return Enums()?.discount_group?.currencies || [
      { name: "USD", value: "usd" },
      { name: "VND", value: "vnd" }
    ]
  }

  toLocalInput(iso) {
    return iso ? new Date(iso).toISOString().slice(0, 16) : ""
  }

  conditionalFieldsHTML() {
    const base = this.baseClass()
    const label = this.labelClass()
    const g = this.group

    if (g.discount_type === "percentage") {
      return `
        <div class="space-y-1">
          <label class="${label}">${translate("Percentage (%)")}</label>
          <input type="number" step="0.01" min="0" max="100" name="discount_group[percentage]" value="${g.percentage ?? ""}" class="${base}">
        </div>
        <div class="space-y-1">
          <label class="${label}">${translate("Max Cap")} (cents)</label>
          <input type="number" step="1" min="0" name="discount_group[max_amount_cents]" value="${g.max_amount_cents ?? ""}" class="${base}">
        </div>`
    }

    return `
      <div class="space-y-1">
        <label class="${label}">${translate("Amount")} (cents)</label>
        <input type="number" step="1" min="0" name="discount_group[amount_cents]" value="${g.amount_cents ?? ""}" class="${base}">
      </div>`
  }

  contentHTML() {
    const g = this.group
    if (!g) return `<div class="p-8 text-center">${translate("Campaign not found.")}</div>`

    const base = this.baseClass()
    const label = this.labelClass()
    const companyId = window.location.pathname.split("/")[2]

    // Money inputs submit cents directly (strong-param names) with a "(cents)"
    // hint — the rich New page converts dollars→cents FE-side instead.
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Campaign")}</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">${g.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="${label}">${translate("Name")}</label>
            <input type="text" name="discount_group[name]" value="${g.name || ""}" required class="${base}">
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("Prefix")}</label>
            <input type="text" name="discount_group[prefix]" value="${g.prefix || ""}" class="${base}">
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("Type")}</label>
            <input type="text" value="${g.discount_type === "percentage" ? translate("Percentage (%)") : translate("Fixed Amount")}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
          </div>

          ${this.conditionalFieldsHTML()}

          <div class="space-y-1">
            <label class="${label}">${translate("Total Budget")} (cents)</label>
            <input type="number" step="1" min="0" name="discount_group[total_budget_cents]" value="${g.total_budget_cents ?? ""}" class="${base}">
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("Currency")}</label>
            <select name="discount_group[currency]" class="${base} cursor-pointer">
              ${this.currencies().map(c => `<option value="${c.value}" ${g.currency === c.value ? "selected" : ""}>${c.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("Start At")}</label>
            <input type="datetime-local" name="discount_group[start_at]" value="${this.toLocalInput(g.start_at)}" class="${base}">
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("End At")}</label>
            <input type="datetime-local" name="discount_group[end_at]" value="${this.toLocalInput(g.end_at)}" class="${base}">
          </div>

          <div class="space-y-1">
            <label class="${label}">${translate("Status")}</label>
            <select name="discount_group[campaign_status]" class="${base} cursor-pointer">
              ${[ "draft", "active", "paused" ].map(s => `<option value="${s}" ${g.campaign_status === s ? "selected" : ""}>${s}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="${label}">${translate("Description")}</label>
            <textarea name="discount_group[description]" rows="3" class="${base}">${g.description || ""}</textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_discount_group_path(companyId, g.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_discount_group_path(companyId, g.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>`
  }
}
