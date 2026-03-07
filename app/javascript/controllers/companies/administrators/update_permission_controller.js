import { Controller } from "@hotwired/stimulus"

export default class Companies_Administrators_UpdatePermissionController extends Controller {
  connect() {
    console.log("connect")
  }

  // Stimulus convention: data-controller-role-id-param -> roleIdParam
  async change(event) {
    const isChecked = event.target.checked
    const { roleId, resourceName, action } = event.params
    const company = currentCompany()

    if (!company) return console.error("No active company context.")

    // We hit the collection route we will define in the next step
    const url = Helpers.update_permission_company_administrators_path(currentCompany().id)

    try {
      await fetchJson(url, {
        method: 'PATCH',
        body: {
          role_id: roleId,
          resource: resourceName,
          permission_action: action, // 'action' is a reserved word in some contexts, so we use permission_action
          status: isChecked
        }
      })
      console.log(`Synced: ${resourceName} ${action} for Role ID ${roleId}`)
    } catch (error) {
      // Revert checkbox state if the server fails
      event.target.checked = !isChecked
      alert("Failed to update permission. Please try again.")
    }
  }
}
