import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Tickets_ShowController extends Companies_LayoutController {
  // Ticket detail — read-only ticket view + Jira-style advance controls
  // (Approve / Reject / Rework via POST advance → Workflows::AdvanceService).
  // Depends on BE: Companies::TicketsController#show (workflow steps + logs) + #advance
  // Endpoints: GET company_ticket_path.json, POST advance_company_ticket_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  /** @type {any | null} */
  ticket = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_ticket_path(companyId, recordId)}.json`)
      this.ticket = response.ticket

      const channel = window.WEBSOCKET && WEBSOCKET.channelName("company", companyId)
      if (channel) {
        try {
          WEBSOCKET.subscribe(channel, "ticket_commented", (data) => this.handleSocketComment(data))
          WEBSOCKET.subscribe(channel, "ticket_workflow_step_changed", () => this.refresh())
        } catch (e) { /* socket unavailable */ }
      }

      if (this.ticket?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.ticket.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load ticket.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  advanceable() {
    const status = this.ticket?.workflow_status
    return !!this.ticket?.workflow && status !== "completed" && status !== "cancelled"
  }

  async advance(outcome, targetStepId = null) {
    const companyId = window.location.pathname.split("/")[2]
    try {
      const response = await fetchJson(Helpers.advance_company_ticket_path(companyId, this.ticket.id), {
        method: "POST",
        body: {
          outcome,
          note: this.element.querySelector("#advance-note")?.value || null,
          target_step_id: targetStepId || null
        }
      })
      reloadThenToast({ type: "success", message: response.message || translate("Ticket advanced") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to advance ticket") })
    }
  }

  async refresh() {
    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]
    try {
      const response = await fetchJson(`${Helpers.company_ticket_path(companyId, recordId)}.json`)
      this.ticket = response.ticket
      if (this.hasContentTarget) this.renderContent()
    } catch (e) { /* ignore */ }
  }

  handleSocketComment(data) {
    if (!this.ticket || data?.id !== this.ticket.id) return
    const c = data.payload?.comment || data.comment
    if (!c?.id) return
    if ((this.ticket.comments || []).some((x) => x.id === c.id)) return
    this.ticket.comments = [...(this.ticket.comments || []), c].sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
    if (this.hasContentTarget) this.renderContent()
  }

  async handleCommentSubmit(event) {
    event.preventDefault()
    const formEl = event.target
    const companyId = window.location.pathname.split("/")[2]
    try {
      const response = await fetchJson(Helpers.company_ticket_comments_path(companyId), {
        method: "POST",
        body: new FormData(formEl)
      })
      const c = response.ticket_comment
      if (c?.id) {
        if (!(this.ticket.comments || []).some((x) => x.id === c.id)) {
          this.ticket.comments = [...(this.ticket.comments || []), c].sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
        }
      }
      formEl.reset()
      if (this.hasContentTarget) this.renderContent()
      toast({ type: "success", message: translate("Comment posted") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to post comment") })
    }
  }

  approve() { this.advance("approved") }
  reject() { this.advance("rejected") }
  rework() { this.advance("rework", this.element.querySelector("#rework-target")?.value || null) }

  formatMoney(value) {
    return Number(value || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  outcomeBadge(outcome) {
    const styles = {
      submitted: "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300",
      approved: "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
      rejected: "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400",
      rework: "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
    }
    return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md capitalize ${styles[outcome] || styles.submitted}">${outcome}</span>`
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400'}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        return `<span class="text-sm text-slate-900 dark:text-white">${new Date(value).toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  showHTML() {
    const p = this.ticket
    if (!p) return `<div class="p-8 text-center">${translate("Ticket not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === p.category_id)
    const currentId = p.current_workflow_step?.id

    const itemsTable = ""

    const workflowSection = p.workflow ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Workflow")}: ${p.workflow.name}</h3>
        <div class="flex flex-wrap gap-2">
          ${(p.workflow_steps || []).map(s => `
            <span class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium border cursor-default ${s.id === currentId
               ? (s.background_color || "bg-blue-50 dark:bg-blue-900/30") + " " + (s.text_color || "text-blue-700 dark:text-blue-300") + " border-blue-300 dark:border-blue-700"
               : (s.background_color || "bg-slate-50 dark:bg-slate-800") + " " + (s.text_color || "text-slate-500 dark:text-slate-400") + " border-slate-200 dark:border-slate-700"}">
              ${s.position}. ${s.name}
            </span>`).join('')}
        </div>
      </div>` : ""

    const logsSection = (p.workflow_step_logs || []).length ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("History")}</h3>
        <div class="space-y-2">
          ${p.workflow_step_logs.map(log => `
            <div class="flex items-center gap-3 text-sm">
              ${this.outcomeBadge(log.outcome)}
              <span class="font-medium text-slate-900 dark:text-white">${log.step_name || "—"}</span>
              <span class="text-slate-500">${log.employee_name || "—"}</span>
              ${log.note ? `<span class="text-slate-500 italic">"${log.note}"</span>` : ""}
              <span class="text-xs text-slate-400 ml-auto">${new Date(log.created_at).toLocaleString()}</span>
            </div>`).join('')}
        </div>
      </div>` : ""

    const advanceControls = this.advanceable() ? `
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <input type="text" id="advance-note" placeholder="${translate("Note (optional)")}"
          class="flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
        <select id="rework-target"
          class="px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm cursor-pointer">
          ${(p.workflow_steps || []).map(s => `<option value="${s.id}">${s.position}. ${s.name}</option>`).join('')}
        </select>
        <button type="button" data-action="click->${this.identifier}#approve"
          class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Approve")}</button>
        <button type="button" data-action="click->${this.identifier}#reject"
          class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Reject")}</button>
        <button type="button" data-action="click->${this.identifier}#rework"
          class="px-4 py-2 bg-amber-500 hover:bg-amber-600 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Rework")}</button>
      </div>` : ""

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.name}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDisplayValue(p[field.key], field.type)}</p>
              </div>
            </div>`).join('')}
        </div>
      </div>` : ""

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_tickets_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Tickets")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-emerald-100 dark:bg-gray-800 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-emerald-600 dark:text-emerald-400">shopping_cart</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${p.name}</h2>
              <p class="font-semibold text-emerald-600 dark:text-emerald-400">${p.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-emerald-100 dark:bg-emerald-900/40 px-3 py-1 text-xs font-bold text-emerald-700 dark:text-emerald-300 uppercase">${p.code || "N/A"}</span>
                ${Helpers.statusBadge(p.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || p.category?.name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">local_shipping</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Supplier")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${p.supplier?.name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">event</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Needed By")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${p.needed_by ? new Date(p.needed_by).toLocaleString() : "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">payments</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Total")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatMoney(p.total_price)}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}
          ${workflowSection}
          ${logsSection}

          <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Comments")}</h3>
        <div class="space-y-3 mb-4">
          ${(p.comments || []).map(c => `
            <div class="p-3 rounded-lg bg-slate-50 dark:bg-slate-800">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-xs font-bold text-slate-700 dark:text-slate-300">${c.employee_name || "—"}</span>
                <span class="text-xs text-slate-400">${new Date(c.created_at).toLocaleString()}</span>
              </div>
              <p class="text-sm text-slate-900 dark:text-white">${c.message}</p>
            </div>`).join('')}
        </div>
        <form data-action="submit->${this.identifier}#handleCommentSubmit" class="flex gap-2">
          <input type="hidden" name="ticket_comment[ticket_id]" value="${p.id}">
          <input type="text" name="ticket_comment[message]" placeholder="${translate("Write a comment...")}"
            class="flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm" required>
          <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">${translate("Post")}</button>
        </form>
      </div>

      ${advanceControls ? `<div class="mt-8 pt-6 border-t border-slate-200 dark:border-gray-800">${advanceControls}</div>` : ""}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_ticket_path(companyId, p.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Ticket")}
            </a>
          </div>
        </div>
      </div>`
  }
}
