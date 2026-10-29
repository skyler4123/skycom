import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Permissions_AddResourceModalController from "controllers/companies/permissions/add_resource_modal_controller"
import Companies_Permissions_EditPolicyModalController from "controllers/companies/permissions/edit_policy_modal_controller"

export default class Companies_Permissions_IndexController extends Companies_LayoutController {
  async connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) {
        this.loadData()
        return true
      }
      return false
    }, { interval: 50, maxAttempts: 100 })
  }

  async loadData() {
    const companyId = currentCompany()?.id || this.extractCompanyIdFromUrl()
    const response = await fetchJson(Helpers.company_permissions_path(companyId))
    this.roles = response.roles || []
    this.roles = Helpers.sortObjectArray(this.roles)
    this.renderContent()
  }

  extractCompanyIdFromUrl() {
    const match = window.location.pathname.match(/\/companies\/([^/]+)/)
    return match ? match[1] : null
  }

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-card rounded-xl border border-line flex flex-col">
          <div class="p-6 border-b border-line">
            <h2 class="text-xl font-semibold text-foreground">${translate("Permissions")}</h2>
            <p class="text-sm text-muted-foreground mt-1">${translate("Manage role-based permissions by toggling policies")}</p>
          </div>

          <div class="divide-y divide-line">
            ${this.roles.length === 0 ? this.emptyStateHTML() : this.rolesHTML()}
          </div>
        </div>
      </div>
    `
  }

  rolesHTML() {
    return this.roles.map(role => this.roleCardHTML(role)).join('')
  }

  roleCardHTML(role) {
    const groupedByResource = this.groupPoliciesByResource(role.policies)
    const resources = Object.keys(groupedByResource).sort()
    const assignedResources = resources

    return `
      <div class="role-section" data-role-id="${role.id}">
        <div class="px-6 py-4 bg-muted flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-foreground">${role.name}</h3>
            <p class="text-sm text-muted-foreground">${role.description || translate('No description')}</p>
          </div>
          <div class="text-sm text-muted-foreground">
            ${role.policies.filter(p => p.policy_appointment?.workflow_status === 'active').length} / ${role.policies.length} ${translate("active")}
          </div>
        </div>
        <div class="p-6 space-y-4">
          ${resources.map(resourceName => this.resourceSectionHTML(resourceName, groupedByResource[resourceName])).join('')}
        </div>
        <div class="px-6 pb-6 pt-2">
          <button
            type="button"
            data-action="click->${this.identifier}#openAddResourceModal"
            data-${this.identifier}-role-id-param="${role.id}"
            data-${this.identifier}-role-name-param="${role.name}"
            data-${this.identifier}-assigned-resources-param="${assignedResources.join(',')}"
            class="flex items-center gap-2 px-4 py-2 text-sm font-medium text-primary hover:bg-primary/10 rounded-lg transition-colors"
          >
            <span class="material-symbols-outlined text-[18px]!">add</span>
            ${translate("Add Resource")}
          </button>
        </div>
      </div>
    `
  }

  groupPoliciesByResource(policies) {
    return policies.reduce((groups, policy) => {
      const resource = policy.resource || translate('Unknown')
      if (!groups[resource]) {
        groups[resource] = []
      }
      groups[resource].push(policy)
      return groups
    }, {})
  }

  resourceSectionHTML(resourceName, policies) {
    const activeCount = policies.filter(p => p.policy_appointment?.workflow_status === 'active').length
    const totalCount = policies.length

    return `
      <div class="resource-section border border-line rounded-lg overflow-hidden">
        <details class="resource-details group" open>
          <summary class="px-4 py-3 bg-muted cursor-pointer flex items-center justify-between list-none hover:bg-muted transition-colors select-none">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-lg text-muted-foreground group-open:rotate-90 transition-transform">chevron_right</span>
              <span class="text-sm font-semibold text-foreground">${resourceName}</span>
            </div>
            <span class="text-xs text-muted-foreground">${activeCount} / ${totalCount} ${translate("active")}</span>
          </summary>
          <div class="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            ${policies.map(policy => this.policyBadgeHTML(policy)).join('')}
          </div>
        </details>
      </div>
    `
  }

  policyBadgeHTML(policy) {
    const isActive = policy.policy_appointment?.workflow_status === 'active'
    const appointmentId = policy.policy_appointment?.id
    const tagConditions = JSON.stringify(policy.tag_conditions || {})

    return `
      <button
        type="button"
        data-action="click->${this.identifier}#openEditPolicyModal"
        data-appointment-id="${appointmentId || ''}"
        data-policy-id="${policy.id}"
        data-policy-action="${policy.action}"
        data-policy-resource="${policy.resource}"
        data-tag-conditions='${tagConditions}'
        data-workflow-status="${policy.policy_appointment?.workflow_status || 'inactive'}"
        class="flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-medium transition-colors cursor-pointer ${isActive ? 'bg-primary text-primary-foreground border-primary/40 hover:bg-primary/90' : 'bg-background text-muted-foreground border-line hover:bg-muted '}"
      >
        <span class="material-symbols-outlined text-[16px]">${isActive ? 'toggle_on' : 'toggle_off'}</span>
        ${policy.action}
      </button>
    `
  }

  openEditPolicyModal(event) {
    const btn = event.currentTarget
    const p = {
      appointmentId: btn.dataset.appointmentId || '',
      policyId: btn.dataset.policyId || '',
      policyAction: btn.dataset.policyAction || '',
      policyResource: btn.dataset.policyResource || '',
      tagConditions: btn.dataset.tagConditions || '{}',
      workflowStatus: btn.dataset.workflowStatus || 'inactive'
    }
    openModal({
      html: `<div
        data-controller="${identifier(Companies_Permissions_EditPolicyModalController)}"
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-appointment-id-value="${p.appointmentId}"
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-policy-id-value="${p.policyId}"
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-action-name-value="${p.policyAction}"
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-resource-name-value="${p.policyResource}"
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-tag-conditions-value='${p.tagConditions}'
        data-${identifier(Companies_Permissions_EditPolicyModalController)}-workflow-status-value="${p.workflowStatus}"
      ></div>`
    })
  }

  emptyStateHTML() {
    return `
      <div class="p-12 text-center">
        <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
          <span class="material-symbols-outlined text-2xl text-muted-foreground">shield</span>
        </div>
        <h3 class="text-lg font-medium text-foreground mb-2">${translate("No Roles Found")}</h3>
        <p class="text-sm text-muted-foreground">${translate("Create roles first to manage permissions")}</p>
      </div>
    `
  }

  async refresh(event) {
    await this.loadData()
  }

  openAddResourceModal(event) {
    const roleId = event.params.roleId
    const roleName = event.params.roleName
    const assignedResourcesStr = event.params.assignedResources || ''
    const assignedResources = assignedResourcesStr ? assignedResourcesStr.split(',') : []

    openModal({ html: `<div
      data-controller="${identifier(Companies_Permissions_AddResourceModalController)}"
      data-${identifier(Companies_Permissions_AddResourceModalController)}-role-id-value="${roleId}"
      data-${identifier(Companies_Permissions_AddResourceModalController)}-role-name-value="${roleName}"
      data-${identifier(Companies_Permissions_AddResourceModalController)}-assigned-resources-value='${JSON.stringify(assignedResources)}'
    ></div>` })
  }
}