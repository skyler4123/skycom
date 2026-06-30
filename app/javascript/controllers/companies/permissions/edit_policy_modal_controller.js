import { Controller } from "@hotwired/stimulus"

export default class Companies_Permissions_EditPolicyModalController extends Controller {
  static values = {
    appointmentId: { type: String, default: '' },
    policyId: { type: String, default: '' },
    actionName: { type: String, default: '' },
    resourceName: { type: String, default: '' },
    tagConditions: { type: Object, default: {} },
    workflowStatus: { type: String, default: 'inactive' }
  }

  isActive = false

  connect() {
    this.isActive = this.workflowStatusValue === 'active'
    this.element.innerHTML = this.contentHTML()
  }

  toggleStatus() {
    this.isActive = !this.isActive
    const toggle = this.element.querySelector('[data-status-toggle]')
    const indicator = this.element.querySelector('[data-status-indicator]')
    if (toggle) {
      toggle.className = this.isActive
        ? 'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium bg-blue-600 text-white cursor-pointer'
        : 'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-400 cursor-pointer'
      toggle.innerHTML = this.isActive
        ? '<span class="material-symbols-outlined text-[16px] leading-none">toggle_on</span> Active'
        : '<span class="material-symbols-outlined text-[16px] leading-none">toggle_off</span> Inactive'
    }
    if (indicator) {
      indicator.textContent = this.isActive ? 'Active' : 'Inactive'
    }
  }

  addTagRow() {
    const container = this.element.querySelector('[data-tag-rows]')
    if (!container) return
    const row = document.createElement('div')
    row.setAttribute('data-tag-row', '')
    row.className = 'flex items-center gap-2'
    row.innerHTML = `
      <input type="text" data-tag-key placeholder="Key" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
      <input type="text" data-tag-value placeholder="Value" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
      <button type="button" data-action="click->${this.identifier}#removeTagRow" class="p-2 text-slate-400 hover:text-red-500 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 cursor-pointer">
        <span class="material-symbols-outlined text-[18px]">close</span>
      </button>
    `
    container.appendChild(row)
    row.querySelector('[data-tag-key]').focus()
  }

  removeTagRow(event) {
    const row = event.currentTarget.closest('[data-tag-row]')
    if (row) row.remove()
  }

  async handleSubmit(event) {
    event.preventDefault()

    const tagConditions = {}
    this.element.querySelectorAll('[data-tag-row]').forEach(row => {
      const key = row.querySelector('[data-tag-key]').value.trim()
      const value = row.querySelector('[data-tag-value]').value.trim()
      if (key) tagConditions[key] = value
    })

    try {
      await fetchJson(Helpers.edit_company_permission_path(
        currentCompany().id, this.appointmentIdValue
      ), {
        method: "PATCH",
        body: {
          policy_appointment: { workflow_status: this.isActive },
          policy: { tag_conditions: tagConditions }
        }
      })

      reloadThenToast({ type: "success", message: `${this.actionNameValue} permission updated` })
    } catch (error) {
      toast({ type: "error", message: error.error || "Failed to update permission" })
    }
  }

  tagRowsHTML() {
    const entries = Object.entries(this.tagConditionsValue || {})
    if (entries.length === 0) {
      return `
        <div data-tag-row class="flex items-center gap-2">
          <input type="text" data-tag-key placeholder="Key" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
          <input type="text" data-tag-value placeholder="Value" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
          <button type="button" data-action="click->${this.identifier}#removeTagRow" class="p-2 text-slate-400 hover:text-red-500 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
      `
    }
    return entries.map(([key, value]) => `
      <div data-tag-row class="flex items-center gap-2">
        <input type="text" data-tag-key value="${key}" placeholder="Key" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
        <input type="text" data-tag-value value="${value ?? ''}" placeholder="Value" class="flex-1 min-w-0 px-3 py-2 text-sm border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 placeholder-slate-400">
        <button type="button" data-action="click->${this.identifier}#removeTagRow" class="p-2 text-slate-400 hover:text-red-500 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 cursor-pointer">
          <span class="material-symbols-outlined text-[18px]">close</span>
        </button>
      </div>
    `).join('')
  }

  contentHTML() {
    return `
      <div class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[640px] shadow-2xl">
        <div class="space-y-6">
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white capitalize">${this.actionNameValue} ${this.resourceNameValue}</h2>
            <p class="text-sm text-slate-500 mt-1">Configure permission and tag conditions</p>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Status</label>
            <button
              type="button"
              data-action="click->${this.identifier}#toggleStatus"
              data-status-toggle
              class="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium cursor-pointer ${this.isActive ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-400'}"
            >
              <span class="material-symbols-outlined text-[16px] leading-none">${this.isActive ? 'toggle_on' : 'toggle_off'}</span>
              <span data-status-indicator>${this.isActive ? 'Active' : 'Inactive'}</span>
            </button>
          </div>

          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Tag Conditions</label>
              <button
                type="button"
                data-action="click->${this.identifier}#addTagRow"
                class="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg cursor-pointer"
              >
                <span class="material-symbols-outlined text-[14px]">add</span>
                Add Condition
              </button>
            </div>
            <div class="p-3 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-slate-200 dark:border-slate-700 space-y-2" data-tag-rows>
              ${this.tagRowsHTML()}
            </div>
            <p class="text-[11px] text-slate-400">Tag conditions use AND logic. Leave empty for no tag filtering.</p>
          </div>

          <div class="flex justify-end gap-3 pt-2">
            <button type="button" data-action="click->modal#close" class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
              Cancel
            </button>
            <button type="button" data-action="click->${this.identifier}#handleSubmit" class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
              Save
            </button>
          </div>
        </div>
      </div>
    `
  }
}
