import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Imports_NewModalController from "controllers/companies/imports/new_modal_controller"

export default class Companies_Imports_IndexController extends Companies_LayoutController {
  // Imports index — list, create modal, guarded draft delete. The full
  // workflow (setup, sample, upload, dry run, approve, rollback) lives on the
  // show page.
  // Depends on BE: Companies::ImportsController (index/create/destroy)
  // Endpoints: GET <pathname>.json, POST /companies/:id/imports.json,
  //            DELETE /companies/:id/imports/:id
  // Docs: docs/IMPORT.md

  /** @type {ImportSummary[]} */ imports = []
  /** @type {string} */ loadError = ""

  async connect() {
    super.connect()

    try {
      /** @type {{ imports: ImportSummary[] }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.imports = response.imports || []
    } catch (error) {
      this.loadError = error.errors?.join(", ") || error.message || ""
      toast({ type: "error", message: `${translate("Failed to load imports")}: ${this.loadError}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.contentTarget.classList.add("flex", "flex-col", "flex-1")
        this.renderContent()
        return true
      }
      return false
    }, { maxAttempts: 500 })
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Imports_NewModalController)}"></div>` })
  }

  async deleteImport(event) {
    const importId = event.currentTarget.dataset.importId
    if (!confirm(translate("Delete this import and its uploaded file?"))) return

    try {
      const response = await fetchJson(Helpers.company_import_path(currentCompany().id, importId), {
        method: "DELETE"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete import") })
    }
  }

  statusBadgeClasses(workflowStatus) {
    switch (workflowStatus) {
      case "completed":
        return "bg-success/10 text-success "
      case "failed":
        return "bg-danger/10 text-danger "
      case "approved":
      case "processing":
      case "rolling_back":
        return "bg-primary/10 text-primary "
      default:
        return "bg-muted text-muted-foreground "
    }
  }

  statusLabel(workflowStatus) {
    const labels = {
      draft: translate("Draft"),
      approved: translate("Approved"),
      processing: translate("Processing"),
      completed: translate("Completed"),
      failed: translate("Failed"),
      rolling_back: translate("Rolling back"),
      rolled_back: translate("Rolled back")
    }
    return labels[workflowStatus] || workflowStatus
  }

  statusBadgeHTML(workflowStatus) {
    return `<span class="px-2.5 py-1 rounded-full text-xs font-medium ${this.statusBadgeClasses(workflowStatus)}">
      ${escapeHtml(this.statusLabel(workflowStatus))}
    </span>`
  }

  rowHTML(importRecord) {
    const target = importRecord.target_model || "—"
    const rows = `${importRecord.created_rows || 0}/${importRecord.total_rows || 0}`
    const deleteButton = importRecord.workflow_status === "draft"
      ? `<button type="button" data-action="click->${this.identifier}#deleteImport" data-import-id="${importRecord.id}"
           class="text-xs text-danger hover:underline cursor-pointer">${translate("Delete")}</button>`
      : ""

    return `
      <tr class="border-b border-line/60">
        <td class="py-2 pr-4">
          <a href="${Helpers.company_import_path(currentCompany().id, importRecord.id)}"
            class="text-sm font-medium text-primary hover:underline">${escapeHtml(importRecord.name)}</a>
          ${importRecord.category_name ? `<p class="text-[11px] text-muted-foreground">${escapeHtml(importRecord.category_name)}</p>` : ""}
        </td>
        <td class="py-2 pr-4 text-sm text-muted-foreground">${escapeHtml(target)}</td>
        <td class="py-2 pr-4">${this.statusBadgeHTML(importRecord.workflow_status)}</td>
        <td class="py-2 pr-4 text-sm text-muted-foreground">${rows}</td>
        <td class="py-2 pr-4 text-sm text-muted-foreground">${Helpers.timeFormat(importRecord.created_at, "YYYY-MM-DD HH:mm")}</td>
        <td class="py-2 text-right">
          <a href="${Helpers.company_import_path(currentCompany().id, importRecord.id)}"
            class="text-xs text-primary hover:underline mr-3">${translate("Open")}</a>
          ${deleteButton}
        </td>
      </tr>
    `
  }

  tableHTML() {
    return `
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
              <th class="py-2 pr-4">${translate("Name")}</th>
              <th class="py-2 pr-4">${translate("Target")}</th>
              <th class="py-2 pr-4">${translate("Status")}</th>
              <th class="py-2 pr-4">${translate("Rows")}</th>
              <th class="py-2 pr-4">${translate("Created")}</th>
              <th class="py-2 text-right">${translate("Actions")}</th>
            </tr>
          </thead>
          <tbody>
            ${this.imports.map((importRecord) => this.rowHTML(importRecord)).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  emptyHTML() {
    return `
      <div class="flex flex-col items-center justify-center py-16 text-center">
        <span class="material-symbols-outlined text-4xl text-muted-foreground">file_upload</span>
        <h3 class="mt-3 text-sm font-bold text-foreground">${translate("No imports yet")}</h3>
        <p class="mt-1 text-xs text-muted-foreground">${translate("Create your first import to get started.")}</p>
      </div>
    `
  }

  contentHTML() {
    if (this.loadError) {
      return `
        <div class="p-4 flex-1 flex flex-col">
          <div class="p-4 bg-card rounded-xl border border-danger/20">
            <h2 class="text-lg font-bold text-danger">${translate("Could not load imports")}</h2>
            <p class="mt-1 text-sm text-muted-foreground">${escapeHtml(this.loadError)}</p>
          </div>
        </div>
      `
    }

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-bold text-foreground">${translate("Imports")}</h2>
            <p class="text-xs text-muted-foreground">
              ${translate("Import CSV data into a table using its exact header contract.")}
            </p>
          </div>
          <button type="button" data-action="click->${this.identifier}#openNewModal"
            class="px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
            ${translate("New Import")}
          </button>
        </div>
        <div class="p-4 bg-card rounded-xl border border-line flex-1">
          ${this.imports.length === 0 ? this.emptyHTML() : this.tableHTML()}
        </div>
      </div>
    `
  }
}
