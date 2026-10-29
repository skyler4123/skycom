import Companies_LayoutController from "controllers/companies/layout_controller"
import { marked } from "marked"
import DOMPurify from "dompurify"

const renderBody = (source = "") => DOMPurify.sanitize(marked.parse(String(source ?? "")))

export default class Companies_Documents_ShowController extends Companies_LayoutController {
  // Depends on BE: Companies::DocumentsController#show (document JSON with body_markdown + urls)
  // Endpoints: GET <pathname>.json → { document }
  /** @type {Document | null} */
  document = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_document_path(companyId, recordId)}.json`)
      this.document = response.document

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load document.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-muted-foreground/60">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-success/10 text-success ' : 'bg-background text-foreground '}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-foreground">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-foreground">${escapeHtml(value)}</span>`
    }
  }

  showHTML() {
    const d = this.document
    if (!d) return `<div class="p-8 text-center">${translate("Document not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === d.category_id)
    const isDraft = d.workflow_status === 'draft'

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-info ">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${escapeHtml(field.name)}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(d[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    const images = (d.image_urls || []).map(a => `
      <a href="${a.url}" target="_blank" rel="noopener noreferrer" class="block overflow-hidden rounded-lg border border-line cursor-pointer">
        <img src="${a.thumb_url || a.url}" alt="${escapeHtml(a.filename)}" class="w-full h-32 object-cover">
        <p class="px-2 py-1 text-xs text-muted-foreground truncate">${escapeHtml(a.filename)}</p>
      </a>
    `).join('')

    const files = (d.file_urls || []).map(a => `
      <a href="${a.url}" target="_blank" rel="noopener noreferrer" class="flex items-center gap-3 px-3 py-2 rounded-lg border border-line hover:bg-muted cursor-pointer">
        <span class="material-symbols-outlined text-muted-foreground">description</span>
        <span class="min-w-0 flex-1">
          <span class="block text-sm font-medium text-foreground truncate">${escapeHtml(a.filename)}</span>
          <span class="block text-xs text-muted-foreground">${escapeHtml(a.content_type) || ''}</span>
        </span>
      </a>
    `).join('')

    const attachmentsHTML = (images || files) ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Attachments")}</h3>
        ${images ? `<div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">${images}</div>` : ''}
        ${files ? `<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">${files}</div>` : ''}
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_documents_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Documents")}
          </a>

          ${isDraft ? `
            <div class="mb-6 flex items-center gap-2 rounded-lg bg-warning/10 border border-warning/20 px-4 py-2.5 text-sm font-medium text-warning ">
              <span class="material-symbols-outlined text-[20px]">draft</span>
              ${translate("Draft — not visible to readers")}
            </div>
          ` : ''}

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-info/30 /30 bg-info/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-info ">article</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${escapeHtml(d.name)}</h2>
              <p class="font-semibold text-info ">${escapeHtml(d.description) || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-info/10 px-3 py-1 text-xs font-bold text-info uppercase">${escapeHtml(d.code) || translate("N/A")}</span>
                ${Helpers.statusBadge(d.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-info ">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${escapeHtml(category?.name || d.category?.name) || translate("N/A")}</p>
              </div>
            </div>
          </div>

          <article class="mt-6 border-t border-line pt-6 max-w-none">
            ${d.body_markdown ? renderBody(d.body_markdown) : `<p class="text-sm text-muted-foreground">${translate("No content yet.")}</p>`}
          </article>

          ${attachmentsHTML}

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_document_path(companyId, d.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Document")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
