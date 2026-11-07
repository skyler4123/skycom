import Companies_LayoutController from "controllers/companies/layout_controller"
import { IMPORTABLE_RESOURCES } from "controllers/helpers/import_tables"
import { parseCsvHeaderLine } from "controllers/helpers/csv_headers"
import {
  activeStep,
  columnDisplayName,
  columnExample,
  columnMeaning,
  columnTypeIcon,
  columnTypeLabel,
  columnTypeTooltip,
  downloadCsv,
  generateProblemRowsCsv,
  generateStarterCsv,
  requiredLabel,
  statusBadgeClasses,
  statusLabel,
  stepLockedReason,
  stepState,
  stepStateLabel,
  targetTableLabel
} from "controllers/helpers/import_helpers"

export default class Companies_Imports_ShowController extends Companies_LayoutController {
  // Import show — a guided four-step flow for non-technical managers:
  // 1) what you're importing, 2) prepare your file, 3) upload & check,
  // 4) review & import (with rollback). Raw storage keys never render.
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
  /** @type {string} */ pendingTargetTable = ""
  /** @type {string} */ pendingCategoryId = ""
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

    // Index-page Import button passes the page's table + category so step 1
    // opens with both already selected. Nothing is saved until the user clicks
    // "Save setup & load sample".
    const params = new URLSearchParams(window.location.search)
    this.pendingTargetTable = params.get("target_table") || ""
    this.pendingCategoryId = params.get("category_id") || ""

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

  // --- Setup (what you're importing) ---

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

    if (!targetTable || !categoryId) {
      toast({ type: "error", message: translate("Choose what you are importing and a category first.") })
      this.focusFirstSetupField(targetTable, categoryId)
      return
    }

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

  focusFirstSetupField(targetTable, categoryId) {
    const selector = !targetTable ? "[data-import-target]" : "[data-import-category]"
    this.contentTarget?.querySelector(selector)?.focus()
  }

  // --- Upload + browser-side header pre-check ---

  async handleFileSelect(event) {
    const input = event.target
    const file = input.files?.[0]
    if (!file) return

    await this.processFile(file, input)
  }

  async processFile(file, input) {
    if (!this.import || this.uploadState.active) return

    if (!this.import.schema) {
      input.value = ""
      toast({ type: "error", message: translate("Save the setup before uploading a CSV") })
      return
    }

    this.headerCheck = await this.checkHeaders(file)
    this.renderHeaderCheck()

    if (this.headerCheck.blocking) {
      input.value = ""
      toast({ type: "error", message: translate("Fix the CSV headers before uploading") })
      return
    }

    await this.uploadFile(file)
  }

  handleDragOver(event) {
    event.preventDefault()
    event.currentTarget.classList.add("border-primary", "bg-primary/5")
  }

  handleDragLeave(event) {
    event.currentTarget.classList.remove("border-primary", "bg-primary/5")
  }

  async handleDrop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("border-primary", "bg-primary/5")

    const input = this.contentTarget?.querySelector("#import-file-input")
    const file = event.dataTransfer?.files?.[0]
    if (!input || !file) return

    const transfer = new DataTransfer()
    transfer.items.add(file)
    input.files = transfer.files

    await this.processFile(file, input)
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
    const rows = this.import.total_rows || 0
    const target = targetTableLabel(this.import.target_table)
    const message = `${translate("Import")} ${rows} ${translate(rows === 1 ? "row" : "rows")} ${translate("into")} ${target}?\n\n${translate("This creates new records. You can undo it afterwards.")}`
    if (!confirm(message)) return

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
    const count = this.import.created_rows || 0
    const message = `${translate("Undo this import?")}\n\n${translate("This deletes the")} ${count} ${translate(count === 1 ? "record" : "records")} ${translate("it created. Records you added by hand are not affected. Import history is kept.")}`
    if (!confirm(message)) return

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

  downloadStarterCsv() {
    const content = generateStarterCsv(this.import?.schema, this.import?.sample?.rows || [])
    downloadCsv(`${this.fileNameBase()}-template.csv`, content)
    toast({ type: "success", message: translate("Starter CSV downloaded") })
  }

  downloadProblemRows() {
    const content = generateProblemRowsCsv(this.import?.dry_run_result)
    downloadCsv(`${this.fileNameBase()}-problems.csv`, content)
    toast({ type: "success", message: translate("Problem rows downloaded") })
  }

