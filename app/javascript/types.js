/**
 * @global
 * @typedef {Object} User
 * @property {string} id - The unique identifier for the user (UUID).
 * @property {string} email
 * @property {boolean} verified
 * @property {SystemRole} system_role
 * @property {string|null} username
 * @property {string|null} first_name
 * @property {string|null} last_name
 * @property {string|null} avatar
 * @property {string|null} phone_number
 * @property {CountryCode|null} country_code
 * @property {string|null} parent_user_id
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Address
 * @property {string} id - The unique identifier for the address (UUID).
 * @property {string} line_1
 * @property {string|null} line_2
 * @property {string} city
 * @property {string|null} state_or_province
 * @property {string|null} postal_code
 * @property {CountryCode|null} country_code
 * @property {string} fingerprint - A unique hash of the address components.
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @typedef {Object} PolymorphicAppointment
 * @property {string|null} appoint_from_type
 * @property {string|null} appoint_from_id
 * @property {string} appoint_to_type
 * @property {string} appoint_to_id
 * @property {string|null} appoint_for_type
 * @property {string|null} appoint_for_id
 * @property {string|null} appoint_by_type
 * @property {string|null} appoint_by_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} value
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, address_id: string }} AddressAppointment
 */

/**
 * @global
 * @typedef {Object} Answer
 * @property {string} id - UUID
 * @property {string} question_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, article_id: string }} ArticleAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, article_group_id: string }} ArticleGroupAppointment
 */

/**
 * @global
 * @typedef {Object} ArticleGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} title
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Article
 * @property {string} id - UUID
 * @property {string} article_group_id
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} title
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Booking
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} appoint_from_type
 * @property {string|null} appoint_from_id
 * @property {string} appoint_to_type
 * @property {string} appoint_to_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Brand
 * @property {string} id - UUID
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, cart_id: string }} CartAppointment
 */

/**
 * @global
 * @typedef {Object} CartGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Cart
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string} cart_group_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} sku
 * @property {string|null} barcode
 * @property {string|null} upc
 * @property {string|null} ean
 * @property {string|null} manufacturer_code
 * @property {string|null} serial_number
 * @property {string|null} batch_number
 * @property {string|null} expiration_date
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Category
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Company
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} parent_company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {number|null} ownership_type
 * @property {BusinessType|null} business_type
 * @property {Currency|null} currency
 * @property {string|null} registration_number
 * @property {string|null} vat_id
 * @property {string|null} tax_id
 * @property {number|null} timezone
 * @property {string|null} address_line_1
 * @property {string|null} city
 * @property {string|null} postal_code
 * @property {string|null} country
 * @property {string|null} email
 * @property {string|null} phone_number
 * @property {string|null} website
 * @property {number|null} employee_count
 * @property {number|null} fiscal_year_end_month
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Subscription
 * @property {string} id - The unique identifier for the subscription (UUID).
 * @property {string|null} subscription_group_id
 * @property {string} price_id
 * @property {string} period_id
 * @property {string} seller_id
 * @property {string} seller_type - e.g., 'System', 'Company'
 * @property {string} buyer_id
 * @property {string} buyer_type - e.g., 'User', 'Company'
 * @property {string|null} resource_id
 * @property {string|null} resource_type
 * @property {string|null} processer_id
 * @property {string|null} processer_type
 * @property {string|null} name
 * @property {string|null} description
 * @property {CountryCode} country_code
 * @property {SubscriptionPlanName} plan_name
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {boolean|null} auto_renew
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} SubscriptionGroup
 * @property {string} id - The unique identifier for the subscription group (UUID).
 * @property {string|null} subscription_group_id
 * @property {string} price_id
 * @property {string} period_id
 * @property {string} seller_type
 * @property {string} seller_id
 * @property {string} buyer_type
 * @property {string} buyer_id
 * @property {string|null} processed_by_type
 * @property {string|null} processed_by_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {CountryCode} country_code
 * @property {SubscriptionPlanName} plan_name
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {boolean|null} auto_renew
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, customer_id: string }} CustomerAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, customer_group_id: string }} CustomerGroupAppointment
 */

/**
 * @global
 * @typedef {Object} CustomerGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, document_id: string }} DocumentAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, document_group_id: string }} DocumentGroupAppointment
 */

/**
 * @global
 * @typedef {Object} DocumentGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} title
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Document
 * @property {string} id - UUID
 * @property {string} document_group_id
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} title
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, employee_id: string }} EmployeeAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, employee_group_id: string }} EmployeeGroupAppointment
 */

/**
 * @global
 * @typedef {Object} EmployeeGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {EmployeeGroup} Department
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, event_id: string }} EventAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, event_group_id: string }} EventGroupAppointment
 */

