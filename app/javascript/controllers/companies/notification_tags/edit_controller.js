import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_NotificationTags_EditController extends Companies_LayoutController {
  // Notification tag edit form — prefilled name + description, delete for custom.
  // Depends on BE: Companies::NotificationTagsController#edit + #update + #destroy
  // Endpoints: GET company_notification_tag_path.json, PATCH company_notification_tag_path, DELETE company_notification_tag_path
  /** @type {any | null} */
  tag = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_notification_tag_path(companyId, recordId)}.json`)
      this.tag = response.notification_tag

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load notification tag.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const t = this.tag
    if (!t) return `<div class="p-8 text-center">${translate("Notification tag not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Notification Tag")}</h2>
        <p class="text-sm text-muted-foreground">${t.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
            <input type="text" name="notification_tag[name]" value="${t.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
            <textarea name="notification_tag[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">${t.description || ''}</textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_notification_tag_path(companyId, t.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_notification_tag_path(companyId, t.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
        <div class="mt-4 flex justify-end">
          ${form({
            action: Helpers.company_notification_tag_path(companyId, t.id),
            method: "DELETE",
            attributes: `data-turbo="false" class="inline"`,
            html: `<button type="submit" class="px-6 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">${translate("Delete")}</button>`
          })}
        </div>
      </div>`
  }
}
