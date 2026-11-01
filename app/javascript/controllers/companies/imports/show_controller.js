import Companies_LayoutController from "controllers/companies/layout_controller"
import { IMPORTABLE_RESOURCES } from "controllers/helpers/import_tables"
import { parseCsvHeaderLine } from "controllers/helpers/csv_headers"

export default class Companies_Imports_ShowController extends Companies_LayoutController {
  // Import show — the whole user-prepared CSV workflow: pick a table + one
  // category, inspect the resolved header contract and 10 latest records,
  // upload a CSV, run a full-file dry run, approve, then rollback.
  // Depends on BE: Companies::ImportsController
  //   (show/update/source_file/dry_run/approve/rollback)
  // Endpoints: GET <pathname>.json, PATCH <pathname>.json,
  //            POST .../source_file, POST .../dry_run, POST .../approve,
  //            POST .../rollback
  // WS: import_progress / import_finished (company channel)
  // Docs: docs/IMPORT.md

  /** @type {Import|null} */ import = null
  /** @type {Object|null} */ liveProgress = null
  /** @type {string} */ loadError = ""
  /** @type {Object|null} */ headerCheck = null
  uploadState = { active: false, name: "" }

  async connect() {
    super.connect()

    try {
      /** @type {{ import: Import }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.import = response.import
    } catch (error) {
      this.loadError = error.errors?.join(", ") || error.message || ""
      toast({ type: "error", message: `${translate("Failed to load import")}: ${this.loadError}` })
    }

    this.subscribeToProgress()

    poll(() => {
      if (this.hasContentTarget) {
        this.contentTarget.classList.add("flex", "flex-col", "flex-1")
        this.renderContent()
        return true
      }
      return false
    }, { maxAttempts: 500 })
  }

  subscribeToProgress() {
    if (!this.import) return

    const channel = WEBSOCKET.channelName("company", currentCompany()?.id)
    if (!channel) return

    WEBSOCKET.subscribe(channel, "import_progress", (data) => {
      if (!this.import || data.id !== this.import.id) return
      this.liveProgress = data.payload
      this.updateProgress()
    })

    WEBSOCKET.subscribe(channel, "import_finished", (data) => {
      if (!this.import || data.id !== this.import.id) return
      toast({ type: "success", message: translate("Import updated") })
      window.location.reload()
    })
  }

  // --- Setup (table + category + basic data) ---

  targetChanged(event) {
    const select = this.contentTarget?.querySelector("[data-import-category]")
    if (!select) return

    select.innerHTML = this.categoryOptionsHTML(event.target.value, "")
  }

  async saveSetup() {
    const root = this.contentTarget
    if (!root) return

    const name = root.querySelector("[data-import-name]")?.value
    const description = root.querySelector("[data-import-description]")?.value
    const targetTable = root.querySelector("[data-import-target]")?.value
    const categoryId = root.querySelector("[data-import-category]")?.value

    try {
      const response = await fetchJson(Helpers.company_import_path(currentCompany().id, this.import.id), {
        method: "PATCH",
        body: {
          import: {
            name,
            description,
            target_table: targetTable,
            category_id: categoryId
          }
        }
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save setup") })
    }
  }

  // --- Upload + browser-side header pre-check ---

  async handleFileSelect(event) {
    const file = event.target.files?.[0]
    if (!file || !this.import || this.uploadState.active) return

    if (!this.import.schema) {
      event.target.value = ""
      toast({ type: "error", message: translate("Save the setup before uploading a CSV") })
      return
    }

    this.headerCheck = await this.checkHeaders(file)
    this.renderHeaderCheck()

    if (this.headerCheck.blocking) {
      event.target.value = ""
      toast({ type: "error", message: translate("Fix the CSV headers before uploading") })
      return
    }

    await this.uploadFile(file)
  }

  async checkHeaders(file) {
    let text = ""
    try {
      text = await file.text()
    } catch (error) {
      return { blocking: true, parseError: true, unknown: [], missing: [], duplicates: [], total: 0 }
    }

    const headers = this.import.schema?.headers || []
    const actual = parseCsvHeaderLine(text)
    const expected = headers.map((entry) => entry.header)
    const required = headers.filter((entry) => entry.required).map((entry) => entry.header)

    const unknown = actual.filter((header) => !expected.includes(header))
    const missing = required.filter((header) => !actual.includes(header))
    const duplicates = actual.filter((header, index) => actual.indexOf(header) !== index)
    const blocking = actual.length === 0 || unknown.length > 0 || missing.length > 0 || duplicates.length > 0

    return { blocking, parseError: false, unknown, missing, duplicates, total: actual.length }
  }

  async uploadFile(file) {
    this.uploadState = { active: true, name: file.name }
    this.renderUploadStatus()

    const formData = new FormData()
    formData.append("file", file)

    try {
      const response = await fetchJson(Helpers.source_file_company_import_path(currentCompany().id, this.import.id), {
        method: "POST",
        body: formData
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      this.uploadState = { active: false, name: "" }
      this.renderUploadStatus()
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to upload CSV") })
    }
  }

  renderHeaderCheck() {
    const el = this.contentTarget?.querySelector("[data-header-check]")
    if (!el || !this.headerCheck) return

    const check = this.headerCheck
    const parts = []

    if (check.parseError) {
      parts.push(`<p class="text-danger">${translate("Could not read this file")}</p>`)
    }
    if ((check.unknown || []).length > 0) {
      parts.push(`<p class="text-danger">${translate("Unknown headers")}: ${escapeHtml(check.unknown.join(", "))}</p>`)
    }
    if ((check.missing || []).length > 0) {
      parts.push(`<p class="text-danger">${translate("Missing required headers")}: ${escapeHtml(check.missing.join(", "))}</p>`)
    }
    if ((check.duplicates || []).length > 0) {
      parts.push(`<p class="text-danger">${translate("Duplicate headers")}: ${escapeHtml(check.duplicates.join(", "))}</p>`)
    }
    if (!check.blocking) {
      parts.push(`<p class="text-success">${translate("All required headers match")}</p>`)
    }

    el.innerHTML = parts.join("")
  }

  renderUploadStatus() {
    const el = this.contentTarget?.querySelector("[data-upload-status]")
    if (!el) return

    el.textContent = this.uploadState.active
      ? `${translate("Uploading")} ${this.uploadState.name}…`
      : ""
  }

  // --- Dry run / approve / rollback ---

  async runDryRun() {
    try {
      const response = await fetchJson(Helpers.dry_run_company_import_path(currentCompany().id, this.import.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Dry run passed") })
    } catch (error) {
      reloadThenToast({ type: "error", message: error.errors?.join(", ") || translate("Dry run failed") })
    }
  }

  async approve() {
    try {
      const response = await fetchJson(Helpers.approve_company_import_path(currentCompany().id, this.import.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to approve import") })
    }
  }

  async rollback() {
    try {
      const response = await fetchJson(Helpers.rollback_company_import_path(currentCompany().id, this.import.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to queue rollback") })
    }
  }

  async copyHeaders() {
    const headers = (this.import?.schema?.headers || []).map((entry) => entry.header)

    try {
      await navigator.clipboard.writeText(headers.join(","))
      toast({ type: "success", message: translate("Copied to clipboard") })
    } catch (error) {
      toast({ type: "error", message: translate("Could not copy headers") })
    }
  }

  // --- Live progress ---

  progressSource() {
    return this.liveProgress || this.import
  }

  updateProgress() {
    const bar = this.contentTarget?.querySelector("[data-import-progress]")
    if (bar) bar.innerHTML = this.progressInnerHTML()

    if (this.liveProgress) {
      const badge = this.contentTarget?.querySelector("[data-status-badge]")
      if (badge) badge.outerHTML = this.statusBadgeHTML(this.liveProgress.status)
    }
  }

  progressInnerHTML() {
    const source = this.progressSource()
    const rollingBack = source.phase === "rollback"
    const total = source.total_rows || 0
    const processed = source.processed_rows || 0
    const percent = total > 0 ? Math.min(100, Math.round((processed / total) * 100)) : 0

    const counts = rollingBack
      ? `${processed}/${total} ${translate("Records")}`
      : `${processed}/${total} ${translate("Rows")}`

    return `
      <div class="flex items-center justify-between text-xs text-muted-foreground mb-1">
        <span>${counts}</span>
        <span>
          ${translate("Created")}: ${source.created_rows || 0} ·
          ${translate("Failed")}: ${source.failed_rows || 0}
        </span>
      </div>
      <div class="h-2 rounded-full bg-muted overflow-hidden">
        <div class="h-full bg-primary transition-all" style="width: ${percent}%"></div>
      </div>
    `
  }

  // --- Rendering ---

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
    return `<span data-status-badge class="px-2.5 py-1 rounded-full text-xs font-medium ${this.statusBadgeClasses(workflowStatus)}">
      ${escapeHtml(this.statusLabel(workflowStatus))}
    </span>`
  }

  headerHTML() {
    return `
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-lg font-bold text-foreground">${escapeHtml(this.import.name)}</h2>
          <p class="text-xs text-muted-foreground mt-0.5">
            ${escapeHtml(this.import.target_model || translate("No target table yet"))}
            ${this.import.category_name ? ` · ${escapeHtml(this.import.category_name)}` : ""}
          </p>
          ${this.import.description ? `<p class="text-xs text-muted-foreground mt-1">${escapeHtml(this.import.description)}</p>` : ""}
        </div>
        ${this.statusBadgeHTML(this.import.workflow_status)}
      </div>
    `
  }

  instructionsHTML() {
    return `
      <section class="p-4 rounded-xl border border-line bg-muted/40 space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("How it works")}</h3>
        <ol class="list-decimal list-inside space-y-1 text-xs text-muted-foreground">
          <li>${translate("Choose the target table.")}</li>
          <li>${translate("Choose the category — its dynamic property names become CSV headers.")}</li>
          <li>${translate("Copy the exact header names below. Spelling and case matter.")}</li>
          <li>${translate("Fill one row per record in your CSV.")}</li>
          <li>${translate("Upload the CSV and run a dry run.")}</li>
          <li>${translate("Fix any reported errors, re-upload, and run the dry run again.")}</li>
          <li>${translate("Approve to create the records in the background.")}</li>
          <li>${translate("Rollback removes only the records this import created.")}</li>
        </ol>
      </section>
    `
  }

  setupHTML() {
    if (this.import.setup_locked) {
      return `
        <section class="p-4 rounded-xl border border-line bg-card">
          <h3 class="text-sm font-bold text-foreground">${translate("Setup")}</h3>
          <p class="mt-1 text-xs text-muted-foreground">
            ${translate("This import is locked. Rollback to undo it or create a new import.")}
          </p>
        </section>
      `
    }

    const targetOptions = Object.entries(IMPORTABLE_RESOURCES).map(([table, model]) => {
      const label = model.replace(/([a-z])([A-Z])/g, "$1 $2")
      return `<option value="${table}" ${table === this.import.target_table ? "selected" : ""}>${escapeHtml(label)} (${table})</option>`
    }).join("")

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground">${translate("Setup")}</h3>
          <a href="${Helpers.company_categories_path(currentCompany().id)}"
            class="text-xs text-primary hover:underline">${translate("Manage categories")}</a>
        </div>

        <div class="grid gap-3 md:grid-cols-2">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Import Name")}</label>
            <input type="text" data-import-name value="${escapeHtml(this.import.name)}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Description")}</label>
            <input type="text" data-import-description value="${escapeHtml(this.import.description || "")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Target table")}</label>
            <select data-import-target data-action="change->${this.identifier}#targetChanged"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              <option value="">${translate("Select a table")}</option>
              ${targetOptions}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Category")}</label>
            <select data-import-category
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${this.categoryOptionsHTML(this.import.target_table, this.import.category_id)}
            </select>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <button type="button" data-action="click->${this.identifier}#saveSetup"
            class="px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
            ${translate("Save setup & load sample")}
          </button>
          <p class="text-xs text-muted-foreground">
            ${translate("The sample uses the latest records from the chosen table and category.")}
          </p>
        </div>
      </section>
    `
  }

  categoryOptionsHTML(table, selectedId) {
    const categories = (this.import.categories || []).filter((category) => category.resource_name === table)
    const options = categories.map((category) => `
      <option value="${category.id}" ${category.id === selectedId ? "selected" : ""}>${escapeHtml(category.name)}</option>
    `).join("")

    const placeholder = categories.length === 0
      ? translate("No categories for this table yet")
      : translate("Select a category")

    return `<option value="">${escapeHtml(placeholder)}</option>${options}`
  }

  expectedHeadersHTML() {
    const schema = this.import.schema
    if (!schema) return ""

    const rows = schema.headers.map((entry) => {
      const notes = []
      if (entry.kind === "property") notes.push(`property slot: ${entry.attribute}`)
      if ((entry.enum || []).length > 0) notes.push(entry.enum.join(", "))
      if (entry.association) notes.push(`FK → ${entry.association.model}`)

      return `
        <tr class="border-b border-line/60">
          <td class="py-1.5 pr-4 font-mono text-xs text-foreground">${escapeHtml(entry.header)}</td>
          <td class="py-1.5 pr-4 text-xs text-muted-foreground">${entry.kind === "property" ? escapeHtml(entry.attribute) : "—"}</td>
          <td class="py-1.5 pr-4 text-xs text-muted-foreground">${escapeHtml(entry.type)}</td>
          <td class="py-1.5 pr-4 text-xs ${entry.required ? "text-danger" : "text-muted-foreground"}">
            ${entry.required ? translate("Required") : translate("Optional")}
          </td>
          <td class="py-1.5 text-xs text-muted-foreground">${escapeHtml(notes.join(" · "))}</td>
        </tr>
      `
    }).join("")

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-2">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-bold text-foreground">${translate("Expected CSV headers")}</h3>
            <p class="text-xs text-muted-foreground">
              ${translate("The CSV must use these exact names. Property columns use the category's display names.")}
            </p>
          </div>
          <button type="button" data-action="click->${this.identifier}#copyHeaders"
            class="px-3 py-1.5 bg-muted hover:bg-card text-foreground rounded-lg text-xs font-medium cursor-pointer">
            ${translate("Copy headers")}
          </button>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
                <th class="py-2 pr-4">${translate("Header")}</th>
                <th class="py-2 pr-4">${translate("Maps to")}</th>
                <th class="py-2 pr-4">${translate("Type")}</th>
                <th class="py-2 pr-4">${translate("Required")}</th>
                <th class="py-2">${translate("Notes")}</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </section>
    `
  }

  sampleHTML() {
    const sample = this.import.sample || { headers: [], rows: [], total_records: 0 }
    if ((sample.headers || []).length === 0) return ""

    const head = sample.headers.map((entry) => `<th class="py-1.5 pr-4 whitespace-nowrap">${escapeHtml(entry.header)}</th>`).join("")
    const body = sample.rows.map((row) => `
      <tr class="border-b border-line/60">
        ${sample.headers.map((entry) => `<td class="py-1 pr-4 whitespace-nowrap text-muted-foreground">${escapeHtml(row[entry.header])}</td>`).join("")}
      </tr>
    `).join("")

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground">${translate("Sample data")}</h3>
          <p class="text-xs text-muted-foreground">
            ${translate("Showing")} ${sample.rows.length} ${translate("of")} ${sample.total_records} ${translate("records")}
          </p>
        </div>
        ${sample.rows.length === 0 ? `
          <p class="text-xs text-muted-foreground">${translate("No records in this category yet.")}</p>
        ` : `
          <div class="overflow-x-auto">
            <table class="w-full text-xs">
              <thead>
                <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">${head}</tr>
              </thead>
              <tbody>${body}</tbody>
            </table>
          </div>
        `}
      </section>
    `
  }

  uploadHTML() {
    if (this.import.setup_locked) return ""

    const maxMb = Math.round((this.import.max_file_bytes || 0) / 1024 / 1024)
    const currentFile = this.import.source_filename
      ? `<p class="text-xs text-muted-foreground">
           ${translate("Current file")}: ${escapeHtml(this.import.source_filename)}
           (${this.import.total_rows} ${translate("rows")})
         </p>`
      : ""

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Upload CSV")}</h3>
        <p class="text-xs text-muted-foreground">
          ${translate("Single file, max")} ${maxMb}MB · ${this.import.max_rows} ${translate("rows")}.
          ${translate("Re-uploading replaces the current file and clears the dry run.")}
        </p>
        ${currentFile}
        <div class="flex items-center gap-3">
          <input id="import-file-input" type="file" accept=".csv,text/csv"
            data-action="change->${this.identifier}#handleFileSelect"
            class="block text-sm text-muted-foreground file:mr-3 file:px-4 file:py-2 file:rounded-lg file:border-0 file:bg-primary file:text-primary-foreground file:cursor-pointer" />
          <span class="text-xs text-muted-foreground" data-upload-status></span>
        </div>
        <div class="text-xs space-y-1" data-header-check></div>
      </section>
    `
  }

  dryRunHTML() {
    const result = this.import.dry_run_result
    if (!result) return ""

    const headerErrors = result.header_errors || []
    const rowErrors = result.row_errors || []

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground">${translate("Dry run result")}</h3>
          <span class="text-sm font-medium ${result.passed ? "text-success" : "text-danger"}">
            ${result.passed ? translate("Passed") : translate("Failed")}
          </span>
        </div>
        <p class="text-xs text-muted-foreground">
          ${translate("Checked at")}: ${Helpers.timeFormat(result.checked_at, "YYYY-MM-DD HH:mm")} ·
          ${translate("Total")}: ${result.total_rows} ·
          ${translate("Valid")}: ${result.valid_rows} ·
          ${translate("Invalid")}: ${result.invalid_rows}
        </p>
        ${headerErrors.length > 0 ? `
          <div class="text-xs text-danger space-y-1">
            ${headerErrors.map((error) => `<p>${escapeHtml(error)}</p>`).join("")}
          </div>
        ` : ""}
        ${rowErrors.length > 0 ? `
          <div class="overflow-x-auto">
            <table class="w-full text-xs">
              <thead>
                <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase">
                  <th class="py-1 pr-4">${translate("Row")}</th>
                  <th class="py-1">${translate("Errors")}</th>
                </tr>
              </thead>
              <tbody>
                ${rowErrors.map((row) => `
                  <tr class="border-t border-line">
                    <td class="py-1 pr-4">${row.row}</td>
                    <td class="py-1 text-danger">${escapeHtml((row.errors || []).join(", "))}</td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
        ` : ""}
      </section>
    `
  }

  actionsHTML() {
    const locked = this.import.setup_locked
    const canApprove = this.import.can_approve
    const canRollback = this.import.can_rollback
    const canDryRun = !locked && this.import.schema && this.import.source_filename

    return `
      <section class="flex flex-wrap items-center gap-3">
        ${!locked ? `
          <button type="button" data-action="click->${this.identifier}#runDryRun" ${canDryRun ? "" : "disabled"}
            class="px-4 py-2 bg-warning/100 hover:bg-warning/90 text-warning-foreground rounded-lg text-sm font-medium cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
            ${translate("Run dry run")}
          </button>
          <button type="button" data-action="click->${this.identifier}#approve" ${canApprove ? "" : "disabled"}
            class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg text-sm font-medium cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
            ${translate("Approve")}
          </button>
        ` : ""}
        ${canRollback ? `
          <button type="button" data-action="click->${this.identifier}#rollback"
            class="px-4 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg text-sm font-medium cursor-pointer">
            ${translate("Rollback")}
          </button>
        ` : ""}
      </section>
    `
  }

  contentHTML() {
    if (!this.import) {
      return `
        <div class="p-4 flex-1 flex flex-col">
          <div class="p-4 bg-card rounded-xl border border-danger/20">
            <h2 class="text-lg font-bold text-danger">${translate("Could not load this import")}</h2>
            <p class="mt-1 text-sm text-muted-foreground">${escapeHtml(this.loadError)}</p>
            <a href="${Helpers.company_imports_path(currentCompany()?.id)}"
              class="mt-3 inline-block text-sm text-primary hover:underline">
              ${translate("Back to Imports")}
            </a>
          </div>
        </div>
      `
    }

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-4 bg-card rounded-xl border border-line flex-1 space-y-5">
          ${this.headerHTML()}
          <div data-import-progress>${this.progressInnerHTML()}</div>
          ${this.instructionsHTML()}
          ${this.setupHTML()}
          ${this.expectedHeadersHTML()}
          ${this.sampleHTML()}
          ${this.uploadHTML()}
          ${this.dryRunHTML()}
          ${this.actionsHTML()}
        </div>
      </div>
    `
  }
}
