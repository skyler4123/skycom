import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_DiscountGroups_ShowController extends Companies_LayoutController {
  // Campaign hub — stats (budget progress, used count), lifecycle toggle
  // (Activate/Pause via PATCH), embedded paginated codes ledger with status
  // filter, per-row copy-to-clipboard and client-side CSV export.
  // Depends on BE: Companies::DiscountGroupsController#show + #update + Companies::DiscountsController#index
  // Endpoints: GET company_discount_group_path.json, PATCH company_discount_group_path,
  //   GET company_discounts_path.json?discount_group_id&status&page
  // Docs: docs/DISCOUNTS.md, docs/superpowers/specs/2026-09-22-discounts-frontend-design.md
  static targets = ["ledgerBody"]

  /** @type {any | null} */
  group = null

  /** @type {any[]} */
  discounts = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]
    this.companyId = companyId
    this.groupId = recordId
    const urlParams = new URLSearchParams(window.location.search)
    this.statusFilter = urlParams.get("status") || ""
    this.page = parseInt(urlParams.get("page[page]"), 10) || 1

    try {
      const groupResponse = await fetchJson(`${Helpers.company_discount_group_path(companyId, recordId)}.json`)
      this.group = groupResponse.discount_group

      const [ledgerResponse, usedResponse] = await Promise.all([
        fetchJson(this.ledgerUrl()),
        fetchJson(this.ledgerUrl({ status: "used" }))
      ])
      this.discounts = ledgerResponse.discounts || []
      this.ledgerPagination = ledgerResponse.pagination || {}
      this.usedCount = usedResponse.pagination?.count ?? 0

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Campaign not found.")}</div>`
          return true
        }
        return false
      })
    }
  }

  ledgerUrl(overrides = {}) {
    // pagy jsonapi nests the page param as page[page] — a flat `page` param
    // raises TypeError in Pagy::Request#resolve_page (String#dig).
    const params = new URLSearchParams({
      discount_group_id: this.groupId
    })
    const page = overrides.page || this.page
    if (page > 1) params.set("page[page]", page)
    const status = overrides.status !== undefined ? overrides.status : this.statusFilter
    if (status) params.set("status", status)
    return `${Helpers.company_discounts_path(this.companyId)}.json?${params.toString()}`
  }

  formatMoney(cents) {
    if (cents === null || cents === undefined) return "—"
    return Number(cents / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  budgetProgressHTML() {
    const g = this.group
    if (!g.total_budget_cents) {
      return `
        <div>
          <p class="text-xs font-medium text-muted-foreground">${translate("Total Budget")}</p>
          <p class="text-sm font-semibold text-foreground">—</p>
        </div>`
    }
    const pct = Math.min(100, Math.round((g.current_spent_cents / g.total_budget_cents) * 100))
    return `
      <div class="min-w-[160px] flex-1">
        <p class="text-xs font-medium text-muted-foreground">${translate("Budget")}</p>
        <p class="text-sm font-semibold text-foreground">${this.formatMoney(g.current_spent_cents)} / ${this.formatMoney(g.total_budget_cents)} (${pct}%)</p>
        <div class="mt-1 h-1.5 w-full rounded-full bg-muted">
          <div class="h-1.5 rounded-full ${pct >= 100 ? "bg-danger/100" : "bg-primary"}" style="width:${pct}%"></div>
        </div>
      </div>`
  }

  async setCampaignStatus(status) {
    try {
      await fetchJson(Helpers.company_discount_group_path(this.companyId, this.groupId), {
        method: "PATCH",
        body: { discount_group: { campaign_status: status } }
      })
      reloadThenToast({ type: "success", message: translate("Campaign updated") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update campaign") })
    }
  }

  activate() { this.setCampaignStatus("active") }
  pause() { this.setCampaignStatus("paused") }

  onStatusChange(event) {
    const params = new URLSearchParams(window.location.search)
    if (event.target.value) params.set("status", event.target.value)
    else params.delete("status")
    params.delete("page[page]")
    window.location.href = `${pathname()}?${params.toString()}`
  }

  async copyCode(event) {
    const code = event.params.code
    try {
      await navigator.clipboard.writeText(code)
      toast({ type: "success", message: `${translate("Copied")}: ${code}` })
    } catch (error) {
      toast({ type: "error", message: translate("Copy Code") })
    }
  }

  exportCsv() {
    const header = "code,status,amount_cents,used_at,customer\n"
    const rows = this.discounts.map(d =>
      [ d.code, d.status, d.amount_cents ?? "", d.used_at ?? "", d.customer?.name ?? "" ]
        .map(v => `"${String(v).replace(/"/g, '""')}"`).join(",")
    ).join("\n")
    const blob = new Blob([ header + rows ], { type: "text/csv;charset=utf-8;" })
    const link = document.createElement("a")
    link.href = URL.createObjectURL(blob)
    link.download = `discounts-${this.group?.prefix || this.groupId}.csv`
    link.click()
    URL.revokeObjectURL(link.href)
  }

  ledgerPageLink(page) {
    const params = new URLSearchParams(window.location.search)
    params.set("page[page]", page)
    return `${pathname()}?${params.toString()}`
  }

  ledgerPaginationHTML() {
    const p = this.ledgerPagination
    if (!p.last || p.last <= 1) return ""
    return `
      <div class="flex items-center justify-center gap-2 pt-4">
        ${p.previous ? `<a href="${this.ledgerPageLink(p.previous)}" class="px-3 py-1 text-sm border rounded-lg text-muted-foreground border-line hover:bg-muted cursor-pointer">‹</a>` : ""}
        <span class="text-sm text-muted-foreground">${p.page} / ${p.last}</span>
        ${p.next ? `<a href="${this.ledgerPageLink(p.next)}" class="px-3 py-1 text-sm border rounded-lg text-muted-foreground border-line hover:bg-muted cursor-pointer">›</a>` : ""}
      </div>`
  }

  statusBadge(status) {
    const styles = {
      unused: "bg-success/10 text-success ",
      pending: "bg-warning/10 text-warning ",
      used: "bg-muted text-muted-foreground ",
      expired: "bg-danger/10 text-danger "
    }
    const label = { unused: translate("Unused"), pending: translate("Pending"), used: translate("Used"), expired: translate("Expired") }[status] || status
    return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${styles[status] || styles.unused}">${label}</span>`
  }

  ledgerHTML() {
    const base = "pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground cursor-pointer"
    const statusOptions = [
      { value: "", label: translate("All") },
      { value: "unused", label: translate("Unused") },
      { value: "pending", label: translate("Pending") },
      { value: "used", label: translate("Used") },
      { value: "expired", label: translate("Expired") }
    ]

    const rows = this.discounts.map(d => `
      <tr class="hover:bg-muted/50 transition-colors">
        <td class="py-3 px-6">
          <span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${d.code}</span>
        </td>
        <td class="py-3 px-6">${this.statusBadge(d.status)}</td>
        <td class="py-3 px-6 text-sm text-foreground">${d.amount_cents != null ? this.formatMoney(d.amount_cents) : "—"}</td>
        <td class="py-3 px-6 text-sm text-muted-foreground">${d.used_at ? new Date(d.used_at).toLocaleString() : "—"}</td>
        <td class="py-3 px-6 text-sm text-muted-foreground">${d.customer?.name || "—"}</td>
        <td class="py-3 px-6 text-right">
          <button type="button" data-action="click->${this.identifier}#copyCode" data-${this.identifier}-code-param="${d.code}"
            ${tooltip(translate("Copy Code"))}
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">content_copy</span>
          </button>
        </td>
      </tr>`).join('')

    return `
      <div class="border-t border-line pt-6 mt-6">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider">${translate("Codes")} (${this.discounts.length})</h3>
          <div class="flex items-center gap-3">
            <select id="ledger-status" name="ledger-status" data-action="change->${this.identifier}#onStatusChange" class="${base}">
              ${statusOptions.map(o => `<option value="${o.value}" ${this.statusFilter === o.value ? "selected" : ""}>${o.label}</option>`).join('')}
            </select>
            <button type="button" data-action="click->${this.identifier}#exportCsv"
              class="inline-flex items-center gap-2 px-3 py-2 bg-muted text-foreground rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">download</span>${translate("Export CSV")}
            </button>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-xs text-muted-foreground border-b border-line">
                <th class="py-2 px-6 font-medium">${translate("Code")}</th>
                <th class="py-2 px-6 font-medium">${translate("Status")}</th>
                <th class="py-2 px-6 font-medium">${translate("Amount")}</th>
                <th class="py-2 px-6 font-medium">${translate("Used At")}</th>
                <th class="py-2 px-6 font-medium">${translate("Customer")}</th>
                <th class="py-2 px-6"></th>
              </tr>
            </thead>
            <tbody data-${this.identifier}-target="ledgerBody" class="divide-y divide-line">
              ${rows || `<tr><td colspan="6" class="py-8 text-center text-sm text-muted-foreground">${translate("None")}</td></tr>`}
            </tbody>
          </table>
        </div>
        ${this.ledgerPaginationHTML()}
      </div>`
  }

  contentHTML() {
    const g = this.group
    if (!g) return `<div class="p-8 text-center">${translate("Campaign not found.")}</div>`

    const lifecycleControls = `
      <div class="mt-6 flex gap-3">
        ${g.campaign_status !== "active" ? `<button type="button" data-action="click->${this.identifier}#activate"
          class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Activate")}</button>` : ""}
        ${g.campaign_status === "active" ? `<button type="button" data-action="click->${this.identifier}#pause"
          class="px-4 py-2 bg-warning/100 hover:bg-warning/90 text-warning-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Pause")}</button>` : ""}
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_discount_groups_path(this.companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Discounts")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-primary/10 /40 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">sell</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${g.name}</h2>
              <p class="font-semibold text-primary">${g.description || ""}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-primary/10 /40 px-3 py-1 text-xs font-bold text-primary uppercase">${g.prefix || g.code || "N/A"}</span>
                ${Helpers.statusBadge(g.campaign_status)}
              </div>
            </div>
          </div>

          <div class="flex flex-col sm:flex-row gap-6 border-t border-line pt-6">
            ${this.budgetProgressHTML()}
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Used")}</p>
              <p class="text-sm font-semibold text-foreground">${this.usedCount} ${translate("Codes")}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Validity")}</p>
              <p class="text-sm font-semibold text-foreground">${g.start_at ? new Date(g.start_at).toLocaleDateString() : "—"} → ${g.end_at ? new Date(g.end_at).toLocaleDateString() : "—"}</p>
            </div>
          </div>

          ${lifecycleControls}

          <div class="mt-8 flex flex-wrap justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.new_company_discount_group_path(this.companyId)}?generate_for=${g.id}"
              class="inline-flex items-center gap-2 px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">add</span>
              ${translate("Generate More Codes")}
            </a>
            <a href="${Helpers.edit_company_discount_group_path(this.companyId, g.id)}"
              class="inline-flex items-center px-6 py-2 bg-muted hover:bg-muted text-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Campaign")}
            </a>
          </div>

          ${this.ledgerHTML()}
        </div>
      </div>`
  }
}