/**
 * @global
 * @typedef {Object} EventGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Event
 * @property {string} id - UUID
 * @property {string} event_group_id
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, exam_id: string }} ExamAppointment
 */

/**
 * @global
 * @typedef {Object} ExamGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Exam
 * @property {string} id - UUID
 * @property {string} exam_group_id
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Facility
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, facility_id: string }} FacilityAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, facility_group_id: string }} FacilityGroupAppointment
 */

/**
 * @global
 * @typedef {Object} FacilityGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Inventory
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, inventory_item_id: string }} InventoryItemAppointment
 */

/**
 * @global
 * @typedef {Object} InventoryItem
 * @property {string} id - UUID
 * @property {string} inventory_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} sku
 * @property {string|null} barcode
 * @property {string|null} upc
 * @property {string|null} ean
 * @property {string|null} manufacturer_code
 * @property {string|null} serial_number
 * @property {string|null} batch_number
 * @property {string|null} expiration_date
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, inventory_transaction_id: string }} InventoryTransactionAppointment
 */

/**
 * @global
 * @typedef {Object} InventoryTransaction
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} appoint_from_type
 * @property {string|null} appoint_from_id
 * @property {string} appoint_to_type
 * @property {string} appoint_to_id
 * @property {string|null} appoint_for_type
 * @property {string|null} appoint_for_id
 * @property {string|null} appoint_by_type
 * @property {string|null} appoint_by_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Invoice
 * @property {string} id - UUID
 * @property {string} order_id
 * @property {string|null} category_id
 * @property {string|null} name
_ * @property {string|null} description
 * @property {string|null} code
 * @property {Currency|null} currency
 * @property {number|null} duration
 * @property {string|null} number
 * @property {number|null} total_price
 * @property {string|null} due_date
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, notification_id: string }} NotificationAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, notification_group_id: string }} NotificationGroupAppointment
 */

/**
 * @global
 * @typedef {Object} NotificationGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Notification
 * @property {string} id - UUID
 * @property {string} notification_group_id
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, order_id: string, unit_price: number, quantity: number, total_price: number }} OrderAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, order_group_id: string, unit_price: number, quantity: number, total_price: number }} OrderGroupAppointment
 */

/**
 * @global
 * @typedef {Object} OrderGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string} customer_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {Currency|null} currency
 * @property {number|null} duration
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Order
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string} customer_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} sku
 * @property {string|null} barcode
 * @property {string|null} upc
 * @property {string|null} ean
 * @property {string|null} manufacturer_code
 * @property {string|null} serial_number
 * @property {string|null} batch_number
 * @property {string|null} expiration_date
 * @property {Currency|null} currency
 * @property {number|null} duration
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} PaymentMethodAppointment
 * @property {string} id - UUID
 * @property {string} payment_method_id
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} PaymentMethod
 * @property {string} id - UUID
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {Currency|null} currency
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Payment
 * @property {string} id - UUID
 * @property {string} invoice_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {Currency|null} currency
 * @property {number|null} duration
 * @property {number|null} exchange_rate
 * @property {number|null} amount
 * @property {string|null} payment_method
 * @property {string|null} gateway_details
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, period_id: string }} PeriodAppointment
 */

/**
 * @global
 * @typedef {Object} Price
 * @property {string} id - The unique identifier for the price (UUID).
 * @property {number} amount - The monetary amount (decimal).
 * @property {Currency} currency
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, price_id: string }} PriceAppointment
 */

/**
 * @global
 * @typedef {Object} Period
 * @property {string} id - The unique identifier for the period (UUID).
 * @property {string} start_at
 * @property {string|null} end_at
 * @property {number} time_zone
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Policy
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} resource
 * @property {string|null} action
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, policy_id: string }} PolicyAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, product_id: string }} ProductAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, product_group_id: string }} ProductGroupAppointment
 */

/**
 * @global
 * @typedef {Object} ProductGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Product
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} brand_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {number|null} price
 * @property {Currency|null} currency
 * @property {string|null} code
 * @property {string|null} sku
 * @property {string|null} barcode
 * @property {string|null} upc
 * @property {string|null} ean
 * @property {string|null} manufacturer_code
 * @property {string|null} serial_number
 * @property {string|null} batch_number
 * @property {string|null} expiration_date
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, project_id: string }} ProjectAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, project_group_id: string }} ProjectGroupAppointment
 */

/**
 * @global
 * @typedef {Object} ProjectGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Project
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string} project_group_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} PurchaseItem
 * @property {string} id - UUID
 * @property {string} purchase_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string|null} sku
 * @property {string|null} barcode
 * @property {string|null} upc
 * @property {string|null} ean
 * @property {string|null} manufacturer_code
 * @property {string|null} serial_number
 * @property {string|null} batch_number
 * @property {string|null} expiration_date
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Purchase
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Question
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, role_id: string }} RoleAppointment
 */

