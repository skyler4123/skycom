import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_CompanyMigrations_NewModalController from "controllers/companies/company_migrations/new_modal_controller"

export default class Companies_CompanyMigrations_IndexController extends Companies_LayoutController {
  // Data Import index — migration list, create modal, guarded draft delete.
  // Full import workflow (upload/split, config editor, dry run, approve,
  // rollback, progress) lives on the show page.
  // Depends on BE: Companies::CompanyMigrationsController (index/create/destroy)
  // Endpoints: GET <pathname>.json, POST /companies/:id/company_migrations.json,
  //            DELETE /companies/:id/company_migrations/:id
  // Docs: docs/DATA_IMPORT.md

  /** @type {CompanyMigration[]} */ migrations = []

  async connect() {
    super.connect()

    try {
      /** @type {{ company_migrations: CompanyMigration[] }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.migrations = response.company_migrations || []
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load imports")}: ${error.errors?.join(", ") || error.message}` })
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
    if (!confirm(translate("Delete this import and its uploaded chunks?"))) return

    try {
      const response = await fetchJson(Helpers.company_company_migration_path(currentCompany().id, migrationId), {
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
        return "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
      case "failed":
        return "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-300"
      case "approved":
      case "processing":
        return "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
      case "rolling_back":
      case "rolled_back":
        return "bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300"
      default:
        return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"
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
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex-1">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white">${translate("Data Import")}</h2>
            <button type="button" data-action="click->${this.identifier}#openNewModal"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Import")}
            </button>
          </div>

          ${this.migrations.length === 0
            ? `<p class="mt-6 text-sm text-slate-400 text-center">${translate("No imports yet")}</p>`
            : `<div class="overflow-x-auto">
                <table class="w-full text-sm">
                  <thead>
                    <tr class="text-left text-[10px] font-bold text-slate-400 uppercase border-b border-slate-200 dark:border-slate-800">
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
                      <tr data-migration-id="${migration.id}" class="border-b border-slate-100 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/40">
                        <td class="py-2 pr-4">
                          <a href="${Helpers.company_company_migration_path(companyId, migration.id)}"
                            class="font-medium text-blue-600 dark:text-blue-400 hover:underline">
                            ${escapeHtml(migration.name)}
                          </a>
                        </td>
                        <td class="py-2 pr-4 text-slate-500">${escapeHtml(migration.target_resource || "—")}</td>
                        <td class="py-2 pr-4">
                          <span class="px-2 py-0.5 rounded-full text-[11px] font-medium ${this.statusBadgeClasses(migration.workflow_status)}">
                            ${escapeHtml(this.statusLabel(migration.workflow_status))}
                          </span>
                        </td>
                        <td class="py-2 pr-4 text-slate-500">${migration.processed_rows}/${migration.total_rows}</td>
                        <td class="py-2 pr-4 text-slate-500">${Helpers.timeFormat(migration.created_at, "YYYY-MM-DD HH:mm")}</td>
                        <td class="py-2 text-right">
                          ${migration.workflow_status === "draft" ? `
                            <button type="button" title="${translate("Delete")}" aria-label="${translate("Delete")}"
                              data-action="click->${this.identifier}#deleteMigration" data-migration-id="${migration.id}"
                              class="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-lg cursor-pointer">
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
