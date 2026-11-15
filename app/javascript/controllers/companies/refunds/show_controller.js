import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Refunds_ShowController extends Companies_LayoutController {
  refund = null

  async connect() {
    super.connect()

    const id = window.location.pathname.split('/').pop()
    try {
      const response = await fetchJson(`${Helpers.company_refund_path(currentCompany().id, id)}.json`)
      this.refund = response.refund || null
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load refund") })
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
    const r = this.refund || {}
    const steps = r.workflow_steps || []
    const logs = r.workflow_step_logs || []
    const currentStep = r.current_workflow_step

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line space-y-6">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold text-foreground">${r.name || translate("Refund")}</h2>
            <span class="px-3 py-1 rounded-full text-xs font-bold bg-muted text-muted-foreground">${r.workflow_status || '—'}</span>
          </div>

          <div class="grid grid-cols-2 gap-4 text-sm">
            <div><span class="text-muted-foreground">${translate("Type")}:</span> ${r.refund_type || '—'}</div>
            <div><span class="text-muted-foreground">${translate("Amount")}:</span> ${r.money_amount_cents ?? '—'}</div>
            <div><span class="text-muted-foreground">${translate("Reason")}:</span> ${r.reason || '—'}</div>
            <div><span class="text-muted-foreground">${translate("Customer")}:</span> ${r.customer?.name || '—'}</div>
          </div>

          ${steps.length ? `
            <div class="border-t border-line pt-4">
              <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-3">${translate("Workflow")}</h3>
              <div class="flex flex-wrap gap-2">
                ${steps.map(s => `<span class="px-3 py-1 rounded-lg text-xs font-medium ${s.id === currentStep?.id ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground'}">${s.name}</span>`).join('')}
              </div>
            </div>
          ` : ''}

          ${logs.length ? `
            <div class="border-t border-line pt-4">
              <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-3">${translate("Audit Log")}</h3>
              <ul class="space-y-2 text-sm">
                ${logs.map(l => `<li class="text-muted-foreground">${l.created_at} — ${l.outcome} ${l.step_name ? '(' + l.step_name + ')' : ''} ${l.employee_name ? 'by ' + l.employee_name : ''}</li>`).join('')}
              </ul>
            </div>
          ` : ''}

          <div class="flex gap-3 pt-4 border-t border-line">
            <button data-action="click->${this.identifier}#advance" data-outcome="approved"
              class="px-4 py-2 bg-success text-success-foreground rounded-lg text-sm font-bold cursor-pointer">${translate("Approve")}</button>
            <button data-action="click->${this.identifier}#advance" data-outcome="rejected"
              class="px-4 py-2 bg-danger text-danger-foreground rounded-lg text-sm font-bold cursor-pointer">${translate("Reject")}</button>
          </div>
        </div>
      </div>
    `
  }

  async advance(event) {
    const outcome = event.currentTarget.dataset.outcome
    const id = window.location.pathname.split('/').pop()
    try {
      const response = await fetchJson(Helpers.advance_company_refund_path(currentCompany().id, id), {
        method: "POST",
        body: JSON.stringify({ outcome })
      })
      toast({ type: "success", message: response.message || translate("Updated") })
      window.location.reload()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed") })
    }
  }
}