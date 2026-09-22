import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_DiscountGroups_NewController extends Companies_LayoutController {
  // Rich campaign page — create mode (Phase 1 config → Phase 2 batch generation)
  // and generate mode (?generate_for=<id> — read-only summary + generation only).
  // Depends on BE: Companies::DiscountGroupsController#new (shell) + #show (generate mode)
  //   + #create (JSON) + #generate_codes (JSON)
  // Endpoints: GET new_company_discount_group_path.json, GET company_discount_group_path.json,
  //   POST create_company_discount_groups_path, POST generate_codes_company_discount_group_path
  // Docs: docs/DISCOUNTS.md, docs/superpowers/specs/2026-09-22-discounts-frontend-design.md
  static targets = ["conditionalFields"]

  /** @type {"create" | "generate"} */
  mode = "create"

  /** @type {"config" | "generate"} */
  phase = "config"

  /** @type {any | null} */
  group = null

  /** @type {string | null} */
  generateForId = null

  async connect() {
    super.connect()

    this.generateForId = new URLSearchParams(window.location.search).get("generate_for")
    this.mode = this.generateForId ? "generate" : "create"
    if (this.mode === "generate") this.phase = "generate"

    if (this.mode === "generate") {
      try {
        const response = await fetchJson(`${Helpers.company_discount_group_path(currentCompany().id, this.generateForId)}.json`)
        this.group = response.discount_group
      } catch (error) {
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load campaign") })
      }
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  baseClass() {
    return "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"
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

  field(name) {
    return this.element.querySelector(`[name="${name}"]`)?.value?.trim() || ""
  }

  dollarsToCents(value) {
    const parsed = parseFloat(value)
    return Number.isFinite(parsed) ? Math.round(parsed * 100) : null
  }

  formatMoney(cents) {
    if (cents === null || cents === undefined) return "—"
    return Number(cents / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  selectedDiscountType() {
    return this.field("discount_group_discount_type") || "fixed_amount"
  }

  onDiscountTypeChange() {
    if (this.hasConditionalFieldsTarget) this.conditionalFieldsTarget.innerHTML = this.conditionalFieldsHTML()
  }

  conditionalFieldsHTML() {
    const type = this.mode === "create" ? this.selectedDiscountType() : this.group?.discount_type
    const base = this.baseClass()
    const label = this.labelClass()

    if (type === "percentage") {
      return `
        <div class="space-y-1">
          <label class="${label}">${translate("Percentage (%)")}</label>
          <input type="number" step="0.01" min="0" max="100" name="discount_group_percentage" placeholder="10" class="${base}">
        </div>
        <div class="space-y-1">
          <label class="${label}">${translate("Max Cap")}</label>
          <input type="number" step="0.01" min="0" name="discount_group_max_cap" class="${base}">
        </div>`
    }

    return `
      <div class="space-y-1">
        <label class="${label}">${translate("Amount")}</label>
        <input type="number" step="0.01" min="0" name="discount_group_amount" class="${base}">
      </div>`
  }

  configFormHTML() {
    const base = this.baseClass()
    const label = this.labelClass()
    const currencies = this.currencies()

    return `
      <div class="grid grid-cols-2 gap-4">
        <div class="col-span-2 space-y-1">
          <label class="${label}">${translate("Name")}</label>
          <input type="text" name="discount_group_name" required placeholder="${translate("New Year Event")}" class="${base}">
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("Prefix")}</label>
          <input type="text" name="discount_group_prefix" placeholder="NY26" class="${base}">
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("Type")}</label>
          <select name="discount_group_discount_type" data-action="change->${this.identifier}#onDiscountTypeChange" class="${base} cursor-pointer">
            <option value="fixed_amount">${translate("Fixed Amount")}</option>
            <option value="percentage">${translate("Percentage (%)")}</option>
          </select>
        </div>

        <div id="conditional-fields" data-${this.identifier}-target="conditionalFields" class="contents">
          ${this.conditionalFieldsHTML()}
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("Total Budget")}</label>
          <input type="number" step="0.01" min="0" name="discount_group_total_budget" class="${base}">
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("Currency")}</label>
          <select name="discount_group_currency" class="${base} cursor-pointer">
            ${currencies.map(c => `<option value="${c.value}">${c.name}</option>`).join('')}
          </select>
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("Start At")}</label>
          <input type="datetime-local" name="discount_group_start_at" class="${base}">
        </div>

        <div class="space-y-1">
          <label class="${label}">${translate("End At")}</label>
          <input type="datetime-local" name="discount_group_end_at" class="${base}">
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${label}">${translate("Description")}</label>
          <textarea name="discount_group_description" rows="3" class="${base}"></textarea>
        </div>
      </div>`
  }

  summaryCardHTML() {
    const g = this.group
    const value = g.discount_type === "percentage" ? `${g.percentage}%` : this.formatMoney(g.amount_cents)
    return `
      <div class="flex items-center gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
        <div class="flex size-12 shrink-0 items-center justify-center rounded-lg bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400">
          <span class="material-symbols-outlined">sell</span>
        </div>
        <div class="min-w-0">
          <p class="font-bold text-slate-900 dark:text-white">${g.name}</p>
          <p class="text-sm text-slate-500 dark:text-slate-400">
            ${g.prefix ? `<span class="font-mono">${g.prefix}</span> · ` : ""}${value} · ${this.formatMoney(g.total_budget_cents)} ${translate("Total Budget")}
          </p>
        </div>
      </div>`
  }

  generatePanelHTML() {
    const base = this.baseClass()
    const label = this.labelClass()
    return `
      <div class="space-y-4 pt-6 border-t border-slate-200 dark:border-slate-700">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">${translate("Generate Codes")}</h3>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="${label}">${translate("Quantity")}</label>
            <input type="number" min="1" max="1000" step="1" id="generate-quantity" name="generate-quantity" placeholder="10" class="${base}">
          </div>
          <div class="space-y-1">
            <label class="${label}">${translate("Code Length")}</label>
            <input type="number" min="4" max="64" step="1" id="generate-code-length" name="generate-code-length" placeholder="8" class="${base}">
          </div>
        </div>
        <div class="flex justify-end gap-3">
          ${this.mode === "create" ? `<a href="${Helpers.company_discount_group_path(currentCompany().id, this.group.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">${translate("Skip")}</a>` : ""}
          <button type="button" data-action="click->${this.identifier}#submitGenerate"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Generate Codes")}
          </button>
        </div>
      </div>`
  }

  async submitCampaign(event) {
    event.preventDefault()

    const payload = {
      discount_group: {
        name: this.field("discount_group_name"),
        description: this.field("discount_group_description"),
        prefix: this.field("discount_group_prefix"),
        discount_type: this.selectedDiscountType(),
        currency: this.field("discount_group_currency") || "usd",
        start_at: this.field("discount_group_start_at") || null,
        end_at: this.field("discount_group_end_at") || null
      }
    }

    const budgetCents = this.dollarsToCents(this.field("discount_group_total_budget"))
    if (budgetCents) payload.discount_group.total_budget_cents = budgetCents

    if (payload.discount_group.discount_type === "fixed_amount") {
      payload.discount_group.amount_cents = this.dollarsToCents(this.field("discount_group_amount"))
    } else {
      payload.discount_group.percentage = parseFloat(this.field("discount_group_percentage"))
      const maxCapCents = this.dollarsToCents(this.field("discount_group_max_cap"))
      if (maxCapCents) payload.discount_group.max_amount_cents = maxCapCents
    }

    try {
      const response = await fetchJson(Helpers.create_company_discount_groups_path(currentCompany().id), {
        method: "POST",
        body: payload
      })
      this.group = response.discount_group
      this.phase = "generate"
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create campaign") })
    }
  }

  async submitGenerate() {
    const quantity = parseInt(this.field("generate-quantity"), 10)
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 1000) {
      toast({ type: "warning", message: translate("Quantity must be between 1 and 1000") })
      return
    }

    const codeLengthRaw = this.field("generate-code-length")
    const codeLength = codeLengthRaw ? parseInt(codeLengthRaw, 10) : null

    try {
      const response = await fetchJson(Helpers.generate_codes_company_discount_group_path(currentCompany().id, this.group.id), {
        method: "POST",
        body: { quantity, code_length: codeLength }
      })
      // Queue the toast in localStorage — the show page's toasts_controller displays it on load.
      const pending = JSON.parse(localStorage.getItem("pending_toasts") || "[]")
      pending.push({ type: "success", message: response.message || translate("Codes generated") })
      localStorage.setItem("pending_toasts", JSON.stringify(pending))
      window.location.href = Helpers.company_discount_group_path(currentCompany().id, this.group.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to generate codes") })
    }
  }

  contentHTML() {
    if (this.mode === "generate" && !this.group) {
      return `<div class="p-8 text-center text-red-600">${translate("Campaign not found.")}</div>`
    }

    if (this.phase === "generate" && this.group) {
      return `
        <div class="p-4 overflow-y-auto">
          <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Campaign")} — ${this.group.name}</h2>
            ${this.summaryCardHTML()}
            ${this.generatePanelHTML()}
          </div>
        </div>`
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: "#",
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->${this.identifier}#submitCampaign"`,
            html: `
              <div class="space-y-6">
                <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Campaign")}</h2>
                ${this.configFormHTML()}
                <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
                  <button type="submit"
                    class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
                    ${translate("Save Campaign")}
                  </button>
                </div>
              </div>`
          })}
        </div>
      </div>`
  }
}
