import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Workflows_NewController extends Companies_LayoutController {
  // Workflow creation form — template fields + ordered step rows.
  // Depends on BE: Companies::WorkflowsController#create (nested steps)
  // Endpoints: POST create_company_workflows_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["stepRows"]

  /** @type {Array<{name: string}>} */
  steps = []

  connect() {
    super.connect()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  addStepRow() {
    this.steps.push({ name: "" })
    this.rerenderStepRows()
  }

  removeStepRow(event) {
    this.steps.splice(Number(event.params.index), 1)
    this.rerenderStepRows()
  }

  stepRowHTML(step, index) {
    const baseClass = 'flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm'
    return `
      <tr>
        <td class="py-2 px-2">
          <div class="flex items-center gap-2">
            <span class="text-xs text-slate-400 font-bold w-5">${index + 1}.</span>
            <input type="hidden" name="workflow[workflow_steps_attributes][${index}][position]" value="${index + 1}">
            <input type="text" name="workflow[workflow_steps_attributes][${index}][name]" required
              value="${step.name || ''}" placeholder="${translate("e.g. Manager Approval")}" class="${baseClass}">
          </div>
        </td>
        <td class="py-2 px-2 text-right">
          <button type="button" data-action="click->${this.identifier}#removeStepRow" data-${this.identifier}-index-param="${index}"
            class="p-1.5 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/30 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">delete</span>
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
            <span class="material-symbols-outlined text-[18px]">add</span>${translate("Add Step")}
          </button>
        </div>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Name")}</th>
              <th class="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody data-${this.identifier}-target="stepRows"></tbody>
        </table>
      </div>`
  }

  contentHTML() {
    const processTypes = Enums()?.workflow?.process_types || [
      { name: "Purchase Process", value: "purchase_process" },
      { name: "Leave Process", value: "leave_process" }
    ]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Workflow")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="workflow[name]" required placeholder="${translate("e.g. Standard Purchase Process")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Process")}</label>
            <select name="workflow[process_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              ${processTypes.map(t => `<option value="${t.value}">${t.name}</option>`).join('')}
            </select>
          </div>

          <div class="flex items-center gap-3 py-2 mt-auto">
            <input type="hidden" name="workflow[is_default]" value="false">
            <input type="checkbox" name="workflow[is_default]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${translate("Default")}</span>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="workflow[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white"></textarea>
          </div>
        </div>

        ${this.stepsSectionHTML()}

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Workflow")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_workflows_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }
}
