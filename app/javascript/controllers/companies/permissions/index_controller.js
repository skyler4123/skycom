import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Permissions_IndexController extends Companies_LayoutController {
  async connect() {
    super.connect()
    await this.loadData()
  }

  async loadData() {
    const response = await fetchJson(Helpers.company_permissions_path(currentCompany().id))
    this.roles = response.roles || []
    this.authorized = response.authorized || false
    this.renderContent()
  }

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="p-6 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-xl font-semibold text-slate-900 dark:text-white">Permissions</h2>
            <p class="text-sm text-slate-500 mt-1">Manage role-based permissions by toggling policies</p>
          </div>

          <div class="divide-y divide-slate-200 dark:divide-slate-800">
            ${!this.authorized ? this.noAccessHTML() : (this.roles.length === 0 ? this.emptyStateHTML() : this.rolesHTML())}
          </div>
        </div>
      </div>
    `
  }

  noAccessHTML() {
    return `
      <div class="p-12 text-center">
        <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
          <span class="material-symbols-outlined text-2xl text-red-500">block</span>
        </div>
        <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-2">No Access</h3>
        <p class="text-sm text-slate-500">You don't have permission to manage permissions</p>
      </div>
    `
  }

  rolesHTML() {
    return this.roles.map(role => this.roleCardHTML(role)).join('')
  }

  roleCardHTML(role) {
    return `
      <div class="role-section" data-role-id="${role.id}">
        <div class="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-900 dark:text-white">${role.name}</h3>
            <p class="text-sm text-slate-500">${role.description || 'No description'}</p>
          </div>
          <div class="text-sm text-slate-500">
            ${role.policies.filter(p => p.policy_appointment?.workflow_status === 'active').length} / ${role.policies.length} active
          </div>
        </div>
        <div class="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${role.policies.map(policy => this.policyCheckboxHTML(role.id, policy)).join('')}
        </div>
      </div>
    `
  }

  policyCheckboxHTML(roleId, policy) {
    const isActive = policy.policy_appointment?.workflow_status === 'active'
    const appointmentId = policy.policy_appointment?.id
    const companyId = currentCompany().id
    const newStatus = isActive ? 'inactive' : 'active'
    const actionUrl = Helpers.edit_company_permission_path(companyId, appointmentId)

    return `
      <label class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50 ${!this.authorized ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'} transition-colors">
        ${Helpers.form({
          action: actionUrl,
          method: 'PATCH',
          className: 'flex items-center gap-3',
          html: `
            <input type="hidden" name="policy_appointment[workflow_status]" value="${newStatus}" />
            <input 
              type="checkbox" 
              class="w-4 h-4 text-blue-600 border-slate-300 rounded focus:ring-blue-600 dark:border-slate-600 dark:bg-slate-800"
              data-action="change->form#submit"
              ${isActive ? 'checked' : ''}
              ${!this.authorized ? 'disabled' : ''}
            />
          `
        })}
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-slate-900 dark:text-white truncate">${policy.name}</p>
          <p class="text-xs text-slate-500">${policy.resource} · ${policy.action}</p>
        </div>
      </label>
    `
  }

  emptyStateHTML() {
    return `
      <div class="p-12 text-center">
        <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
          <span class="material-symbols-outlined text-2xl text-slate-400">shield</span>
        </div>
        <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-2">No Roles Found</h3>
        <p class="text-sm text-slate-500">Create roles first to manage permissions</p>
      </div>
    `
  }

  async refresh(event) {
    await this.loadData()
  }
}