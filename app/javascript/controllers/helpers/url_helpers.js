
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
export const auth_google_oauth2_path = () => `/auth/google_oauth2`

export const admin_companies_path = () => `/admin/companies`
export const admin_company_path = (companyId) => `/admin/companies/${companyId}`

export const admin_company_credits_path = () => `/admin/company_credits`

export const admin_promo_campaigns_path = () => `/admin/promo_campaigns`
export const new_admin_promo_campaign_path = () => `/admin/promo_campaigns/new`
export const admin_promo_campaign_path = (id) => `/admin/promo_campaigns/${id}`
export const edit_admin_promo_campaign_path = (id) => `/admin/promo_campaigns/${id}/edit`
export const create_admin_promo_campaigns_path = () => `/admin/promo_campaigns`
export const run_now_admin_promo_campaign_path = (id) => `/admin/promo_campaigns/${id}/run_now`
export const cancel_admin_promo_campaign_path = (id) => `/admin/promo_campaigns/${id}/cancel`

export const admin_payment_methods_path = () => `/admin/payment_methods`
export const new_admin_payment_method_path = () => `/admin/payment_methods/new`
export const admin_payment_method_path = (id) => `/admin/payment_methods/${id}`
export const edit_admin_payment_method_path = (id) => `/admin/payment_methods/${id}/edit`
export const create_admin_payment_methods_path = () => `/admin/payment_methods`
// Company support tickets pool (docs/superpowers/plans/2026-10-07-company-support-center.md)
export const admin_company_tickets_path = () => `/admin/company_tickets`
export const admin_company_ticket_path = (id) => `/admin/company_tickets/${id}`
export const assign_admin_company_ticket_path = (id) => `/admin/company_tickets/${id}/assign`
export const resolve_admin_company_ticket_path = (id) => `/admin/company_tickets/${id}/resolve`
export const close_admin_company_ticket_path = (id) => `/admin/company_tickets/${id}/close`
export const reopen_admin_company_ticket_path = (id) => `/admin/company_tickets/${id}/reopen`
export const comment_admin_company_ticket_path = (id) => `/admin/company_tickets/${id}/comment`

export const users_path = () => `/users`
export const users_update_avatar_path = () => `/users/update_avatar`

export const create_companies_path = () => `/companies`
export const company_path = (id) => `/companies/${id}`
export const edit_company_path = (id) => `/companies/${id}/edit`
export const company_dashboards_path = (companyId) => `/companies/${companyId}/dashboards`

export const company_branches_path = (companyId) => `/companies/${companyId}/branches`
export const create_company_branches_path = (companyId) => `/companies/${companyId}/branches`
export const edit_company_branch_path = (companyId, branchId) => `/companies/${companyId}/branches/${branchId}/edit`
export const company_branch_path = (companyId, branchId) => `/companies/${companyId}/branches/${branchId}`
export const new_company_branch_path = (companyId) => `/companies/${companyId}/branches/new`

export const company_branches_new_path = (companyId) => `/companies/${companyId}/branches/new`
export const company_departments_path = (companyId) => `/companies/${companyId}/departments`
export const create_company_departments_path = (companyId) => `/companies/${companyId}/departments`
export const company_department_path = (companyId, departmentId) => `/companies/${companyId}/departments/${departmentId}`
export const new_company_department_path = (companyId) => `/companies/${companyId}/departments/new`
export const edit_company_department_path = (companyId, departmentId) => `/companies/${companyId}/departments/${departmentId}/edit`

export const company_categories_path = (companyId) => `/companies/${companyId}/categories`
export const new_company_category_path = (companyId) => `/companies/${companyId}/categories/new`
export const create_company_categories_path = (companyId) => `/companies/${companyId}/categories`
export const company_category_path = (companyId, categoryId) => `/companies/${companyId}/categories/${categoryId}`
export const edit_company_category_path = (companyId, categoryId) => `/companies/${companyId}/categories/${categoryId}/edit`

