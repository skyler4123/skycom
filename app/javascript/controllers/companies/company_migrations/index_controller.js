import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_CompanyMigrations_NewModalController from "controllers/companies/company_migrations/new_modal_controller"

export default class Companies_CompanyMigrations_IndexController extends Companies_LayoutController {
  // Migrations index — migration list, create modal, guarded draft delete.
  // Full import workflow (upload/split, config editor, dry run, approve,
  // rollback, progress) lives on the show page.
  // Depends on BE: Companies::CompanyMigrationsController (index/create/destroy)
  // Endpoints: GET <pathname>.json, POST /companies/:id/company_migrations.json,
  //            DELETE /companies/:id/company_migrations/:id
  // Docs: docs/DATA_MIGRATION.md

  /** @type {CompanyMigration[]} */ migrations = []

  async connect() {
    super.connect()

    try {
      /** @type {{ company_migrations: CompanyMigration[] }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.migrations = response.company_migrations || []
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load migrations")}: ${error.errors?.join(", ") || error.message}` })
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
    openModal({ html: `<div data-controller="${identifier(Companies_CompanyMigrations_NewModalController)}"></div>` })
  }

  async deleteMigration(event) {
    const migrationId = event.currentTarget.dataset.migrationId
    if (!confirm(translate("Delete this migration and its uploaded chunks?"))) return

    try {
      const response = await fetchJson(Helpers.company_company_migration_path(currentCompany().id, migrationId), {
        method: "DELETE"
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete migration") })
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

  contentHTML() {
    const companyId = currentCompany().id

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-4 bg-card rounded-xl border border-line flex-1">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-bold text-foreground">${translate("Migrations")}</h2>
            <button type="button" data-action="click->${this.identifier}#openNewModal"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Migration")}
            </button>
          </div>

          ${this.migrations.length === 0
            ? `<p class="mt-6 text-sm text-muted-foreground text-center">${translate("No migrations yet")}</p>`
            : `<div class="overflow-x-auto">
                <table class="w-full text-sm">
                  <thead>
                    <tr class="text-left text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
                      <th class="py-2 pr-4">${translate("Name")}</th>
                      <th class="py-2 pr-4">${translate("Target")}</th>
                      <th class="py-2 pr-4">${translate("Status")}</th>
                      <th class="py-2 pr-4">${translate("Rows")}</th>
                      <th class="py-2 pr-4">${translate("Created")}</th>
                      <th class="py-2"></th>
                    </tr>
                  </thead>
                  <tbody>
                    ${this.migrations.map((migration) => `
                      <tr data-migration-id="${migration.id}" class="border-b border-line/60 hover:bg-muted/40">
                        <td class="py-2 pr-4">
                          <a href="${Helpers.company_company_migration_path(companyId, migration.id)}"
                            class="font-medium text-primary hover:underline">
                            ${escapeHtml(migration.name)}
                          </a>
                        </td>
                        <td class="py-2 pr-4 text-muted-foreground">${escapeHtml(migration.target_resource || "—")}</td>
                        <td class="py-2 pr-4">
                          <span class="px-2 py-0.5 rounded-full text-[11px] font-medium ${this.statusBadgeClasses(migration.workflow_status)}">
                            ${escapeHtml(this.statusLabel(migration.workflow_status))}
                          </span>
                        </td>
                        <td class="py-2 pr-4 text-muted-foreground">${migration.processed_rows}/${migration.total_rows}</td>
                        <td class="py-2 pr-4 text-muted-foreground">${Helpers.timeFormat(migration.created_at, "YYYY-MM-DD HH:mm")}</td>
                        <td class="py-2 text-right">
                          ${migration.workflow_status === "draft" ? `
                            <button type="button" title="${translate("Delete")}" aria-label="${translate("Delete")}"
                              data-action="click->${this.identifier}#deleteMigration" data-migration-id="${migration.id}"
                              class="p-1.5 text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg cursor-pointer">
                              <span class="material-symbols-outlined text-[18px]">delete</span>
                              <span class="sr-only">${translate("Delete")}</span>
                            </button>
                          ` : ""}
                        </td>
                      </tr>
                    `).join("")}
                  </tbody>
                </table>
              </div>`}
        </div>
      </div>
    `
  }
}
