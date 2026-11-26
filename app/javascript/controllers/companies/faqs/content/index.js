import gettingStarted from "controllers/companies/faqs/content/01_getting_started"
import dashboardAnalytics from "controllers/companies/faqs/content/02_dashboard_analytics"
import catalogCustomers from "controllers/companies/faqs/content/03_catalog_customers"
import posCheckout from "controllers/companies/faqs/content/04_pos_checkout"
import ordersInvoicesRefunds from "controllers/companies/faqs/content/05_orders_invoices_refunds"
import discountsTax from "controllers/companies/faqs/content/06_discounts_tax"
import inventoryStock from "controllers/companies/faqs/content/07_inventory_stock"
import purchasesWorkflowsTickets from "controllers/companies/faqs/content/08_purchases_workflows_tickets"
import operationsAccess from "controllers/companies/faqs/content/09_operations_access"
import bookingFacilities from "controllers/companies/faqs/content/10_booking_facilities"
import reception from "controllers/companies/faqs/content/11_reception"
import storeManager from "controllers/companies/faqs/content/12_store_manager"
import hrAttendance from "controllers/companies/faqs/content/13_hr_attendance"
import payrollPerformance from "controllers/companies/faqs/content/14_payroll_performance"
import exams from "controllers/companies/faqs/content/15_exams"
import notificationsDocumentsStorage from "controllers/companies/faqs/content/16_notifications_documents_storage"
import importsExports from "controllers/companies/faqs/content/17_imports_exports"
import customizationPaymentMethods from "controllers/companies/faqs/content/18_customization_payment_methods"
import creditsBillingUsage from "controllers/companies/faqs/content/19_credits_billing_usage"
import supportSecurityMobile from "controllers/companies/faqs/content/20_support_security_mobile"
import { buildFaqDictionary } from "controllers/companies/faqs/content/dictionary"

export const FAQ_GROUPS = [
  gettingStarted,
  dashboardAnalytics,
  catalogCustomers,
  posCheckout,
  ordersInvoicesRefunds,
  discountsTax,
  inventoryStock,
  purchasesWorkflowsTickets,
  operationsAccess,
  bookingFacilities,
  reception,
  storeManager,
  hrAttendance,
  payrollPerformance,
  exams,
  notificationsDocumentsStorage,
  importsExports,
  customizationPaymentMethods,
  creditsBillingUsage,
  supportSecurityMobile
]

export const FAQ_DICTIONARY = buildFaqDictionary(FAQ_GROUPS)
