# Skycom Platform Roadmap: 100 Steps to a Waston-Style Empire

This roadmap outlines the journey from initial sign-up to managing a nationwide multi-tenant retail and clinic business using the Skycom platform.

---

## Phase 1: Onboarding & Identity (1-10)
1.  **User Sign-up:** Register as a system administrator.
2.  **Email Verification:** Secure the account via SMTP verification.
3.  **User Sign-in:** Access the unified Skycom dashboard.
4.  **Create Company:** Initialize the "Hasaki Beauty & Clinic" entity in the `companies` table.
5.  **Company Branding:** Upload logos and set primary colors via the `metadata` JSONB.
6.  **Multi-Tenancy Lockdown:** Ensure all subsequent records are scoped to `company_id`.
7.  **Legal Registration:** Input `tax_id` and `registration_number` for Vietnamese compliance.
8.  **Currency Initialization:** Set the primary currency to VND (using precision 15, scale 2).
9.  **Timezone Configuration:** Calibrate system events to GMT+7.
10. **Global Search Index:** Trigger the initial search index mapping for the new company.

## Phase 2: Structural Hierarchy (11-20)
11. **Core Categories:** Create high-level categories for "Retail" and "Clinic Services."
12. **Define Branches:** Create the first physical location (e.g., "District 1 Flagship").
13. **Address Appointment:** Use `AddressAppointment` to link the Branch to a physical location.
14. **Geographic Mapping:** Populate Ward/District/City for the branch address.
15. **Warehouse Creation:** Initialize a `Warehouse` linked to the District 1 Branch.
16. **Department Setup:** Create "Sales," "Medical," and "Logistics" departments.
17. **Staff Roles:** Initialize `Role` records for "Doctor," "Consultant," and "Warehouse Staff."
18. **Branch Operating Hours:** Store Mon-Sun schedule in the Branch `opening_hours` JSONB.
19. **Brand Onboarding:** Add partner brands (e.g., La Roche-Posay, Vichy) to the `brands` table.
20. **Brand Appointment:** Link brands to the specific company resource list.

## Phase 3: Product & Service Catalog (21-30)
21. **Physical Product Entry:** Add retail items (e.g., Sunscreen) to the `products` table.
22. **Product Physical Specs:** Define `material`, `color`, and `size` for retail tracking.
23. **Clinic Service Entry:** Add "Pico Laser Treatment" as a `business_type: :service` product.
24. **Price Appointment:** Assign a VND price to the product for the Saigon branch.
25. **Multi-Tier Pricing:** Create separate `PriceAppointments` for "Member" vs "Non-Member."
26. **Barcode Assignment:** Assign EAN/UPC/SKU values for scanning.
27. **Batch Management:** Enable `batch_number` tracking for expiry-sensitive products.
28. **Generic Property Slots:** Use `property_s1` for "Ingredients" and `property_s2` for "Usage."
29. **UOM Definition:** Set Units of Measure (e.g., "Bottle," "Session," "Pack").
30. **Asset Attachment:** Upload product images to `ActiveStorage`.

## Phase 4: Inventory & Warehouse Logistics (31-40)
31. **Stock Initialization:** Create `Stock` records for the Branch Warehouse.
32. **Stock Mirroring:** Ensure `Stock` rows carry physical traits (color/size) for picking.
33. **Reorder Thresholds:** Set `reorder_threshold` to trigger auto-stock alerts.
34. **Stock Import:** Record the first bulk shipment from a supplier via `StockImport`.
35. **Bin Locations:** Map stock to specific shelves using `metadata`.
36. **Inter-Branch Transfer:** Move inventory between warehouses using `StockTransfer`.
37. **Stock Reservation:** Logic to lock stock when an item is added to a digital cart.
38. **Write-offs:** Process `StockExport` for damaged or expired testers.
39. **Supplier Management:** Add vendors to the `customers` table with a "Supplier" tag.
40. **Purchase Orders:** Generate POs when stock levels hit the threshold.

## Phase 5: HR & Staff Operations (41-50)
41. **Employee Profile:** Create employee records for staff and doctors.
42. **Role Assignment:** Link users to "Doctor" or "Manager" roles.
43. **Shift Definition:** Create shifts in the `shifts` table (e.g., "Morning Shift 8AM-2PM").
44. **Attendance System:** Enable `attendance_logs` for staff clock-in/out.
45. **Geo-Fencing:** Use `location_lat/lng` in attendance to ensure staff are at the branch.
46. **Payroll Configuration:** Define base salary components in employee `metadata`.
47. **Commission Engine:** Set rules for "Service Commission" (e.g., 5% per Laser session).
48. **Leave Management:** Implement workflows for holiday/sick leave requests.
49. **Department Linking:** Assign employees to their specific Branch/Department.
50. **Staff Directory:** Generate a searchable internal directory for branch coordination.