/**
 * @global
 * @typedef {Object} Role
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {number|null} model_type
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, service_id: string, duration: number, start_at: string }} ServiceAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, service_group_id: string, duration: number, start_at: string }} ServiceGroupAppointment
 */

/**
 * @global
 * @typedef {Object} ServiceGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {number|null} duration
 * @property {string|null} start_at
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Service
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {number|null} duration
 * @property {string|null} start_at
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, setting_id: string }} SettingAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, setting_group_id: string }} SettingGroupAppointment
 */

/**
 * @global
 * @typedef {Object} SettingGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Setting
 * @property {string} id - UUID
 * @property {string} setting_group_id
 * @property {string} company_group_id
 * @property {string} company_id
 * @property {string|null} category_id
 * @property {Object|null} content - JSON content
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Statistic
 * @property {string} id - UUID
 * @property {string} owner_type
 * @property {string} owner_id
 * @property {Object|null} data - JSON content
 * @property {string|null} recorded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, tag_id: string }} TagAppointment
 */

/**
 * @global
 * @typedef {Object} Tag
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, task_id: string }} TaskAppointment
 */

/**
 * @global
 * @typedef {PolymorphicAppointment & { id: string, task_group_id: string }} TaskGroupAppointment
 */

/**
 * @global
 * @typedef {Object} TaskGroup
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Task
 * @property {string} id - UUID
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string} task_group_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {Currency|null} currency
 * @property {LifecycleStatus|null} lifecycle_status
_ * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} System
 * @property {string} id - The unique identifier for the system record (UUID).
 * @property {string} name
 * @property {string} code
 * @property {number} balance_cents
 * @property {Currency|null} currency
 * @property {CountryCode|null} country_code
 * @property {boolean} active
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Session
 * @property {string} id - The unique identifier for the session (UUID).
 * @property {string} user_id
 * @property {string|null} user_agent
 * @property {string|null} ip_address
 * @property {string|null} single_access_token
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} SignInToken
 * @property {string} id - The unique identifier for the token (UUID).
 * @property {string} user_id
 */

/**
 * @global
 * @typedef {Object} CompanyGroup
 * @property {string} id - The unique identifier for the company group (UUID).
 * @property {string} user_id - The ID of the owning user.
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {number|null} ownership_type
 * @property {BusinessType|null} business_type
 * @property {Currency|null} currency
 * @property {string|null} registration_number
 * @property {string|null} vat_id
 * @property {string|null} tax_id
 * @property {number|null} timezone
 * @property {string|null} address_line_1
 * @property {string|null} city
 * @property {string|null} postal_code
 * @property {string|null} country
 * @property {string|null} email
 * @property {string|null} phone_number
 * @property {string|null} website
 * @property {number|null} employee_count
 * @property {number|null} fiscal_year_end_month
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Employee
 * @property {string} id - The unique identifier for the employee record (UUID).
 * @property {string} user_id - The ID of the associated user.
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {Object} Customer
 * @property {string} id - The unique identifier for the customer record (UUID).
 * @property {string|null} user_id - The ID of the associated user.
 * @property {string} company_group_id
 * @property {string|null} company_id
 * @property {string|null} category_id
 * @property {string|null} name
 * @property {string|null} description
 * @property {string|null} code
 * @property {LifecycleStatus|null} lifecycle_status
 * @property {WorkflowStatus|null} workflow_status
 * @property {BusinessType|null} business_type
 * @property {string|null} discarded_at
 * @property {string} created_at
 * @property {string} updated_at
 */

/**
 * @global
 * @typedef {'super_admin'|'admin'|'company_owner'|'company_employee'|'company_customer'} SystemRole
 */

/**
 * @global
 * @typedef {'us'|'vn'} CountryCode
 */

/**
 * @global
 * @typedef {'active'|'inactive'|'archived'|'suspended'|'deleted'} LifecycleStatus
 */

/**
 * @global
 * @typedef {'draft'|'pending'|'confirmed'|'in_progress'|'completed'|'paid'|'cancelled'|'refunded'|'failed'} WorkflowStatus
 */

/**
 * @global
 * @typedef {'system_to_business'|'business_to_business'|'business_to_customer'|number} BusinessType
 */

/**
 * @global
 * @typedef {string} SubscriptionPlanName - The name of the subscription plan (e.g., 'free', 'pro', 'enterprise').
 */

/**
 * @global
 * @typedef {'usd'|'vnd'|number} Currency
 */
