import Companies_LayoutController from "controllers/companies/layout_controller"
import { marked } from "marked"
import DOMPurify from "dompurify"

const renderBody = (source = "") => DOMPurify.sanitize(marked.parse(String(source ?? "")))

export default class Companies_Documents_EditController extends Companies_LayoutController {
  // Depends on BE: Companies::DocumentsController#edit (document + groups JSON) + #update (multipart PATCH)
  // Endpoints: GET <pathname>.json → { document, document_groups }, PATCH /companies/:id/documents/:id
  /** @type {Document | null} */
  document = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  /** @type {Array<{id: string, name: string}>} */
  documentGroups = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_document_path(companyId, recordId)}.json`)
      this.document = response.document
      this.documentGroups = response.document_groups || []

      if (this.document?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.document.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load document.")}</div>`
          return true
        }
        return false
      })
    }
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

  updatePreview(event) {
    const preview = this.element.querySelector('#markdown-preview')
    if (preview) {
      const rendered = renderBody(event.target.value || '')
      preview.innerHTML = rendered || `<p class="text-sm text-slate-400">${translate("Nothing to preview yet.")}</p>`
    }
  }

  contentHTML() {
    const d = this.document
    if (!d) return `<div class="p-8 text-center">${translate('Document not found.')}</div>`

    const companyId = window.location.pathname.split("/")[2]

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = d[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="document[${field.key}]" value="false">
                  <input type="checkbox" name="document[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 dark:border-slate-600 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="document[${field.key}]" value="${escapeHtml(value) ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="document[${field.key}]" value="${escapeHtml(value) ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="document[${field.key}]" value="${escapeHtml(value) ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              default:
                inputHTML = `<input type="text" name="document[${field.key}]" value="${escapeHtml(value) ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${escapeHtml(field.name)}</label>
                ${inputHTML}
              </div>`
          }).join('')}
        </div>
      </div>
    ` : ''

    const existingImages = (d.image_urls || []).map(a => `
      <span class="inline-flex items-center gap-1 px-2 py-0.5 text-xs bg-slate-100 dark:bg-slate-800 rounded">${escapeHtml(a.filename)}</span>
    `).join('')
    const existingFiles = (d.file_urls || []).map(a => `
      <span class="inline-flex items-center gap-1 px-2 py-0.5 text-xs bg-slate-100 dark:bg-slate-800 rounded">${escapeHtml(a.filename)}</span>
    `).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Document")}</h2>
        <p class="text-sm text-slate-500">${escapeHtml(d.title)}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Document Title")}</label>
            <input type="text" name="document[title]" value="${escapeHtml(d.title) || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Document Group")}</label>
            <select name="document[document_group_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(cloneNewKey(this.documentGroups, "id", "value"), d.document_group_id)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Type")}</label>
            <select name="document[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(this.documentBusinessTypes(), d.business_type || 'general')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Status")}</label>
            <select name="document[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(this.documentWorkflowStatuses(), d.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</label>
            <input type="text" value="${escapeHtml(currentCategories().find(c => c.id === d.category_id)?.name) || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="document[category_id]" value="${d.category_id}">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="document[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${escapeHtml(d.description) || ''}</textarea>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Body")} (Markdown)</label>
            <textarea name="document[body_markdown]" rows="12"
              data-action="input->${this.identifier}#updatePreview"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono">${escapeHtml(d.body_markdown) || ''}</textarea>
          </div>
          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Preview")}</label>
            <div
              id="markdown-preview"
              data-preview="markdown"
              class="w-full min-h-[300px] px-4 py-3 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-800/50 overflow-y-auto"
            >
              ${renderBody(d.body_markdown || '')}
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Images")} (max 10)</label>
            ${existingImages ? `<div class="flex flex-wrap gap-1 mb-1">${existingImages}</div>` : ''}
            <input type="file" name="document[image_attachments][]" multiple accept="image/jpeg,image/png,image/gif"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm cursor-pointer">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Files")} (max 5)</label>
            ${existingFiles ? `<div class="flex flex-wrap gap-1 mb-1">${existingFiles}</div>` : ''}
            <input type="file" name="document[file_attachments][]" multiple accept=".pdf,.doc,.docx,.xls,.xlsx,.txt,image/jpeg,image/png,image/gif"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm cursor-pointer">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_document_path(companyId, d.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Document")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_document_path(companyId, d.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate enctype="multipart/form-data"`,
          html: fields
        })}
      </div>
    `
  }
}
