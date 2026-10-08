import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Documents_NewController extends Companies_LayoutController {
  // Depends on BE: Companies::DocumentsController#new (document_groups JSON) + #create (multipart POST)
  // Endpoints: GET <pathname>.json → { document_groups }, POST /companies/:id/documents
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  /** @type {Array<{id: string, name: string}>} */
  documentGroups = []

  connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    fetchJson(`${pathname()}.json`).then((response) => {
      this.documentGroups = response.document_groups || []
      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    }).catch(() => {
      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    })
  }

  documentsCategories() {
    return currentCategories().filter(c => c.resource_name === "documents")
  }

  defaultFilterCategory() {
    return this.documentsCategories()[0]
  }

  documentBusinessTypes() {
    return Enums()?.document?.business_types || [
      { name: "General", value: "general" },
      { name: "Policy", value: "policy" },
      { name: "Guide", value: "guide" },
      { name: "Announcement", value: "announcement" }
    ]
  }

  documentWorkflowStatuses() {
    return Enums()?.document?.workflow_statuses || [
      { name: "Draft", value: "draft" },
      { name: "Pending", value: "pending" },
      { name: "Confirmed", value: "confirmed" },
      { name: "In Progress", value: "in_progress" },
      { name: "Completed", value: "completed" },
      { name: "Paid", value: "paid" },
      { name: "Cancelled", value: "cancelled" },
      { name: "Refunded", value: "refunded" },
      { name: "Failed", value: "failed" },
      { name: "Initiated", value: "initiated" },
      { name: "Received", value: "received" },
      { name: "Shipped", value: "shipped" }
    ]
  }

  renderField({ key, label, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="document[${key}]" value="false">
            <input type="checkbox" name="document[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="number" name="document[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="document[${key}]"
              class="${baseClass}">
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="text" name="document[${key}]" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''

    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>
    `
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  updatePreview(event) {
    const preview = this.element.querySelector('#markdown-preview')
    if (preview) {
      const rendered = renderMarkdown(event.target.value || '')
      preview.innerHTML = rendered || `<p class="text-sm text-slate-400">${translate("Nothing to preview yet.")}</p>`
    }
  }

  contentHTML() {
    const categoryFilter = this.documentsCategories()

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Document")}</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
          <select
            name="document[category_id]"
            data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
          >
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Document Title")}</label>
            <input type="text" name="document[title]" required placeholder="${translate("e.g. Leave Policy")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Document Group")}</label>
            <select name="document[document_group_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(cloneNewKey(this.documentGroups, "id", "value"), null)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Type")}</label>
            <select name="document[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(this.documentBusinessTypes(), 'general')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Status")}</label>
            <select name="document[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(this.documentWorkflowStatuses(), 'draft')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="document[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Body")} (Markdown)</label>
            <textarea name="document[body_markdown]" rows="12"
              data-action="input->${this.identifier}#updatePreview"
              placeholder="# Title&#10;&#10;Write **markdown** here..."
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Preview")}</label>
            <div
              id="markdown-preview"
              data-preview="markdown"
              class="w-full min-h-[300px] px-4 py-3 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-800/50 overflow-y-auto"
            >
              <p class="text-sm text-slate-400">${translate("Nothing to preview yet.")}</p>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Images")} (max 10)</label>
            <input type="file" name="document[image_attachments][]" multiple accept="image/jpeg,image/png,image/gif"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white cursor-pointer">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Files")} (max 5)</label>
            <input type="file" name="document[file_attachments][]" multiple accept=".pdf,.doc,.docx,.xls,.xlsx,.txt,image/jpeg,image/png,image/gif"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white cursor-pointer">
          </div>
        </div>

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Document")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_documents_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" enctype="multipart/form-data"`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
