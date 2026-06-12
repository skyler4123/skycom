
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

export const users_path = () => `/users`
export const users_update_avatar_path = () => `/users/update_avatar`

export const create_companies_path = () => `/companies`
export const company_dashboards_path = (companyId) => `/companies/${companyId}/dashboards`

export const company_branches_path = (companyId) => `/companies/${companyId}/branches`
export const create_company_branches_path = (companyId) => `/companies/${companyId}/branches`
export const edit_company_branch_path = (companyId, branchId) => `/companies/${companyId}/branches/${branchId}`

export const company_branches_new_path = (companyId) => `/companies/${companyId}/branches/new`
export const company_departments_path = (companyId) => `/companies/${companyId}/departments`
export const create_company_departments_path = (companyId) => `/companies/${companyId}/departments`
export const edit_company_department_path = (companyId, departmentId) => `/companies/${companyId}/departments/${departmentId}`

export const company_categories_path = (companyId) => `/companies/${companyId}/categories`
export const create_company_categories_path = (companyId) => `/companies/${companyId}/categories`
export const edit_company_category_path = (companyId, categoryId) => `/companies/${companyId}/categories/${categoryId}`

export const company_property_mappings_path = (companyId) => `/companies/${companyId}/property_mappings`
export const edit_company_property_mapping_path = (companyId, mappingId) => `/companies/${companyId}/property_mappings/${mappingId}`

export const company_products_path = (companyId) => `/companies/${companyId}/products`
export const new_company_product_path = (companyId) => `/companies/${companyId}/products/new`
export const create_company_products_path = (companyId) => `/companies/${companyId}/products`
export const company_product_path = (companyId, productId) => `/companies/${companyId}/products/${productId}`
export const edit_company_product_path = (companyId, productId) => `/companies/${companyId}/products/${productId}/edit`
export const company_services_path = (companyId) => `/companies/${companyId}/services`
export const create_company_services_path = (companyId) => `/companies/${companyId}/services`
export const edit_company_service_path = (companyId, serviceId) => `/companies/${companyId}/services/${serviceId}`
export const company_customers_path = (companyId) => `/companies/${companyId}/customers`
export const create_company_customers_path = (companyId) => `/companies/${companyId}/customers`
export const edit_company_customer_path = (companyId, customerId) => `/companies/${companyId}/customers/${customerId}`
export const company_brands_path = (companyId) => `/companies/${companyId}/brands`
export const create_company_brands_path = (companyId) => `/companies/${companyId}/brands`
export const edit_company_brand_path = (companyId, brandId) => `/companies/${companyId}/brands/${brandId}`
export const company_facilities_path = (companyId) => `/companies/${companyId}/facilities`
export const create_company_facilities_path = (companyId) => `/companies/${companyId}/facilities`
export const edit_company_facility_path = (companyId, facilityId) => `/companies/${companyId}/facilities/${facilityId}`

export const company_employees_path = (companyId) => `/companies/${companyId}/employees`
export const create_company_employees_path = (companyId) => `/companies/${companyId}/employees`
export const edit_company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`
export const delete_company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`

export const company_orders_path = (companyId) => `/companies/${companyId}/orders`
export const create_company_orders_path = (companyId) => `/companies/${companyId}/orders`
export const edit_company_order_path = (companyId, orderId) => `/companies/${companyId}/orders/${orderId}`

export const company_permissions_path = (companyId) => `/companies/${companyId}/permissions`
export const edit_company_permission_path = (companyId, permissionId) => `/companies/${companyId}/permissions/${permissionId}`

export const company_roles_path = (companyId) => `/companies/${companyId}/roles`
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
export const company_tasks_path = (companyId) => `/companies/${companyId}/tasks`
export const company_payslips_path = (companyId) => `/companies/${companyId}/payslips`

export const company_invoices_path = (companyId) => `/companies/${companyId}/invoices`
export const create_company_invoices_path = (companyId) => `/companies/${companyId}/invoices`
export const edit_company_invoice_path = (companyId, invoiceId) => `/companies/${companyId}/invoices/${invoiceId}`
export const company_stocks_path = (companyId) => `/companies/${companyId}/stocks`
export const company_stock_transfers_path = (companyId) => `/companies/${companyId}/stock_transfers`
export const company_stock_imports_path = (companyId) => `/companies/${companyId}/stock_imports`
export const company_stock_exports_path = (companyId) => `/companies/${companyId}/stock_exports`