  fileNameBase() {
    const name = (this.import?.name || "import").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
    return name || "import"
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

  statusBadgeHTML(workflowStatus) {
    return `<span data-status-badge class="px-2.5 py-1 rounded-full text-xs font-medium ${statusBadgeClasses(workflowStatus)}">
      ${escapeHtml(statusLabel(workflowStatus))}
    </span>`
  }

  headerHTML() {
    return `
      <div>
        <a href="${Helpers.company_imports_path(currentCompany()?.id)}"
          class="mb-3 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
          <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
          ${translate("Back to Imports")}
        </a>
        <div class="flex items-start justify-between gap-4">
          <div>
            <h2 class="text-lg font-bold text-foreground">${escapeHtml(this.import.name)}</h2>
            <p class="text-xs text-muted-foreground mt-0.5">
              ${this.import.target_table ? escapeHtml(targetTableLabel(this.import.target_table)) : translate("No target table yet")}
              ${this.import.category_name ? ` · ${escapeHtml(this.import.category_name)}` : ""}
            </p>
            ${this.import.description ? `<p class="text-xs text-muted-foreground mt-1">${escapeHtml(this.import.description)}</p>` : ""}
          </div>
          ${this.statusBadgeHTML(this.import.workflow_status)}
        </div>
      </div>
    `
  }

  stepperHTML() {
    const steps = [
      { number: 1, title: translate("What you're importing") },
      { number: 2, title: translate("Prepare your file") },
      { number: 3, title: translate("Upload & check") },
      { number: 4, title: translate("Review & import") }
    ]

    const items = steps.map((step) => {
      const state = stepState(this.import, step.number)
      const classes = state === "current"
        ? "border-primary/40 bg-primary/10 text-primary"
        : state === "done"
          ? "border-success/30 bg-success/10 text-success"
          : "border-line bg-card text-muted-foreground"

      // Current step: ping ring around the number + gentle pulse on the card
      // so the manager immediately sees where to work next.
      const cardAnimation = state === "current" ? " animate-pulse" : ""
      const pingHTML = state === "current"
        ? `<span class="absolute inset-0 rounded-full bg-primary/40 animate-ping"></span>`
        : ""

      return `
        <a href="#import-step-${step.number}"
          class="flex items-center gap-2 rounded-lg border px-3 py-2 text-left transition-colors hover:bg-muted ${classes}${cardAnimation}">
          <span class="relative flex size-6 shrink-0 items-center justify-center rounded-full bg-card text-[11px] font-black">
            ${pingHTML}
            <span class="relative z-10">${step.number}</span>
          </span>
          <span class="text-xs font-bold">${escapeHtml(step.title)}</span>
          <span class="material-symbols-outlined ml-auto text-[16px]!">${this.stepIcon(state)}</span>
        </a>
      `
    }).join("")

    return `<nav data-import-stepper data-active-step="${activeStep(this.import)}" class="grid gap-2 sm:grid-cols-4">${items}</nav>`
  }

  stepIcon(state) {
    switch (state) {
      case "done":
        return "check_circle"
      case "current":
        return "arrow_forward"
      case "next":
        return "radio_button_unchecked"
      default:
        return "lock"
    }
  }

  stepCardHTML(number, title, subtitle, body) {
    const state = stepState(this.import, number)
    const border = state === "current" ? "border-primary/40" : "border-line"
    const badgeClasses = state === "current"
      ? "bg-primary/10 text-primary"
      : state === "done"
        ? "bg-success/10 text-success"
        : "bg-muted text-muted-foreground"
    const numberClasses = state === "current"
      ? "bg-primary/10 text-primary"
      : "bg-muted text-foreground"
    const pingHTML = state === "current"
      ? `<span class="absolute inset-0 rounded-full bg-primary/40 animate-ping"></span>`
      : ""

    return `
      <section id="import-step-${number}" data-import-step="${number}"
        class="rounded-xl border ${border} bg-card">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line px-4 py-3">
          <div class="flex items-start gap-3">
            <span class="relative flex size-7 shrink-0 items-center justify-center rounded-full ${numberClasses} text-xs font-black">
              ${pingHTML}
              <span class="relative z-10">${number}</span>
            </span>
            <div>
              <h3 class="text-sm font-bold text-foreground">${escapeHtml(title)}</h3>
              <p class="text-xs text-muted-foreground">${escapeHtml(subtitle)}</p>
            </div>
          </div>
          <span class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-bold ${badgeClasses}">
            <span class="material-symbols-outlined text-[14px]!">${this.stepIcon(state)}</span>
            ${escapeHtml(stepStateLabel(state))}
          </span>
        </div>
        <div class="space-y-4 p-4">
          ${body}
        </div>
      </section>
    `
  }

  lockedStepHTML(step) {
    return `
      <p class="text-xs text-muted-foreground">${escapeHtml(stepLockedReason(step))}</p>
    `
  }

  instructionsHTML() {
    return `
      <section class="p-4 rounded-xl border border-line bg-muted/40 space-y-3">
        <div class="flex items-start gap-3">
          <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
            <span class="material-symbols-outlined text-[20px]!">help</span>
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="text-sm font-bold text-foreground">${translate("How it works")}</h3>
            <ol class="mt-2 list-decimal list-inside space-y-1 text-xs text-muted-foreground">
              <li>${translate("Choose what you are importing and the category it belongs to.")}</li>
              <li>${translate("Download the starter file and fill one row per record.")}</li>
              <li>${translate("Upload the file and check it.")}</li>
              <li>${translate("Import when the check passes. Undo is available afterwards.")}</li>
            </ol>
            <p class="mt-3 text-xs text-muted-foreground">
              <span class="font-bold text-foreground">${translate("Example")}:</span>
              ${translate("Importing 2 products with a name, a business type, and the category's property columns.")}
            </p>
          </div>
        </div>
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

    const effectiveTable = this.import.target_table || this.pendingTargetTable
    const effectiveCategory = this.import.category_id || this.pendingCategoryId

    const targetOptions = Object.keys(IMPORTABLE_RESOURCES).map((table) => {
      return `<option value="${table}" ${table === effectiveTable ? "selected" : ""}>${escapeHtml(targetTableLabel(table))}</option>`
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
            <label class="text-[10px] font-bold text-muted-foreground uppercase"
              ${tooltip(translate("A short name so you can find this import later. Example: Q4 product catalog."))}
            >${translate("Import Name")}</label>
            <input type="text" data-import-name value="${escapeHtml(this.import.name)}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase"
              ${tooltip(translate("Optional note about where this file came from."))}
            >${translate("Description")}</label>
            <input type="text" data-import-description value="${escapeHtml(this.import.description || "")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase"
              ${tooltip(translate("The kind of record you are importing. The list of columns changes with this choice."))}
            >${translate("What are you importing?")}</label>
            <select data-import-target data-action="change->${this.identifier}#targetChanged"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              <option value="">${translate("Select a table")}</option>
              ${targetOptions}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase"
              ${tooltip(translate("The category gives the dynamic property columns their display names."))}
            >${translate("Category")}</label>
            <select data-import-category
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${this.categoryOptionsHTML(effectiveTable, effectiveCategory)}
            </select>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-3">
          <button type="button" data-action="click->${this.identifier}#saveSetup"
            class="px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer"
            ${tooltip(translate("Saves the target and category, then loads the column list and sample records."))}>
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

  columnGuideHTML() {
    const schema = this.import.schema
    if (!schema) {
      return this.lockedStepHTML(2)
    }

    const sampleRows = this.import.sample?.rows || []
    const rows = schema.headers.map((entry) => {
      const displayName = columnDisplayName(entry.header, entry)
      const headerTooltip = displayName && displayName !== entry.header ? tooltip(displayName) : ""

      return `
        <tr class="border-b border-line/60 last:border-0">
          <td class="py-2 pr-4 font-mono text-xs text-foreground whitespace-nowrap" ${headerTooltip}>${escapeHtml(entry.header)}</td>
          <td class="py-2 pr-4 text-xs text-muted-foreground">${escapeHtml(columnMeaning(entry.header, entry))}</td>
          <td class="py-2 pr-4">
            <span class="inline-flex w-fit items-center gap-1 rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-foreground"
              ${tooltip(columnTypeTooltip(entry.type, entry))}>
              <span class="material-symbols-outlined text-[14px]!">${columnTypeIcon(entry.type, entry)}</span>
              ${escapeHtml(columnTypeLabel(entry.type, entry))}
            </span>
          </td>
          <td class="py-2 pr-4 text-xs ${entry.required ? "font-medium text-danger" : "text-muted-foreground"}">
            ${escapeHtml(requiredLabel(entry.required))}
          </td>
          <td class="py-2 text-xs text-muted-foreground">${escapeHtml(columnExample(entry.header, entry, sampleRows))}</td>
        </tr>
      `
    }).join("")

    return `
      <section data-import-columns class="space-y-3">
        <div class="rounded-xl border border-primary/30 bg-primary/5 p-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-start gap-3">
              <span class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                <span class="material-symbols-outlined text-[22px]!">download</span>
              </span>
              <div>
                <h4 class="text-sm font-bold text-foreground">${translate("Start here: download the starter file")}</h4>
                <p class="mt-1 text-xs text-muted-foreground">
                  ${translate("Open it in Excel or Google Sheets, fill one row per record, and save it as CSV. The first row already has the exact column names.")}
                </p>
              </div>
            </div>
            <button type="button" data-action="click->${this.identifier}#downloadStarterCsv"
              class="inline-flex shrink-0 items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-bold text-primary-foreground hover:bg-primary/90 cursor-pointer"
              ${tooltip(translate("Downloads a CSV with these exact headers and one example row. Open it in Excel or Google Sheets, replace the example row, and save."))}>
              <span class="material-symbols-outlined text-[18px]!">download</span>
              ${translate("Download starter CSV")}
            </button>
          </div>
          <div class="mt-3 flex flex-wrap items-center gap-2 border-t border-primary/20 pt-3">
            <button type="button" data-action="click->${this.identifier}#copyHeaders"
              class="inline-flex items-center gap-1 px-3 py-1.5 bg-card text-foreground border border-line rounded-lg text-xs font-medium hover:bg-muted cursor-pointer"
              ${tooltip(translate("Copies the header row so you can paste it into the first row of your spreadsheet."))}>
              <span class="material-symbols-outlined text-[16px]!">content_copy</span>
              ${translate("Copy headers")}
            </button>
            <p class="text-[11px] text-muted-foreground">${translate("Prefer a spreadsheet? Copy the headers instead.")}</p>
          </div>
        </div>

        <div class="flex flex-wrap items-start justify-between gap-2 pt-1">
          <div>
            <h4 class="text-xs font-bold text-muted-foreground">${translate("Expected CSV headers")}</h4>
            <p class="text-xs text-muted-foreground">
              ${translate("The CSV must use these exact names. Property columns use the category's display names.")}
            </p>
          </div>
          <span class="inline-flex items-center gap-1 rounded-full border border-line bg-muted px-2.5 py-1 text-[11px] font-bold text-muted-foreground">
            ${schema.headers.length} ${translate("columns")}
          </span>
        </div>

        <div class="overflow-x-auto rounded-lg border border-line">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line bg-muted">
                <th class="py-2 px-3" ${tooltip(translate("Use this exact text in the first row of your CSV, including capital letters."))}>${translate("Column header")}</th>
                <th class="py-2 px-3" ${tooltip(translate("What this column is for, in plain language."))}>${translate("What it means")}</th>
                <th class="py-2 px-3" ${tooltip(translate("The kind of value this column accepts."))}>${translate("Type")}</th>
                <th class="py-2 px-3" ${tooltip(translate("Required columns must be present and filled in for every row."))}>${translate("Required")}</th>
                <th class="py-2 px-3" ${tooltip(translate("An example value from your existing records, or a placeholder."))}>${translate("Example")}</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </div>

        <p class="text-[11px] text-muted-foreground">
          ${translate("Capital letters matter: 'Name' and 'name' are different.")}
        </p>
      </section>
    `
  }

  sampleHTML() {
    const sample = this.import.sample || { headers: [], rows: [], total_records: 0 }
    if ((sample.headers || []).length === 0) return ""

    // Header names are case-sensitive, so never apply `uppercase` here — the
    // sample table must show the exact CSV header strings.
    const head = sample.headers.map((entry) => `<th class="py-1.5 pr-4 whitespace-nowrap font-mono text-foreground">${escapeHtml(entry.header)}</th>`).join("")
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
        <p class="text-[11px] text-muted-foreground">${translate("Header names are case-sensitive.")}</p>
        ${sample.rows.length === 0 ? `
          <p class="text-xs text-muted-foreground">${translate("No sample records yet. Your uploaded rows will look like this.")}</p>
        ` : `
          <div class="overflow-x-auto">
            <table data-sample-table class="w-full text-xs">
              <thead>
                <tr class="text-left text-[10px] font-bold text-muted-foreground border-b border-line">${head}</tr>
              </thead>
              <tbody>${body}</tbody>
            </table>
          </div>
        `}
      </section>
    `
  }

  uploadCheckBodyHTML() {
    if (this.import.setup_locked) {
      return `<p class="text-xs text-muted-foreground">${translate("This import is locked. You cannot upload a new file.")}</p>`
    }
    if (!this.import.schema) return this.lockedStepHTML(3)

    return `${this.uploadHTML()}${this.dryRunButtonHTML()}${this.dryRunHTML()}`
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
      <section class="space-y-2">
        <h4 class="text-sm font-bold text-foreground">${translate("Upload CSV")}</h4>
        <p class="text-xs text-muted-foreground">
          ${translate("Single file, max")} ${maxMb}MB · ${this.import.max_rows} ${translate("rows")}.
          ${translate("Re-uploading replaces the current file and clears the dry run.")}
        </p>
        ${currentFile}
        <div data-drop-zone
          data-action="dragover->${this.identifier}#handleDragOver dragleave->${this.identifier}#handleDragLeave drop->${this.identifier}#handleDrop"
          class="flex flex-wrap items-center gap-3 rounded-xl border-2 border-dashed border-line bg-muted/20 p-4 transition-colors">
          <span class="material-symbols-outlined text-2xl text-muted-foreground">upload_file</span>
          <div class="min-w-0 flex-1">
            <p class="text-xs font-medium text-foreground">${translate("Drop your CSV here, or choose a file.")}</p>
            <p class="text-[11px] text-muted-foreground">${translate("The file is checked in your browser before it is uploaded.")}</p>
          </div>
          <input id="import-file-input" type="file" accept=".csv,text/csv"
            data-action="change->${this.identifier}#handleFileSelect"
            class="block text-sm text-muted-foreground file:mr-3 file:px-4 file:py-2 file:rounded-lg file:border-0 file:bg-primary file:text-primary-foreground file:cursor-pointer" />
          <span class="text-xs text-muted-foreground" data-upload-status></span>
        </div>
        <div class="text-xs space-y-1" data-header-check></div>
      </section>
    `
  }

  dryRunButtonHTML() {
    const canDryRun = Boolean(!this.import.setup_locked && this.import.schema && this.import.source_filename)
    const reason = !this.import.schema
      ? translate("Save step 1 first.")
      : !this.import.source_filename
        ? translate("Upload a CSV first.")
        : ""
    const title = reason || translate("Checks every row without saving anything.")

    return `
      <div class="flex flex-wrap items-center gap-3">
        <button type="button" data-action="click->${this.identifier}#runDryRun" ${canDryRun ? "" : "disabled"}
          class="px-4 py-2 bg-warning/100 hover:bg-warning/90 text-warning-foreground rounded-lg text-sm font-medium cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
          ${tooltip(title)}>
          ${translate("Run dry run")}
        </button>
        ${reason ? `<p class="text-xs text-muted-foreground">${escapeHtml(reason)}</p>` : ""}
      </div>
    `
  }

  dryRunHTML() {
    const result = this.import.dry_run_result
    if (!result) return ""

    const headerErrors = result.header_errors || []
    const rowErrors = result.row_errors || []
    const verdict = result.passed
      ? `${translate("All")} ${result.valid_rows} ${translate("rows look good. You can import now.")}`
      : `${result.invalid_rows} ${translate("of")} ${result.total_rows} ${translate("rows have problems. Fix them in your file and upload again.")}`

    return `
      <section class="p-4 rounded-xl border border-line bg-card space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground">${translate("Dry run result")}</h3>
          <span class="text-sm font-medium ${result.passed ? "text-success" : "text-danger"}">
            ${result.passed ? translate("Passed") : translate("Failed")}
          </span>
        </div>
        <p class="text-xs ${result.passed ? "text-success" : "text-danger"}">${escapeHtml(verdict)}</p>
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
          <div class="flex justify-end">
            <button type="button" data-action="click->${this.identifier}#downloadProblemRows"
              class="px-3 py-1.5 bg-muted hover:bg-card text-foreground rounded-lg text-xs font-medium cursor-pointer"
              ${tooltip(translate("Downloads a CSV with the row numbers and problems so you can fix them in your file."))}>
              ${translate("Download problem rows")}
            </button>
          </div>
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

  resultSummaryHTML() {
    const status = this.import.workflow_status
    const total = this.import.total_rows || 0
    const created = this.import.created_rows || 0
    const failed = this.import.failed_rows || 0

    if (status === "approved" || status === "processing") {
      return `
        <div class="rounded-lg border border-primary/30 bg-primary/10 p-3 text-sm text-foreground">
          ${translate("Importing… You can leave this page; you'll be notified when it's done.")}
          ${translate("Undo will be available when it finishes.")}
        </div>
      `
    }

    if (status === "rolling_back") {
      return `
        <div class="rounded-lg border border-primary/30 bg-primary/10 p-3 text-sm text-foreground">
          ${translate("Undoing… removing the records this import created.")}
        </div>
      `
    }

    if (status === "completed") {
      return `
        <div class="rounded-lg border border-success/30 bg-success/10 p-3 text-sm text-foreground">
          ${translate("Imported")} ${created} ${translate("of")} ${total} ${translate("records. You can undo this import if needed.")}
        </div>
      `
    }

    if (status === "failed") {
      return `
        <div class="rounded-lg border border-danger/30 bg-danger/10 p-3 text-sm text-foreground">
          ${translate("Import finished with problems:")} ${created} ${translate("created")}, ${failed} ${translate("failed. You can undo the created records and try again.")}
        </div>
      `
    }

    if (status === "rolled_back") {
      return `
        <div class="rounded-lg border border-line bg-muted/40 p-3 text-sm text-foreground">
          ${translate("This import was undone. No records from it remain.")}
        </div>
      `
    }

    return ""
  }

  reviewHTML() {
    if (this.import.setup_locked) {
      return `${this.resultSummaryHTML()}${this.actionsHTML()}`
    }

    const total = this.import.total_rows || 0
    const summary = `
      <div class="rounded-lg border border-line bg-muted/30 p-3 text-sm">
        <div class="grid gap-2 sm:grid-cols-3">
          <div>
            <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Target")}</p>
            <p class="font-medium text-foreground">${this.import.target_table ? escapeHtml(targetTableLabel(this.import.target_table)) : "—"}</p>
          </div>
          <div>
            <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Category")}</p>
            <p class="font-medium text-foreground">${escapeHtml(this.import.category_name || "—")}</p>
          </div>
          <div>
            <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Rows")}</p>
            <p class="font-medium text-foreground">${total}</p>
          </div>
        </div>
        <p class="mt-2 text-xs text-muted-foreground">
          ${translate("Creates new records only — nothing is updated. Nothing is imported until you click Approve.")}
        </p>
      </div>
    `

    return `${summary}${this.resultSummaryHTML()}${this.actionsHTML()}`
  }

  approveDisabledReason() {
    if (this.import.can_approve) return ""
    if (!this.import.source_filename) return translate("Upload and check your file first.")
    if (this.import.dry_run_result?.passed !== true) return translate("Run the dry run and fix any errors first.")
    return translate("This import is not ready yet.")
  }

  actionsHTML() {
    const locked = this.import.setup_locked
    const canApprove = this.import.can_approve
    const canRollback = this.import.can_rollback
    const approveReason = this.approveDisabledReason()

    return `
      <section class="flex flex-wrap items-center gap-3">
        ${!locked ? `
          <button type="button" data-action="click->${this.identifier}#approve" ${canApprove ? "" : "disabled"}
            class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg text-sm font-medium cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
            ${tooltip(canApprove ? translate("Creates the records in the background. You can undo it afterwards.") : approveReason)}>
            ${translate("Approve")}
          </button>
          ${approveReason ? `<p class="text-xs text-muted-foreground">${escapeHtml(approveReason)}</p>` : ""}
        ` : ""}
        ${canRollback ? `
          <button type="button" data-action="click->${this.identifier}#rollback"
            class="px-4 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg text-sm font-medium cursor-pointer"
            ${tooltip(translate("Deletes only the records this import created. Records you added by hand are not affected."))}>
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
          ${this.stepperHTML()}
          ${this.instructionsHTML()}
          ${this.stepCardHTML(1, translate("What you're importing"), translate("Choose what you are importing and the category it belongs to."), this.setupHTML())}
          ${this.stepCardHTML(2, translate("Prepare your file"), translate("Download the starter file and fill one row per record."), `${this.columnGuideHTML()}${this.sampleHTML()}`)}
          ${this.stepCardHTML(3, translate("Upload & check"), translate("Upload the file and check the rows before importing."), this.uploadCheckBodyHTML())}
          ${this.stepCardHTML(4, translate("Review & import"), translate("Review, import, and undo if needed."), this.reviewHTML())}
        </div>
      </div>
    `
  }
}