export const company_property_mappings_path = (companyId) => `/companies/${companyId}/property_mappings`
export const new_company_property_mapping_path = (companyId) => `/companies/${companyId}/property_mappings/new`
export const create_company_property_mappings_path = (companyId) => `/companies/${companyId}/property_mappings`
export const company_property_mapping_path = (companyId, mappingId) => `/companies/${companyId}/property_mappings/${mappingId}`
export const edit_company_property_mapping_path = (companyId, mappingId) => `/companies/${companyId}/property_mappings/${mappingId}/edit`

export const company_table_configs_path = (companyId) => `/companies/${companyId}/table_configs`
export const new_company_table_config_path = (companyId) => `/companies/${companyId}/table_configs/new`
export const create_company_table_configs_path = (companyId) => `/companies/${companyId}/table_configs`
export const company_table_config_path = (companyId, configId) => `/companies/${companyId}/table_configs/${configId}`
export const edit_company_table_config_path = (companyId, configId) => `/companies/${companyId}/table_configs/${configId}/edit`
export const company_table_config_logs_path = (companyId) => `/companies/${companyId}/table_config_logs`
export const company_table_config_log_path = (companyId, id) => `/companies/${companyId}/table_config_logs/${id}`

export const company_products_path = (companyId) => `/companies/${companyId}/products`
export const new_company_product_path = (companyId) => `/companies/${companyId}/products/new`
export const create_company_products_path = (companyId) => `/companies/${companyId}/products`
export const company_product_path = (companyId, productId) => `/companies/${companyId}/products/${productId}`
export const edit_company_product_path = (companyId, productId) => `/companies/${companyId}/products/${productId}/edit`
export const company_services_path = (companyId) => `/companies/${companyId}/services`
export const create_company_services_path = (companyId) => `/companies/${companyId}/services`
export const company_service_path = (companyId, serviceId) => `/companies/${companyId}/services/${serviceId}`
export const new_company_service_path = (companyId) => `/companies/${companyId}/services/new`
export const edit_company_service_path = (companyId, serviceId) => `/companies/${companyId}/services/${serviceId}/edit`
export const company_customers_path = (companyId) => `/companies/${companyId}/customers`
export const create_company_customers_path = (companyId) => `/companies/${companyId}/customers`
export const company_customer_path = (companyId, customerId) => `/companies/${companyId}/customers/${customerId}`
export const new_company_customer_path = (companyId) => `/companies/${companyId}/customers/new`
export const edit_company_customer_path = (companyId, customerId) => `/companies/${companyId}/customers/${customerId}/edit`
export const company_brands_path = (companyId) => `/companies/${companyId}/brands`
export const create_company_brands_path = (companyId) => `/companies/${companyId}/brands`
export const company_brand_path = (companyId, brandId) => `/companies/${companyId}/brands/${brandId}`
export const new_company_brand_path = (companyId) => `/companies/${companyId}/brands/new`
export const edit_company_brand_path = (companyId, brandId) => `/companies/${companyId}/brands/${brandId}/edit`
export const company_suppliers_path = (companyId) => `/companies/${companyId}/suppliers`
export const create_company_suppliers_path = (companyId) => `/companies/${companyId}/suppliers`
export const company_supplier_path = (companyId, supplierId) => `/companies/${companyId}/suppliers/${supplierId}`
export const new_company_supplier_path = (companyId) => `/companies/${companyId}/suppliers/new`
export const edit_company_supplier_path = (companyId, supplierId) => `/companies/${companyId}/suppliers/${supplierId}/edit`
export const company_facilities_path = (companyId) => `/companies/${companyId}/facilities`
export const create_company_facilities_path = (companyId) => `/companies/${companyId}/facilities`
export const company_facility_path = (companyId, facilityId) => `/companies/${companyId}/facilities/${facilityId}`
export const new_company_facility_path = (companyId) => `/companies/${companyId}/facilities/new`
export const edit_company_facility_path = (companyId, facilityId) => `/companies/${companyId}/facilities/${facilityId}/edit`
export const company_warehouses_path = (companyId) => `/companies/${companyId}/warehouses`
export const create_company_warehouses_path = (companyId) => `/companies/${companyId}/warehouses`
export const company_warehouse_path = (companyId, warehouseId) => `/companies/${companyId}/warehouses/${warehouseId}`
export const new_company_warehouse_path = (companyId) => `/companies/${companyId}/warehouses/new`
export const edit_company_warehouse_path = (companyId, warehouseId) => `/companies/${companyId}/warehouses/${warehouseId}/edit`

