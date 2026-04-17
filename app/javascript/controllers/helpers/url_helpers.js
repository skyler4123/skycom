
// export const retail_pos_branches_path = (retailId, branchId) => `/retail/${retailId}/pos/branches/${branchId}`
// export const retail_management_branches_path = (retailId) => `/retail/${retailId}/management/branches`
// export const edit_retail_management_branches_path = (retailId, branchId) => `/retail/${retailId}/management/branches/${branchId}`
// export const retail_management_departments_path = (retailId) => `/retail/${retailId}/management/departments`
// export const retail_management_products_path = (retailId) => `/retail/${retailId}/management/products`
// export const retail_management_services_path = (retailId) => `/retail/${retailId}/management/services`
// export const retail_management_customers_path = (retailId) => `/retail/${retailId}/management/customers`
// export const retail_management_facilities_path = (retailId) => `/retail/${retailId}/management/facilities`
// export const retail_management_employees_path = (retailId) => `/retail/${retailId}/management/employees`
// export const retail_management_orders_path = (retailId) => `/retail/${retailId}/management/orders`
// export const retail_management_permissions_path = (retailId) => `/retail/${retailId}/management/permissions`
// export const retail_management_roles_path = (retailId) => `/retail/${retailId}/management/roles`
// export const retail_management_settings_path = (retailId) => `/retail/${retailId}/management/settings`
// export const retail_management_users_path = (retailId) => `/retail/${retailId}/management/users`

// --- Paths ---
export const root_path = () => `/`
export const sign_in_path = () => `/sign_in`
export const sign_up_path = () => `/sign_up`
export const sign_out_path = () => `/sign_out`

export const company_dashboards_path = (companyId) => `/companies/${companyId}/dashboards`

export const company_branches_path = (companyId) => `/companies/${companyId}/branches`
export const new_company_branches_path = (companyId) => `/companies/${companyId}/branches/new`

export const company_branches_new_path = (companyId) => `/companies/${companyId}/branches/new`
export const company_departments_path = (companyId) => `/companies/${companyId}/departments`
export const company_products_path = (companyId) => `/companies/${companyId}/products`
export const company_services_path = (companyId) => `/companies/${companyId}/services`
export const company_customers_path = (companyId) => `/companies/${companyId}/customers`
export const company_facilities_path = (companyId) => `/companies/${companyId}/facilities`
export const company_employees_path = (companyId) => `/companies/${companyId}/employees`
export const edit_company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`
export const company_orders_path = (companyId) => `/companies/${companyId}/orders`
export const company_permissions_path = (companyId) => `/companies/${companyId}/permissions`
export const company_roles_path = (companyId) => `/companies/${companyId}/roles`
export const company_bookings_path = (companyId) => `/companies/${companyId}/bookings`
export const company_settings_path = (companyId) => `/companies/${companyId}/settings`
export const company_users_path = (companyId) => `/companies/${companyId}/users`
export const company_payments_path = (companyId) => `/companies/${companyId}/payments`
export const company_schedules_path = (companyId) => `/companies/${companyId}/schedules`
export const company_attendances_path = (companyId) => `/companies/${companyId}/attendances`
export const company_reports_path = (companyId) => `/companies/${companyId}/reports`
export const company_documents_path = (companyId) => `/companies/${companyId}/documents`
export const company_announcements_path = (companyId) => `/companies/${companyId}/announcements`
export const company_events_path = (companyId) => `/companies/${companyId}/events`
export const company_discounts_path = (companyId) => `/companies/${companyId}/discounts`
export const company_subscriptions_path = (companyId) => `/companies/${companyId}/subscriptions`
export const company_policies_path = (companyId) => `/companies/${companyId}/policies`
export const company_policies_create_path = (companyId) => `/companies/${companyId}/policies`
export const company_policy_appointment_path = (companyId, appointmentId) => `/companies/${companyId}/policy_appointments/${appointmentId}`
export const company_role_permissions_path = (companyId, roleId) => `/companies/${companyId}/permissions?role_id=${roleId}`
export const company_tasks_path = (companyId) => `/companies/${companyId}/tasks`
export const company_payslips_path = (companyId) => `/companies/${companyId}/payslips`

export const company_invoices_path = (companyId) => `/companies/${companyId}/invoices`
export const company_inventories_path = (companyId) => `/companies/${companyId}/inventories`