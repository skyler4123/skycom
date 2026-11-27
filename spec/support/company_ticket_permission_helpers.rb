# Grants a company employee ABAC policies for CompanyTicket specs.
# Returns the reloaded employee with fresh permission caches.
module CompanyTicketPermissionHelpers
  def grant_company_ticket_permissions(employee, *actions, resource: "CompanyTicket")
    company = employee.company
    role = create(:role, company: company, name: "TicketPermissions#{SecureRandom.hex(3)}")
    create(:employee_role_appointment, company: company, employee: employee, role: role)

    actions.each do |action|
      policy = Seed::PolicyService.create(
        company: company,
        name: "#{resource} #{action} #{SecureRandom.hex(3)}",
        resource: resource,
        action: action.to_s,
        business_type: :operational,
        lifecycle_status: :active
      )
      PolicyRoleAppointment.find_or_create_by!(company: company, policy: policy, role: role)
        .update!(workflow_status: :active)
    end

    company.clear_permissions_cache
    employee.clear_permissions_cache
    employee.reload
    employee
  end
end

RSpec.configure do |config|
  config.include CompanyTicketPermissionHelpers
end