## Phase 6: Clinic & Booking Engine (51-60)
51. **Resource Definition:** Add treatment rooms and machines as "Resource" products.
52. **Capacity Setup:** Set `capacity_limit` for group classes or multi-person rooms.
53. **Time Slot Generation:** Create 30/60 minute availability windows.
54. **Customer Booking:** Logic for a customer to book a clinic appointment via the UI.
55. **Required Role Check:** Ensure "Laser" services are only booked with "Doctor" roles.
56. **Booking Appointment:** Link Customer, Staff, and Branch in a `task_appointment`.
57. **Automated Reminders:** Send Zalo/Email notifications 2 hours before the service.
58. **Check-in Workflow:** Mark customer as "Arrived" in the branch attendance log.
59. **Treatment Notes:** Store medical/aesthetic notes in the `metadata` of the task.
60. **Post-Service Follow-up:** Automatically schedule a "Review Session" for 2 weeks later.

## Phase 7: CRM & Loyalty (61-70)
61. **Customer Registration:** Capture name, phone, and birthday in the `customers` table.
62. **Customer Segmentation:** Group users into "Retail Shopper," "Clinic Patient," or "VIP."
63. **Tag Appointment:** Assign skin-type tags (e.g., "Dry Skin") via `TagAppointment`.
64. **Loyalty Point Rule:** Define the "Spend to Point" ratio (e.g., 10k VND = 1 Point).
65. **Reward Catalog:** Link points to "Free Product" or "Service Discount" appointments.
66. **Address Book:** Allow customers to store multiple shipping addresses.
67. **Wishlist Logic:** Use `cart_appointments` to track "Saved Items."
68. **Interaction Logs:** Record every call or complaint in the customer `metadata`.
69. **Marketing Opt-in:** Track GDPR/Decree 13 compliance for SMS marketing.
70. **Referral Tracking:** Link new customers to the friend who referred them.

## Phase 8: Sales & Financials (71-80)
71. **Cart Initialization:** Setup a `cart` for the current user session.
72. **Cart Appointments:** Link specific products and variants to the active cart.
73. **Discount Engine:** Apply "Buy 1 Get 1" or percentage-based promos.
74. **Voucher Validation:** Validate unique codes against the `promotion` tables.
75. **Tax Calculation:** Apply 8% or 10% VAT based on the product category.
76. **Shipping Integration:** Calculate fees via GHN/GHTK API based on `AddressAppointment`.
77. **Invoice Generation:** Create the `invoice` record with a unique `code`.
78. **Payment Gateway:** Integrate MoMo, ZaloPay, or VNPay.
79. **Transaction Completion:** Update status to "Paid" and generate a receipt.
80. **Refund Workflow:** Logic for partial or full refunds back to the original payment source.

## Phase 9: Fulfillment & Last Mile (81-90)
81. **Order Picking:** Notify warehouse staff of a new "Paid" order.
82. **Packing Slip:** Generate a PDF slip containing the SKU and physical specs (color/size).
83. **Shipping Label:** Print labels with the `AddressAppointment` details.
84. **Courier Handover:** Mark order as "Shipped" and record the tracking number.
85. **Transit Tracking:** Sync real-time location data from the logistics partner.
86. **Delivery Confirmation:** Mark order as "Completed" upon customer signature.
87. **In-Store Pickup:** Logic for "Click and Collect" at a specific branch.
88. **Return Request (RMA):** Customer initiates a return via the mobile app.
89. **Quality Inspection:** Process returned stock before it enters the "Available" count.
90. **Stock Reconciliation:** Auto-update inventory levels across all branches post-sale.

## Phase 10: Intelligence & Scaling (91-100)
91. **Financial Reporting:** Generate Daily/Monthly Revenue reports per branch.
92. **Inventory Turnover:** Identify "Dead Stock" using `Stock` movement history.
93. **Staff Performance:** Report on service ratings and booking volume per doctor.
94. **Predictive Reordering:** Auto-generate POs based on the last 30 days of sales.
95. **Customer Lifetime Value (CLV):** Calculate total spend per customer record.
96. **Knowledge Base:** Use `articles` to provide "Skincare Routines" to users.
97. **Multi-Tenant Expansion:** Owner creates a second sub-company for a different brand.
98. **System Audit Logs:** Track who changed a product price or stock count.
99. **Database Maintenance:** Vacuum SQLite/Postgres and rotate logs on the Ubuntu server.
100. **Go-Live:** Flip the `workflow_status` from "Draft" to "Active" for the entire company.