export const company_employees_path = (companyId) => `/companies/${companyId}/employees`
export const create_company_employees_path = (companyId) => `/companies/${companyId}/employees`
export const company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`
export const new_company_employee_path = (companyId) => `/companies/${companyId}/employees/new`
export const edit_company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}/edit`
export const delete_company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`

export const company_employee_groups_path = (companyId) => `/companies/${companyId}/employee_groups`
export const create_company_employee_groups_path = (companyId) => `/companies/${companyId}/employee_groups`
export const company_employee_group_path = (companyId, employeeGroupId) => `/companies/${companyId}/employee_groups/${employeeGroupId}`
export const new_company_employee_group_path = (companyId) => `/companies/${companyId}/employee_groups/new`
export const edit_company_employee_group_path = (companyId, employeeGroupId) => `/companies/${companyId}/employee_groups/${employeeGroupId}/edit`

export const company_orders_path = (companyId) => `/companies/${companyId}/orders`
export const create_company_orders_path = (companyId) => `/companies/${companyId}/orders`
export const company_order_path = (companyId, orderId) => `/companies/${companyId}/orders/${orderId}`
export const new_company_order_path = (companyId) => `/companies/${companyId}/orders/new`
export const edit_company_order_path = (companyId, orderId) => `/companies/${companyId}/orders/${orderId}/edit`

export const company_pages_path = (companyId) => `/companies/${companyId}/pages`
export const create_company_pages_path = (companyId) => `/companies/${companyId}/pages`
export const company_page_path = (companyId, pageId) => `/companies/${companyId}/pages/${pageId}`
export const new_company_page_path = (companyId) => `/companies/${companyId}/pages/new`
export const edit_company_page_path = (companyId, pageId) => `/companies/${companyId}/pages/${pageId}/edit`
export const retail_cashier_company_page_path = (companyId, pageId) => `/companies/${companyId}/pages/${pageId}/retail_cashier`

export const order_processing_v1_checkout_path = (companyId) => `/companies/${companyId}/order_processing/v1/checkout`
export const order_processing_v1_pay_path = (companyId) => `/companies/${companyId}/order_processing/v1/pay`
export const order_processing_v1_pay_cancel_path = (companyId) => `/companies/${companyId}/order_processing/v1/pay_cancel`
export const receipt_company_order_path = (companyId, orderId) => `/companies/${companyId}/orders/${orderId}/receipt`

export const company_permissions_path = (companyId) => `/companies/${companyId}/permissions`
export const edit_company_permission_path = (companyId, permissionId) => `/companies/${companyId}/permissions/${permissionId}`
export const company_permission_logs_path = (companyId) => `/companies/${companyId}/permission_logs`
export const company_permission_log_path = (companyId, id) => `/companies/${companyId}/permission_logs/${id}`

export const company_roles_path = (companyId) => `/companies/${companyId}/roles`
export const new_company_role_path = (companyId) => `/companies/${companyId}/roles/new`
export const company_role_path = (companyId, roleId) => `/companies/${companyId}/roles/${roleId}`
export const edit_company_role_path = (companyId, roleId) => `/companies/${companyId}/roles/${roleId}/edit`
export const create_company_roles_path = (companyId) => `/companies/${companyId}/roles`
export const company_settings_path = (companyId, settingId) => settingId ? `/companies/${companyId}/company_settings/${settingId}` : `/companies/${companyId}/company_settings`
export const company_users_path = (companyId) => `/companies/${companyId}/users`
export const company_transactions_path = (companyId) => `/companies/${companyId}/transactions`
export const new_company_transaction_path = (companyId) => `/companies/${companyId}/transactions/new`
export const company_transaction_path = (companyId, id) => `/companies/${companyId}/transactions/${id}`
export const edit_company_transaction_path = (companyId, id) => `/companies/${companyId}/transactions/${id}/edit`
export const create_company_transactions_path = (companyId) => `/companies/${companyId}/transactions`
export const company_scheduled_shifts_path = (companyId) => `/companies/${companyId}/scheduled_shifts`
export const new_company_scheduled_shift_path = (companyId) => `/companies/${companyId}/scheduled_shifts/new`
export const company_scheduled_shift_path = (companyId, id) => `/companies/${companyId}/scheduled_shifts/${id}`
export const edit_company_scheduled_shift_path = (companyId, id) => `/companies/${companyId}/scheduled_shifts/${id}/edit`
export const create_company_scheduled_shifts_path = (companyId) => `/companies/${companyId}/scheduled_shifts`

export const company_attendance_configs_path = (companyId) => `/companies/${companyId}/attendance_configs`
export const new_company_attendance_config_path = (companyId) => `/companies/${companyId}/attendance_configs/new`
export const company_attendance_config_path = (companyId, id) => `/companies/${companyId}/attendance_configs/${id}`
export const edit_company_attendance_config_path = (companyId, id) => `/companies/${companyId}/attendance_configs/${id}/edit`
export const create_company_attendance_configs_path = (companyId) => `/companies/${companyId}/attendance_configs`

export const company_attendance_logs_path = (companyId) => `/companies/${companyId}/attendance_logs`
export const company_attendance_log_path = (companyId, id) => `/companies/${companyId}/attendance_logs/${id}`
export const company_attendance_config_logs_path = (companyId) => `/companies/${companyId}/attendance_config_logs`
export const company_attendance_config_log_path = (companyId, id) => `/companies/${companyId}/attendance_config_logs/${id}`

export const company_attendance_days_path = (companyId) => `/companies/${companyId}/attendance_days`
export const company_attendance_day_path = (companyId, id) => `/companies/${companyId}/attendance_days/${id}`

export const company_attendance_requests_path = (companyId) => `/companies/${companyId}/attendance_requests`
export const new_company_attendance_request_path = (companyId) => `/companies/${companyId}/attendance_requests/new`
export const company_attendance_request_path = (companyId, id) => `/companies/${companyId}/attendance_requests/${id}`
export const create_company_attendance_requests_path = (companyId) => `/companies/${companyId}/attendance_requests`
export const approve_company_attendance_request_path = (companyId, id) => `/companies/${companyId}/attendance_requests/${id}/approve`
export const reject_company_attendance_request_path = (companyId, id) => `/companies/${companyId}/attendance_requests/${id}/reject`

export const company_attendance_months_path = (companyId) => `/companies/${companyId}/attendance_months`
export const company_attendance_month_path = (companyId, id) => `/companies/${companyId}/attendance_months/${id}`
export const company_attendance_months_collect_path = (companyId) => `/companies/${companyId}/attendance_months/collect`
export const company_attendance_months_my_path = (companyId, month = null) => month ? `/companies/${companyId}/attendance_months/my?month=${month}` : `/companies/${companyId}/attendance_months/my`

export const company_shift_templates_path = (companyId) => `/companies/${companyId}/shift_templates`
export const new_company_shift_template_path = (companyId) => `/companies/${companyId}/shift_templates/new`
export const company_shift_template_path = (companyId, id) => `/companies/${companyId}/shift_templates/${id}`
export const edit_company_shift_template_path = (companyId, id) => `/companies/${companyId}/shift_templates/${id}/edit`
export const create_company_shift_templates_path = (companyId) => `/companies/${companyId}/shift_templates`
export const company_reports_path = (companyId) => `/companies/${companyId}/reports`
export const company_documents_path = (companyId) => `/companies/${companyId}/documents`
export const company_folders_path = (companyId) => `/companies/${companyId}/folders`
export const create_company_folders_path = (companyId) => `/companies/${companyId}/folders`
export const company_folder_path = (companyId, folderId) => `/companies/${companyId}/folders/${folderId}`
export const company_stored_files_path = (companyId) => `/companies/${companyId}/stored_files`
export const create_company_stored_files_path = (companyId) => `/companies/${companyId}/stored_files`
export const company_stored_file_path = (companyId, fileId) => `/companies/${companyId}/stored_files/${fileId}`
export const download_company_stored_file_path = (companyId, fileId) => `/companies/${companyId}/stored_files/${fileId}/download`
export const company_storage_statistics_path = (companyId) => `/companies/${companyId}/storage_statistics`
export const company_company_migrations_path = (companyId) => `/companies/${companyId}/company_migrations`
export const company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}`
export const chunks_company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}/chunks`
export const update_config_company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}/update_config`
export const dry_run_company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}/dry_run`
export const approve_company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}/approve`
export const rollback_company_company_migration_path = (companyId, migrationId) => `/companies/${companyId}/company_migrations/${migrationId}/rollback`
export const company_imports_path = (companyId) => `/companies/${companyId}/imports`
export const company_import_path = (companyId, importId) => `/companies/${companyId}/imports/${importId}`
export const source_file_company_import_path = (companyId, importId) => `/companies/${companyId}/imports/${importId}/source_file`
export const dry_run_company_import_path = (companyId, importId) => `/companies/${companyId}/imports/${importId}/dry_run`
export const approve_company_import_path = (companyId, importId) => `/companies/${companyId}/imports/${importId}/approve`
export const rollback_company_import_path = (companyId, importId) => `/companies/${companyId}/imports/${importId}/rollback`
export const create_company_documents_path = (companyId) => `/companies/${companyId}/documents`
export const new_company_document_path = (companyId) => `/companies/${companyId}/documents/new`
export const company_document_path = (companyId, documentId) => `/companies/${companyId}/documents/${documentId}`
export const edit_company_document_path = (companyId, documentId) => `/companies/${companyId}/documents/${documentId}/edit`
export const company_announcements_path = (companyId) => `/companies/${companyId}/announcements`
export const company_events_path = (companyId) => `/companies/${companyId}/events`
export const new_company_event_path = (companyId) => `/companies/${companyId}/events/new`
export const create_company_events_path = (companyId) => `/companies/${companyId}/events`
export const company_event_path = (companyId, eventId) => `/companies/${companyId}/events/${eventId}`
export const edit_company_event_path = (companyId, eventId) => `/companies/${companyId}/events/${eventId}/edit`
export const company_event_configs_path = (companyId) => `/companies/${companyId}/event_configs`
export const new_company_event_config_path = (companyId) => `/companies/${companyId}/event_configs/new`
export const create_company_event_configs_path = (companyId) => `/companies/${companyId}/event_configs`
export const company_event_config_path = (companyId, configId) => `/companies/${companyId}/event_configs/${configId}`
export const edit_company_event_config_path = (companyId, configId) => `/companies/${companyId}/event_configs/${configId}/edit`
export const company_event_config_logs_path = (companyId) => `/companies/${companyId}/event_config_logs`
export const company_event_config_log_path = (companyId, id) => `/companies/${companyId}/event_config_logs/${id}`
export const company_calendar_path = (companyId) => `/companies/${companyId}/calendar`
export const company_discounts_path = (companyId) => `/companies/${companyId}/discounts`
// Discount groups (Discount FE — docs/superpowers/specs/2026-09-22-discounts-frontend-design.md)
export const company_discount_groups_path = (companyId) => `/companies/${companyId}/discount_groups`
export const create_company_discount_groups_path = (companyId) => `/companies/${companyId}/discount_groups`
export const new_company_discount_group_path = (companyId) => `/companies/${companyId}/discount_groups/new`
export const company_discount_group_path = (companyId, discountGroupId) => `/companies/${companyId}/discount_groups/${discountGroupId}`
export const edit_company_discount_group_path = (companyId, discountGroupId) => `/companies/${companyId}/discount_groups/${discountGroupId}/edit`
export const generate_codes_company_discount_group_path = (companyId, discountGroupId) => `/companies/${companyId}/discount_groups/${discountGroupId}/generate_codes`
// Company support tickets (docs/superpowers/plans/2026-10-07-company-support-center.md)
export const company_company_tickets_path = (companyId) => `/companies/${companyId}/company_tickets`
export const new_company_company_ticket_path = (companyId) => `/companies/${companyId}/company_tickets/new`
export const company_company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/company_tickets/${ticketId}`
export const rate_company_company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/company_tickets/${ticketId}/rate`
export const company_company_ticket_comments_path = (companyId) => `/companies/${companyId}/company_ticket_comments`
export const company_company_ticket_logs_path = (companyId) => `/companies/${companyId}/company_ticket_logs`
export const company_company_ticket_log_path = (companyId, logId) => `/companies/${companyId}/company_ticket_logs/${logId}`

