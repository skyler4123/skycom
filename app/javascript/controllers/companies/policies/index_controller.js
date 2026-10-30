import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Policies_IndexController extends Companies_LayoutController {
  static targets = ["policiesList"]

  async connect() {
    super.connect()
    const response = await fetchJson();
    this.policies = response.policies || []
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-card rounded-xl border border-line flex flex-col">

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground bg-muted border-b border-line">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Policy Name")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Resource")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Action")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Branch")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Status")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="policiesList" class="divide-y divide-line">
                ${this.policiesHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-line flex items-center justify-between">
            <span class="text-sm text-muted-foreground">${translate("Showing")} ${this.policies.length} ${translate("policies")}</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-line rounded-lg text-muted-foreground cursor-not-allowed" disabled>${translate("Previous")}</button>
              <button class="px-3 py-1 text-sm border border-line rounded-lg text-muted-foreground hover:bg-muted transition-colors">${translate("Next")}</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  policiesHTML() {
    if (this.policies.length === 0) {
      return `<tr><td colspan="5" class="text-center py-4 text-muted-foreground">${translate("No policies found")}</td></tr>`
    }
    return this.policies.map(policy => `
      <tr class="hover:bg-muted/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex flex-col">
            <p class="font-medium text-foreground">${policy.name}</p>
            <p class="text-xs text-muted-foreground">${policy.code || translate('No code')}</p>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-muted-foreground">${policy.resource}</td>
        <td class="py-4 px-6 text-sm text-muted-foreground">${policy.action}</td>
        <td class="py-4 px-6 text-sm">
          <span class="text-foreground">${policy.branch ? policy.branch.name : translate('All branches')}</span>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(policy.lifecycle_status)}
        </td>
      </tr>
    `).join('')
  }
}
