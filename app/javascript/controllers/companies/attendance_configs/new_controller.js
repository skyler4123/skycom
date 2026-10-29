import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceConfigs_NewController extends Companies_LayoutController {
  // New Attendance Config form — branch geofence + resolution strategy.
  // Depends on BE: Companies::AttendanceConfigsController#create
  // Endpoints: POST /companies/:company_id/attendance_configs
  // Docs: docs/HR.md
  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Attendance Config")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Branch ID")}</label>
            <input type="text" name="attendance_config[branch_id]" required placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Latitude")}</label>
            <input type="number" step="0.000001" name="attendance_config[latitude]" required placeholder="e.g. 10.773"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Longitude")}</label>
            <input type="number" step="0.000001" name="attendance_config[longitude]" required placeholder="e.g. 106.694"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Allowed Radius (m)")}</label>
            <input type="number" name="attendance_config[allowed_radius_meters]" value="100"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("WiFi SSID")}</label>
            <input type="text" name="attendance_config[allowed_wifi_ssid]" placeholder="e.g. Clinic_WiFi"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Resolution Strategy")}</label>
            <select name="attendance_config[resolution_strategy]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              <option value="paired">Paired (check in/out)</option>
              <option value="check_in_only">Check In Only</option>
            </select>
          </div>
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="attendance_config[require_photo]" value="false">
            <input type="checkbox" name="attendance_config[require_photo]" value="true"
              class="h-5 w-5 rounded border-line text-primary cursor-pointer">
            <span class="text-sm text-foreground">${translate("Require Photo")}</span>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_attendance_configs_path(currentCompany().id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_attendance_configs_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
