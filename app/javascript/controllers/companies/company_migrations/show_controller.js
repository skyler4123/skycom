import Companies_LayoutController from "controllers/companies/layout_controller"
import { splitCsvChunks } from "controllers/helpers/csv_splitter"

export default class Companies_CompanyMigrations_ShowController extends Companies_LayoutController {
  // Migrations show — browser-side chunk splitting + upload, raw preview,
  // mapping-config editor, dry run, approve/rollback, and live progress.
  // Depends on BE: Companies::CompanyMigrationsController
  //   (show/chunks/update_config/dry_run/approve/rollback)
  // Endpoints: GET <pathname>.json, POST .../chunks, PATCH .../update_config,
  //            POST .../dry_run, POST .../approve, POST .../rollback
  // WS: company_migration_progress / company_migration_finished (company channel)
  // Docs: docs/DATA_MIGRATION.md

  /** @type {CompanyMigration|null} */ migration = null
  /** @type {Object|null} */ liveProgress = null
  /** @type {string} */ loadError = ""
  uploadState = { active: false, uploaded: 0, total: 0 }

  async connect() {
    super.connect()

    try {
      /** @type {{ company_migration: CompanyMigration }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.migration = response.company_migration
    } catch (error) {
      this.loadError = error.errors?.join(", ") || error.message || ""
      toast({ type: "error", message: `${translate("Failed to load migration")}: ${this.loadError}` })
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
    if (!this.migration) return

    const channel = WEBSOCKET.channelName("company", currentCompany()?.id)
    if (!channel) return

    WEBSOCKET.subscribe(channel, "company_migration_progress", (data) => {
      if (data.id !== this.migration.id) return
      this.liveProgress = data.payload
      this.updateProgress()
    })

    WEBSOCKET.subscribe(channel, "company_migration_finished", (data) => {
      if (data.id !== this.migration.id) return
      toast({ type: "success", message: translate("Migration updated") })
      window.location.reload()
    })
  }

  // --- Upload (browser-side split) ---

  async handleFileSelect(event) {
    const file = event.target.files?.[0]
    if (!file || !this.migration || this.uploadState.active) return

    const chunks = splitCsvChunks(await file.text(), this.migration.chunk_max_bytes)
    if (chunks.length === 0) {
      toast({ type: "error", message: translate("The file is empty") })
      return
    }

    const pending = chunks.slice(this.migration.total_chunks)
    if (pending.length === 0) {
      toast({ type: "warning", message: translate("All chunks are already uploaded — re-pick the source file to continue") })
      return
    }

    this.uploadState = { active: true, uploaded: 0, total: pending.length }
    this.renderUploadStatus()

    for (const chunk of pending) {
      const formData = new FormData()
      formData.append("file", new File([ chunk.text ], `part-${String(chunk.index).padStart(3, "0")}.csv`, { type: "text/csv" }))
      formData.append("chunk_index", chunk.index)

      try {
        await fetchJson(Helpers.chunks_company_company_migration_path(currentCompany().id, this.migration.id), {
          method: "POST",
          body: formData
        })
      } catch (error) {
        this.uploadState.active = false
        this.renderUploadStatus()
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to upload chunk") })
        return
      }

      this.uploadState.uploaded += 1
      this.renderUploadStatus()
    }

    this.uploadState.active = false
    reloadThenToast({ type: "success", message: translate("Upload complete") })
  }

  renderUploadStatus() {
    const el = this.contentTarget?.querySelector("[data-upload-status]")
    if (!el) return

    el.textContent = this.uploadState.active
      ? `${translate("Chunk")} ${this.uploadState.uploaded}/${this.uploadState.total}`
      : ""
  }

  // --- Config / dry run / approve / rollback ---

  async saveConfig() {
    const editor = this.contentTarget?.querySelector("[data-config-editor]")
    if (!editor) return

    let parsed
    try {
      parsed = JSON.parse(editor.value)
    } catch (error) {
      toast({ type: "error", message: `${translate("Invalid JSON")}: ${error.message}` })
      return
    }

    try {
      const response = await fetchJson(Helpers.update_config_company_company_migration_path(currentCompany().id, this.migration.id), {
        method: "PATCH",
        body: { company_migration: { migration_mapping_config: parsed } }
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save config") })
    }
  }

  async runDryRun() {
    try {
      const response = await fetchJson(Helpers.dry_run_company_company_migration_path(currentCompany().id, this.migration.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Dry run passed") })
    } catch (error) {
      reloadThenToast({ type: "error", message: error.errors?.join(", ") || translate("Dry run failed") })
    }
  }

  async approve() {
    try {
      const response = await fetchJson(Helpers.approve_company_company_migration_path(currentCompany().id, this.migration.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to approve migration") })
    }
  }

  async rollback() {
    try {
      const response = await fetchJson(Helpers.rollback_company_company_migration_path(currentCompany().id, this.migration.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to queue rollback") })
    }
  }

  // --- Live progress ---

  progressSource() {
    return this.liveProgress || this.migration
  }

  updateProgress() {
    const bar = this.contentTarget?.querySelector("[data-migration-progress]")
    if (bar) bar.innerHTML = this.progressInnerHTML()

    if (this.liveProgress) {
      const badge = this.contentTarget?.querySelector("[data-status-badge]")
      if (badge) badge.outerHTML = this.statusBadgeHTML(this.liveProgress.status)
    }
  }

  progressInnerHTML() {
    const source = this.progressSource()
    const total = source.total_rows || 0
    const processed = source.processed_rows || 0
    const percent = total > 0 ? Math.min(100, Math.round((processed / total) * 100)) : 0

    return `
      <div class="flex items-center justify-between text-xs text-muted-foreground mb-1">
        <span>${processed}/${total} ${translate("Rows")}</span>
        <span>
          ${translate("Created")}: ${source.created_rows || 0} ·
          ${translate("Updated")}: ${source.updated_rows || 0} ·
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
        return "bg-primary/10 text-primary "
      case "rolling_back":
      case "rolled_back":
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
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-lg font-bold text-foreground">${escapeHtml(this.migration.name)}</h2>
          <p class="text-xs text-muted-foreground mt-0.5">${escapeHtml(this.migration.target_resource || "—")}</p>
        </div>
        ${this.statusBadgeHTML(this.migration.workflow_status)}
      </div>
    `
  }

  uploadHTML() {
    if (this.migration.config_locked) return ""

    return `
      <section class="space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Upload CSV chunks")}</h3>
        <p class="text-xs text-muted-foreground">
          ${translate("The file is split in your browser and uploaded chunk by chunk")}
          (≤ ${Math.round(this.migration.chunk_max_bytes / 1024)} KB).
        </p>
        <div class="flex items-center gap-3">
          <input id="migration-upload-input" type="file" accept=".csv,text/csv"
            data-action="change->${this.identifier}#handleFileSelect"
            class="block text-sm text-muted-foreground file:mr-3 file:px-4 file:py-2 file:rounded-lg file:border-0 file:bg-primary file:text-primary-foreground file:cursor-pointer" />
          <span class="text-xs text-muted-foreground" data-upload-status></span>
        </div>
      </section>
    `
  }

  chunksHTML() {
    const chunks = this.migration.chunks || []
    if (chunks.length === 0) return ""

    return `
      <section class="space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Chunks")}</h3>
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
              <th class="py-2 pr-4">${translate("Name")}</th>
              <th class="py-2 pr-4">${translate("Rows")}</th>
              <th class="py-2">${translate("Status")}</th>
            </tr>
          </thead>
          <tbody>
            ${chunks.map((chunk) => `
              <tr class="border-b border-line/60">
                <td class="py-1.5 pr-4">${escapeHtml(chunk.name)}</td>
                <td class="py-1.5 pr-4 text-muted-foreground">${chunk.row_count}</td>
                <td class="py-1.5 text-muted-foreground">${escapeHtml(chunk.import_status || "")}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </section>
    `
  }

  previewHTML() {
    const preview = this.migration.preview || { headers: [], rows: [] }
    if (!preview.headers || preview.headers.length === 0) return ""

    return `
      <section class="space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Preview")}</h3>
        <div class="overflow-x-auto">
          <table class="w-full text-xs">
            <thead>
              <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
                ${preview.headers.map((header) => `<th class="py-1.5 pr-4">${escapeHtml(header)}</th>`).join("")}
              </tr>
            </thead>
            <tbody>
              ${preview.rows.map((row) => `
                <tr class="border-b border-line/60">
                  ${row.map((cell) => `<td class="py-1 pr-4 text-muted-foreground whitespace-nowrap">${escapeHtml(cell)}</td>`).join("")}
                </tr>
              `).join("")}
            </tbody>
          </table>
        </div>
      </section>
    `
  }

  configHTML() {
    const locked = this.migration.config_locked
    const json = escapeHtml(JSON.stringify(this.migration.migration_mapping_config || {}, null, 2))

    return `
      <section class="space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Mapping config (JSON)")}</h3>
        <textarea data-config-editor rows="10" spellcheck="false" ${locked ? "disabled" : ""}
          class="w-full font-mono text-xs px-3 py-2 border border-line rounded-lg bg-card text-foreground disabled:opacity-60">${json}</textarea>
        ${locked ? "" : `
          <button type="button" data-action="click->${this.identifier}#saveConfig"
            class="px-4 py-2 bg-muted hover:bg-card text-foreground rounded-lg text-sm font-medium cursor-pointer">
            ${translate("Save config")}
          </button>
        `}
      </section>
    `
  }

  dryRunHTML() {
    const result = this.migration.dry_run_result
    if (!result) return ""

    const rows = result.rows || []
    const errorRows = rows.filter((row) => (row.errors || []).length > 0)
    const globalErrors = result.errors || []

    return `
      <section class="space-y-2">
        <h3 class="text-sm font-bold text-foreground">${translate("Dry run result")}</h3>
        <p class="text-sm font-medium ${result.passed ? "text-success" : "text-danger"}">
          ${result.passed ? translate("Passed") : translate("Failed")} —
          ${translate("Created")}: ${result.created}, ${translate("Updated")}: ${result.updated}
        </p>
        ${globalErrors.length > 0 ? `<p class="text-xs text-danger">${escapeHtml(globalErrors.join(", "))}</p>` : ""}
        ${errorRows.length > 0 ? `
          <div class="overflow-x-auto">
            <table class="w-full text-xs">
              <thead>
                <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase">
                  <th class="py-1 pr-4">${translate("Row")}</th>
                  <th class="py-1">${translate("Errors")}</th>
                </tr>
              </thead>
              <tbody>
                ${errorRows.map((row) => `
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
    const canApprove = this.migration.can_approve
    const canRollback = this.migration.can_rollback
    const configLocked = this.migration.config_locked

    return `
      <section class="flex items-center gap-3">
        ${configLocked ? "" : `
          <button type="button" data-action="click->${this.identifier}#runDryRun"
            class="px-4 py-2 bg-warning/100 hover:bg-warning/90 text-warning-foreground rounded-lg text-sm font-medium cursor-pointer">
            ${translate("Run dry run")}
          </button>
        `}
        <button type="button" data-action="click->${this.identifier}#approve" ${canApprove ? "" : "disabled"}
          class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg text-sm font-medium cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
          ${translate("Approve")}
        </button>
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
    if (!this.migration) {
      return `
        <div class="p-4 flex-1 flex flex-col">
          <div class="p-4 bg-card rounded-xl border border-danger/20 ">
            <h2 class="text-lg font-bold text-danger ">${translate("Could not load this migration")}</h2>
            <p class="mt-1 text-sm text-muted-foreground">${escapeHtml(this.loadError)}</p>
            <a href="${Helpers.company_company_migrations_path(currentCompany()?.id)}"
              class="mt-3 inline-block text-sm text-primary hover:underline">
              ${translate("Back to Migrations")}
            </a>
          </div>
        </div>
      `
    }

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-4 bg-card rounded-xl border border-line flex-1 space-y-6">
          ${this.headerHTML()}
          <div data-migration-progress>${this.progressInnerHTML()}</div>
          ${this.uploadHTML()}
          ${this.chunksHTML()}
          ${this.previewHTML()}
          ${this.configHTML()}
          ${this.dryRunHTML()}
          ${this.actionsHTML()}
        </div>
      </div>
    `
  }
}