// Tickets (docs/TICKET.md)
export const company_tickets_path = (companyId) => `/companies/${companyId}/tickets`
export const create_company_tickets_path = (companyId) => `/companies/${companyId}/tickets`
export const new_company_ticket_path = (companyId) => `/companies/${companyId}/tickets/new`
export const company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/tickets/${ticketId}`
export const edit_company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/tickets/${ticketId}/edit`
export const advance_company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/tickets/${ticketId}/advance`
export const assign_company_ticket_path = (companyId, ticketId) => `/companies/${companyId}/tickets/${ticketId}/assign`
export const company_ticket_comments_path = (companyId) => `/companies/${companyId}/ticket_comments`
export const company_ticket_logs_path = (companyId) => `/companies/${companyId}/ticket_logs`
export const company_ticket_log_path = (companyId, logId) => `/companies/${companyId}/ticket_logs/${logId}`
// Notifications (docs/superpowers/plans/2026-10-07-notification.md)
export const company_notifications_path = (companyId) => `/companies/${companyId}/notifications`
export const company_notification_path = (companyId, notificationId) => `/companies/${companyId}/notifications/${notificationId}`
export const mark_read_company_notification_path = (companyId, notificationId) => `/companies/${companyId}/notifications/${notificationId}/mark_read`
export const mark_all_read_company_notifications_path = (companyId) => `/companies/${companyId}/notifications/mark_all_read`
export const unread_count_company_notifications_path = (companyId) => `/companies/${companyId}/notifications/unread_count`
export const company_notification_config_path = (companyId) => `/companies/${companyId}/notification_config`
export const company_notification_tags_path = (companyId) => `/companies/${companyId}/notification_tags`
export const create_company_notification_tags_path = (companyId) => `/companies/${companyId}/notification_tags`
export const new_company_notification_tag_path = (companyId) => `/companies/${companyId}/notification_tags/new`
export const company_notification_tag_path = (companyId, tagId) => `/companies/${companyId}/notification_tags/${tagId}`
export const edit_company_notification_tag_path = (companyId, tagId) => `/companies/${companyId}/notification_tags/${tagId}/edit`
export const company_subscriptions_path = (companyId) => `/companies/${companyId}/subscriptions`
export const company_policies_path = (companyId) => `/companies/${companyId}/policies`
export const company_tasks_path = (companyId) => `/companies/${companyId}/tasks`
export const company_payslips_path = (companyId) => `/companies/${companyId}/payslips`

export const company_payment_method_appointments_path = (companyId) =>
  `/companies/${companyId}/payment_method_appointments`

export const edit_company_payment_method_appointment_path = (companyId, id) =>
  `/companies/${companyId}/payment_method_appointments/${id}/edit`

export const company_payment_method_appointment_path = (companyId, id) =>
  `/companies/${companyId}/payment_method_appointments/${id}`

// PLACEHOLDER — future Token implementation. Billing page itself is future work.
export const company_billing_path = (companyId) => `/companies/${companyId}/billing`

export const company_usage_path = (companyId) => `/companies/${companyId}/usage`
export const company_usage_enable_logging_path = (companyId) => `/companies/${companyId}/usage/enable_logging`
export const company_usage_disable_logging_path = (companyId) => `/companies/${companyId}/usage/disable_logging`
export const new_company_top_up_path = (companyId) => `/companies/${companyId}/top_ups/new`
export const mock_qr_gateway_company_top_ups_path = (companyId) => `/companies/${companyId}/top_ups/mock_qr_gateway`
export const mock_redirect_gateway_company_top_ups_path = (companyId) => `/companies/${companyId}/top_ups/mock_redirect_gateway`

export const company_invoices_path = (companyId) => `/companies/${companyId}/invoices`
export const create_company_invoices_path = (companyId) => `/companies/${companyId}/invoices`
export const company_invoice_path = (companyId, invoiceId) => `/companies/${companyId}/invoices/${invoiceId}`
export const new_company_invoice_path = (companyId) => `/companies/${companyId}/invoices/new`
export const edit_company_invoice_path = (companyId, invoiceId) => `/companies/${companyId}/invoices/${invoiceId}/edit`

export const company_purchases_path = (companyId) => `/companies/${companyId}/purchases`
export const create_company_purchases_path = (companyId) => `/companies/${companyId}/purchases`
export const new_company_purchase_path = (companyId) => `/companies/${companyId}/purchases/new`
export const company_purchase_path = (companyId, purchaseId) => `/companies/${companyId}/purchases/${purchaseId}`
export const edit_company_purchase_path = (companyId, purchaseId) => `/companies/${companyId}/purchases/${purchaseId}/edit`
export const advance_company_purchase_path = (companyId, purchaseId) => `/companies/${companyId}/purchases/${purchaseId}/advance`

export const company_workflows_path = (companyId) => `/companies/${companyId}/workflows`
export const create_company_workflows_path = (companyId) => `/companies/${companyId}/workflows`
export const new_company_workflow_path = (companyId) => `/companies/${companyId}/workflows/new`
export const company_workflow_path = (companyId, workflowId) => `/companies/${companyId}/workflows/${workflowId}`
export const edit_company_workflow_path = (companyId, workflowId) => `/companies/${companyId}/workflows/${workflowId}/edit`
export const company_stocks_path = (companyId) => `/companies/${companyId}/stocks`
export const company_stock_transfers_path = (companyId) => `/companies/${companyId}/stock_transfers`
export const company_stock_imports_path = (companyId) => `/companies/${companyId}/stock_imports`
export const company_stock_exports_path = (companyId) => `/companies/${companyId}/stock_exports`
export const create_company_stock_imports_path = (companyId) => `/companies/${companyId}/stock_imports`
export const new_company_stock_import_path = (companyId) => `/companies/${companyId}/stock_imports/new`
export const company_stock_import_path = (companyId, id) => `/companies/${companyId}/stock_imports/${id}`
export const create_company_stock_exports_path = (companyId) => `/companies/${companyId}/stock_exports`
export const new_company_stock_export_path = (companyId) => `/companies/${companyId}/stock_exports/new`
export const company_stock_export_path = (companyId, id) => `/companies/${companyId}/stock_exports/${id}`
export const company_stock_adjustments_path = (companyId) => `/companies/${companyId}/stock_adjustments`
export const create_company_stock_adjustments_path = (companyId) => `/companies/${companyId}/stock_adjustments`
export const new_company_stock_adjustment_path = (companyId) => `/companies/${companyId}/stock_adjustments/new`
export const company_stock_adjustment_path = (companyId, id) => `/companies/${companyId}/stock_adjustments/${id}`
export const create_company_stock_transfers_path = (companyId) => `/companies/${companyId}/stock_transfers`
export const new_company_stock_transfer_path = (companyId) => `/companies/${companyId}/stock_transfers/new`
export const company_stock_transfer_path = (companyId, id) => `/companies/${companyId}/stock_transfers/${id}`
export const edit_company_stock_transfer_path = (companyId, id) => `/companies/${companyId}/stock_transfers/${id}/edit`
export const initiate_company_stock_transfer_path = (companyId, id) => `/companies/${companyId}/stock_transfers/${id}/initiate`
export const receive_company_stock_transfer_path = (companyId, id) => `/companies/${companyId}/stock_transfers/${id}/receive`
export const cancel_company_stock_transfer_path = (companyId, id) => `/companies/${companyId}/stock_transfers/${id}/cancel`
export const company_stock_pendings_path = (companyId) => `/companies/${companyId}/stock_pendings`
export const create_company_stock_pendings_path = (companyId) => `/companies/${companyId}/stock_pendings`
export const new_company_stock_pending_path = (companyId) => `/companies/${companyId}/stock_pendings/new`
export const company_stock_pending_path = (companyId, id) => `/companies/${companyId}/stock_pendings/${id}`
export const edit_company_stock_pending_path = (companyId, id) => `/companies/${companyId}/stock_pendings/${id}/edit`
export const release_company_stock_pending_path = (companyId, id) => `/companies/${companyId}/stock_pendings/${id}/release`
export const cancel_company_stock_pending_path = (companyId, id) => `/companies/${companyId}/stock_pendings/${id}/cancel`

export const company_employee_profiles_path = (companyId) => `/companies/${companyId}/employee_profiles`
export const create_company_employee_profiles_path = (companyId) => `/companies/${companyId}/employee_profiles`
export const new_company_employee_profile_path = (companyId) => `/companies/${companyId}/employee_profiles/new`
export const company_employee_profile_path = (companyId, id) => `/companies/${companyId}/employee_profiles/${id}`
export const edit_company_employee_profile_path = (companyId, id) => `/companies/${companyId}/employee_profiles/${id}/edit`
export const company_employee_subprofiles_path = (companyId) => `/companies/${companyId}/employee_subprofiles`
export const create_company_employee_subprofiles_path = (companyId) => `/companies/${companyId}/employee_subprofiles`
export const new_company_employee_subprofile_path = (companyId) => `/companies/${companyId}/employee_subprofiles/new`
export const company_employee_subprofile_path = (companyId, id) => `/companies/${companyId}/employee_subprofiles/${id}`
export const edit_company_employee_subprofile_path = (companyId, id) => `/companies/${companyId}/employee_subprofiles/${id}/edit`
export const company_customer_profiles_path = (companyId) => `/companies/${companyId}/customer_profiles`
export const create_company_customer_profiles_path = (companyId) => `/companies/${companyId}/customer_profiles`
export const new_company_customer_profile_path = (companyId) => `/companies/${companyId}/customer_profiles/new`
export const company_customer_profile_path = (companyId, id) => `/companies/${companyId}/customer_profiles/${id}`
export const edit_company_customer_profile_path = (companyId, id) => `/companies/${companyId}/customer_profiles/${id}/edit`
export const company_customer_subprofiles_path = (companyId) => `/companies/${companyId}/customer_subprofiles`
export const create_company_customer_subprofiles_path = (companyId) => `/companies/${companyId}/customer_subprofiles`
export const new_company_customer_subprofile_path = (companyId) => `/companies/${companyId}/customer_subprofiles/new`
export const company_customer_subprofile_path = (companyId, id) => `/companies/${companyId}/customer_subprofiles/${id}`
export const edit_company_customer_subprofile_path = (companyId, id) => `/companies/${companyId}/customer_subprofiles/${id}/edit`

export const company_analytics_path = (companyId) => `/companies/${companyId}/analytics`

export const company_kpi_configs_path = (companyId) => `/companies/${companyId}/kpi_configs`
export const create_company_kpi_configs_path = (companyId) => `/companies/${companyId}/kpi_configs`
export const company_kpi_config_path = (companyId, id) => `/companies/${companyId}/kpi_configs/${id}`
export const company_performance_index_path = (companyId) => `/companies/${companyId}/performance`
export const company_performance_path = (companyId, employeeId) => `/companies/${companyId}/performance/${employeeId}`
export const company_tax_path = (companyId) => `/companies/${companyId}/tax`
export const company_tax_summary_path = (companyId) => `/companies/${companyId}/tax/summary`
export const company_tax_invoices_path = (companyId) => `/companies/${companyId}/tax/invoices`
export const company_tax_purchases_path = (companyId) => `/companies/${companyId}/tax/purchases`
export const company_tax_stock_exports_path = (companyId) => `/companies/${companyId}/tax/stock_exports`
export const company_tax_config_path = (companyId) => `/companies/${companyId}/tax_config`

export const company_payroll_path = (companyId) => `/companies/${companyId}/payroll`
export const company_payroll_summary_path = (companyId) => `/companies/${companyId}/payroll/summary`
export const company_payroll_payrolls_path = (companyId) => `/companies/${companyId}/payroll/payrolls`
export const company_payroll_payroll_path = (companyId, id) => `/companies/${companyId}/payroll/payrolls/${id}`
export const company_payroll_generate_path = (companyId) => `/companies/${companyId}/payroll/generate`
export const company_payroll_config_path = (companyId) => `/companies/${companyId}/payroll_config`
export const company_payroll_my_path = (companyId, month = null) => month ? `/companies/${companyId}/payroll/my?month=${month}` : `/companies/${companyId}/payroll/my`
