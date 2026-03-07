import { Controller } from "@hotwired/stimulus"

export default class Companies_Administrators_UpdatePermissionController extends Controller {
  connect() {
    // console.log("connect")
  }

  // Stimulus convention: data-controller-role-id-param -> roleIdParam
  async change(event) {
    const isChecked = event.target.checked
    const { roleId, resourceName, action } = event.params
    const company = currentCompany()

    // 1. Ask for confirmation
    const message = `Are you sure you want to ${isChecked ? 'grant' : 'revoke'} the "${action}" permission for ${resourceName}s?`
    
    if (!window.confirm(message)) {
      // 2. If user cancels, revert the checkbox UI and stop
      event.target.checked = !isChecked
      return
    }

    if (!company) return console.error("No active company context.")

    const url = Helpers.update_permission_company_administrators_path(currentCompany().id)

    try {
      await fetchJson(url, {
        method: 'PATCH',
        body: {
          role_id: roleId,
          resource: resourceName,
          permission_action: action,
          status: isChecked
        }
      })
      console.log(`Synced: ${resourceName} ${action} for Role ID ${roleId}`)
      alert("Permission updated successfully.")
    } catch (error) {
      // 3. Revert checkbox state if the server fails
      event.target.checked = !isChecked
      alert("Failed to update permission. Please try again.")
    }
  }
}
