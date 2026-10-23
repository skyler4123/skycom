import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Workflows_EditController extends Companies_LayoutController {
  // Workflow edit form — prefilled template fields + step rows (existing steps
  // carry id; step deletion is intentionally not offered, WorkflowStepLog rows
  // are the audit trail and reference workflow_step_id).
  // Depends on BE: Companies::WorkflowsController#edit + #update
  // Endpoints: GET company_workflow_path.json, PATCH company_workflow_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["stepRows"]

  /** @type {any | null} */
  workflow = null

  /** @type {Array<{id?: string, name: string, text_color?: string, background_color?: string, colorKey?: string}>} */
  steps = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_workflow_path(companyId, recordId)}.json`)
      this.workflow = response.workflow
      this.steps = (this.workflow?.steps || []).map(s => {
         const opt = findWorkflowColorOption(s.text_color, s.background_color)
         return { id: s.id, name: s.name, text_color: s.text_color, background_color: s.background_color, colorKey: opt.key }
       })

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load workflow.")}</div>`
          return true
        }
        return false
      })
    }
  }

  addStepRow() {
    this.syncStepRowsFromDOM()
    this.steps.push({ name: "" })
    this.rerenderStepRows()
  }

  removeStepRow(event) {
    this.syncStepRowsFromDOM()

    const index = Number(event.params.index)
    const row = this.steps[index]
    if (!row) return

    if (row.id) {
      toast({ type: "warning", message: translate("Existing steps cannot be removed — they carry the workflow audit history") })
      return
    }

    this.steps.splice(index, 1)
    this.rerenderStepRows()
  }

  // Preserve typed step names across re-renders — read them back from the DOM.
  syncStepRowsFromDOM() {
    if (!this.hasStepRowsTarget) return
    this.stepRowsTarget.querySelectorAll('input[name$="][name]"]').forEach((input) => {
      const index = Number(input.name.match(/workflow_steps_attributes\]\[(\d+)\]\[name\]/)?.[1])
      if (this.steps[index]) this.steps[index].name = input.value
    })
    this.stepRowsTarget.querySelectorAll('select[data-step-color]').forEach((select) => {
      const index = Number(select.dataset.index)
      if (this.steps[index]) this.steps[index].colorKey = select.value
    })
  }

  syncColor(event) {
    const select = event.target
    const opt = WORKFLOW_STEP_COLOR_OPTIONS.find(o => o.key === select.value)
    if (!opt) return
    const row = select.closest('tr')
    const textInput = row.querySelector('input[name$="[text_color]"]')
    const bgInput = row.querySelector('input[name$="[background_color]"]')
    if (textInput) textInput.value = opt.text
    if (bgInput) bgInput.value = opt.background
  }

  stepRowHTML(step, index) {
    const baseClass = 'flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm'
    const opt = findWorkflowColorOption(step.text_color, step.background_color)
    const colorKey = step.colorKey || opt.key
    const colorSelect = WORKFLOW_STEP_COLOR_OPTIONS.map(o =>
      `<option value="${o.key}" ${o.key === colorKey ? 'selected' : ''}>${o.label}</option>`
    ).join('')
    return `
      <tr>
        <td class="py-2 px-2">
          <div class="flex items-center gap-2">
            <span class="text-xs text-slate-400 font-bold w-5">${index + 1}.</span>
            <input type="hidden" name="workflow[workflow_steps_attributes][${index}][position]" value="${index + 1}">
            <input type="hidden" name="workflow[workflow_steps_attributes][${index}][id]" value="${step.id || ''}">
            <input type="hidden" name="workflow[workflow_steps_attributes][${index}][text_color]" value="${step.text_color || opt.text}">
            <input type="hidden" name="workflow[workflow_steps_attributes][${index}][background_color]" value="${step.background_color || opt.background}">
            <input type="text" name="workflow[workflow_steps_attributes][${index}][name]" required
              value="${step.name || ''}" placeholder="${translate("e.g. Manager Approval")}" class="${baseClass}">
            <select data-step-color data-index="${index}" data-action="change->${this.identifier}#syncColor"
              class="px-2 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${colorSelect}
            </select>
          </div>
        </td>
        <td class="py-2 px-2 text-right">
          <button type="button" data-action="click->${this.identifier}#removeStepRow" data-${this.identifier}-index-param="${index}"
            class="p-1.5 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/30 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">delete</span>
          </button>
        </td>
      </tr>`
  }

  rerenderStepRows() {
    if (this.hasStepRowsTarget) this.stepRowsTarget.innerHTML = this.steps.map((step, i) => this.stepRowHTML(step, i)).join('')
  }

  stepsSectionHTML() {
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">${translate("Steps")}</h3>
          <button type="button" data-action="click->${this.identifier}#addStepRow"
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 rounded-lg text-sm font-medium cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">add</span>${translate("Add Step")}
          </button>
        </div>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Name")}</th>
              <th class="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody data-${this.identifier}-target="stepRows">
            ${this.steps.map((step, i) => this.stepRowHTML(step, i)).join('')}
          </tbody>
        </table>
      </div>`
  }

  contentHTML() {
    const w = this.workflow
    if (!w) return `<div class="p-8 text-center">${translate("Workflow not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const processTypes = ENUMS?.workflow?.process_types || [
      { name: "Purchase Process", value: "purchase_process" },
      { name: "Leave Process", value: "leave_process" }
    ]
    // Purchase-process workflows bind to `purchases` categories — one workflow
    // per category (unique index), the category is the selector.
    const categories = currentCategories().filter(c => c.resource_name === "purchases")
    if (w.category && !categories.some(c => c.id === w.category.id)) categories.push(w.category)

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Workflow")}</h2>
        <p class="text-sm text-slate-500">${w.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Name")}</label>
            <input type="text" name="workflow[name]" value="${w.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Process")}</label>
            <select name="workflow[process_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(processTypes, w.process_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</label>
            <select name="workflow[category_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(cloneNewKey(categories, "id", "value"), w.category_id || '')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="workflow[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${w.description || ''}</textarea>
          </div>
        </div>

        ${this.stepsSectionHTML()}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_workflow_path(companyId, w.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
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
          action: Helpers.company_workflow_path(companyId, w.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>`
  }
}
