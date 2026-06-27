class Seed::RetailService
  EMPLOYEE_COUNTS = {
    Manager: 1,
    Cashier: 10,
    Seller: 10,
    Security: 1,
    Admin: 1,
    Doctor: 3,      # Advises & Performs clinical services
    Therapist: 8,   # Performs skin treatments/spa
    Consultant: 5  # Sells products & advises services

  }.freeze

  CUSTOMER_COUNTS = { Customer: 50 }.freeze
  RETAIL_ROLES = (EMPLOYEE_COUNTS.keys).freeze
  COMPANY_GROUP_BUSINESS_TYPE = :retail

  CLINIC_FACILITIES = [ "Clinic Room A", "Clinic Room B", "Laser Machine 01", "HIFU Machine" ].freeze

  METADATA_CATEGORIES = {
    products: {
      "Cosmetics" => {
        properties: {
          property_string_1: "Skin Type Suitability",
          property_string_2: "Key Ingredients",
          property_string_3: "Formulation (e.g., Liquid, Powder)",
          property_string_4: "Scent Family Notes",
          property_integer_1: "Volume (ml)",
          property_integer_2: "Shelf Life (Months)",
          property_integer_3: "Ph Level Balance Target",
          property_boolean_1: "Organic Certified",
          property_boolean_2: "Requires Refrigeration",
          property_decimal_1: "Cruelty Free Certification Score"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1 property_integer_2]
      },
      "Perfumes" => {
        properties: {
          property_string_1: "Scent Profile / Notes",
          property_string_2: "Concentration (EDP / EDT)",
          property_string_3: "Olfactory Category Family",
          property_string_4: "Recommended Season / Wear Time",
          property_integer_1: "Volume (ml)",
          property_integer_2: "Average Scent Longevity (Hours)",
          property_integer_3: "Sillage Intensity Rating Scale",
          property_boolean_1: "Includes Tester Unit",
          property_boolean_2: "Magnetic Cap Equipped",
          property_decimal_1: "Essential Oil Concentration Percentage"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1 property_integer_2]
      },
      "Beauty Tools" => {
        properties: {
          property_string_1: "Material Composition",
          property_string_2: "Power Source Type",
          property_string_3: "Ergonomic Handle Type Description",
          property_string_4: "Included Attachments Pack List",
          property_integer_1: "Warranty Period (Months)",
          property_integer_2: "Motor RPM / Vibration Frequency",
          property_integer_3: "Charging Duration Time (Minutes)",
          property_boolean_1: "Waterproof Rating Enabled",
          property_boolean_2: "Smart Auto-Shutoff Sensor Included",
          property_decimal_1: "Device Voltage Rating Compatibility"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1 property_integer_2]
      },
      "Makeup" => {
        properties: {
          property_string_1: "Shade / Color Code",
          property_string_2: "Finish (Matte / Dewy)",
          property_string_3: "Coverage Density (Sheer/Medium/Full)",
          property_string_4: "Application Method Recommendation",
          property_integer_1: "Net Weight (g)",
          property_integer_2: "Sun Protection Factor (SPF Value)",
          property_integer_3: "Pigment Purity Grading Index",
          property_boolean_1: "Vegan Formulation",
          property_boolean_2: "Water-Resistant Coating Flag",
          property_decimal_1: "Heavy Metal Safety Screening Score"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1 property_integer_2]
      },
      "Jewelry" => {
        properties: {
          property_string_1: "Material (Gold / Silver)",
          property_string_2: "Gemstone Type",
          property_string_3: "Clasp / Fastener Mechanism Style",
          property_string_4: "Hallmark Certificate Authority Code",
          property_integer_1: "Ring / Chain Size Scale Value",
          property_integer_2: "Total Diamond Facet Counts Set",
          property_decimal_1: "Weight (Grams)",
          property_decimal_2: "Purity Carat",
          property_boolean_1: "Certified Conflict-Free Origin",
          property_boolean_2: "Rhodium Plated Anti-Tarnish Film"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_decimal_1 property_decimal_2 property_boolean_1]
      },
      "Accessories" => {
        properties: {
          property_string_1: "Size / Dimensions",
          property_string_2: "Color Palette",
          property_string_3: "Material Type",
          property_string_4: "Hardware Accent Tone Trim",
          property_integer_1: "Number of Internal Pockets/Slots",
          property_integer_2: "Max Strap Extension Length (cm)",
          property_boolean_1: "Dust Bag Envelope Included",
          property_boolean_2: "Scratch Resistant Protective Film",
          property_decimal_1: "Empty Weight Overhead Scale (kg)",
          property_decimal_2: "Max Dynamic Load Threshold Capacity"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_string_3 property_boolean_1]
      }
    },

    employees: {
      "Management" => {
        properties: {
          property_string_1: "Corporate Level",
          property_string_2: "Primary Executive Committee Seat",
          property_string_3: "Dedicated Emergency Backup Proxy Name",
          property_string_4: "Global Cost Center Allocation ID",
          property_decimal_1: "KPI Target Bonus %",
          property_decimal_2: "Authorized Expense Signoff Cap Limit",
          property_boolean_1: "Signing Authority Status",
          property_boolean_2: "Stock Option Program Vesting Enrolled",
          property_integer_1: "Active Headcount Direct Reports Count",
          property_datetime_1: "Last Board Review Alignment Date"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1 property_boolean_1 property_decimal_2]
      },
      "Sales Specialist" => {
        properties: {
          property_string_1: "Assigned Product Line",
          property_string_2: "Target Customer Tier Segment Portfolio",
          property_string_3: "Secondary Language Proficiency Skill",
          property_string_4: "Top Performing Channel Focus Descriptor",
          property_decimal_1: "Commission Tier %",
          property_decimal_2: "Historical Client Conversion Success Rate",
          property_integer_1: "Monthly Sales Target Value",
          property_integer_2: "Minimum Cold Call Outbound Daily Quota",
          property_boolean_1: "Cross-Selling Specialist Certification Token",
          property_boolean_2: "Authorized to Issue Discretionary Discounts"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1 property_integer_1 property_decimal_2]
      },
      "Cashier" => {
        properties: {
          property_string_1: "POS Station Number",
          property_string_2: "Primary Register Interface Layout Code",
          property_string_3: "Backup Verification Supervisor Assigned",
          property_string_4: "Default Receipt Printer Port Allocation",
          property_integer_1: "Assigned Cash Drawer ID Code",
          property_integer_2: "Maximum Allowed Shift Discrepancy (VND)",
          property_boolean_1: "Vault Drop Authorization Access Flag",
          property_boolean_2: "High-Value Refund Overrides Clearance Allowed",
          property_decimal_1: "Average Checkout Processing Speed (Sec/Item)",
          property_datetime_1: "Last Cash Integrity Audit Execution Time"
        },
        visible_columns: %w[name email property_string_1 property_integer_1 property_boolean_1 property_integer_2]
      },
      "Technical Support" => {
        properties: {
          property_string_1: "Certifications",
          property_string_2: "Primary Tech Stack",
          property_string_3: "Hardware Diagnostics Specialization Focus",
          property_string_4: "Default Helpdesk Queue Routing Alias",
          property_integer_1: "Max Ticket Assignment Backlog Limit",
          property_integer_2: "Average Internal Resolution SLA Target (Min)",
          property_boolean_1: "Remote Infrastructure Access Token Enrolled",
          property_boolean_2: "On-Call Weekend Emergency Rotation Flag",
          property_decimal_1: "Historical Customer Satisfaction CSAT Rating",
          property_datetime_1: "Network Security Clearance Expiration Date"
        },
        visible_columns: %w[name email property_string_1 property_string_2 property_integer_2 property_decimal_1]
      },
      "Marketing" => {
        properties: {
          property_string_1: "Channel Focus (Digital/Social)",
          property_string_2: "Primary Creative Software License ID",
          property_string_3: "Attribution Modeling Methodology Scheme",
          property_string_4: "Assigned Brand Identity Guideline Sub-Tier",
          property_decimal_1: "Monthly Ad Budget Limit",
          property_decimal_2: "Target Return on Ad Spend (ROAS Index)",
          property_integer_1: "Active Lead Conversion Campaign Quota",
          property_integer_2: "Planned Marketing Event Calendars Managed",
          property_boolean_1: "External Agency Vendor Signoff Authority",
          property_boolean_2: "PR Crisis Response Communications Access"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1 property_decimal_2 property_integer_1]
      }
    },

    branches: {
      "Flagship Store" => {
        properties: {
          property_integer_1: "Maximum Occupancy Capacity",
          property_integer_2: "Number of POS Tills",
          property_integer_3: "Dedicated Customer Parking Spaces Set",
          property_integer_4: "VIP Lounge Dressing Rooms Mounted",
          property_boolean_1: "Has Tax-Free Counter",
          property_boolean_2: "Equipped with In-Store Smart Foot-Traffic HUD",
          property_decimal_1: "Total Frontage Window Display Linear Meters",
          property_decimal_2: "Target Daily Revenue Run-Rate Bottom Line",
          property_string_1: "Bespoke Experiential Zone Decor Style",
          property_string_2: "Local Retail Association License Registry Code"
        },
        visible_columns: %w[name property_integer_1 property_integer_2 property_boolean_1 property_decimal_1 property_string_1]
      },
      "Mall Kiosk" => {
        properties: {
          property_string_5: "Mall Unit Number",
          property_string_1: "Parent Mall Management Management Contact",
          property_string_2: "Anchor Store Proximity Zone Location Name",
          property_string_3: "Electricity Meter Shared Drop Serial ID",
          property_decimal_1: "Lease Square Footage",
          property_decimal_2: "Base Monthly Mall Maintenance Surcharge Rate",
          property_integer_1: "Required Security Shutter Lock Point Total",
          property_integer_2: "Max Core Storage Crate Backlog Volume",
          property_boolean_1: "Overnight Stock Replenishment Authorization",
          property_boolean_2: "Shared Mall Guest Wi-Fi Portal Beacon Hooked"
        },
        visible_columns: %w[name property_string_5 property_decimal_1 property_string_1 property_integer_1]
      },
      "Warehouse Distribution" => {
        properties: {
          property_integer_1: "Loading Bay Count",
          property_integer_2: "Forklift Unit Fleet Count Allocation",
          property_integer_3: "Maximum Racking Tier Height Level Layers",
          property_decimal_1: "Storage Capacity (Cubic Meters)",
          property_decimal_2: "Pallet Ingestion Throughput Rate Per Hour",
          property_boolean_1: "Cold Chain Storage Enabled",
          property_boolean_2: "Hazmat Fire Suppression Sprinkler Subsystems Active",
          property_string_1: "WMS Software Sync Interface Pipeline Format",
          property_string_2: "Customs Bonded Area Registration Bond Serial",
          property_datetime_1: "Structural Safety Integrity Inspection Pass Date"
        },
        visible_columns: %w[name property_integer_1 property_decimal_1 property_boolean_1 property_integer_2 property_string_1]
      },
      "Pop-up Shop" => {
        properties: {
          property_datetime_1: "Operation Start Date",
          property_datetime_2: "Operation End Date",
          property_datetime_3: "Permit Clearance Cutoff Deadline",
          property_string_1: "Temporary Asset Shell Vendor Provider Name",
          property_string_2: "Mobile POS Cellular Network Hardware Profile",
          property_string_3: "Decommissioning Waste Management Route Code",
          property_decimal_1: "Daily Capital Outlay Rental Prorated Factor",
          property_decimal_2: "Target Customer Ingestion Engagement Conversions",
          property_integer_1: "Total Days Active Runway Target lifespan",
          property_boolean_1: "Requires Local Event Marshal Presence Code"
        },
        visible_columns: %w[name property_datetime_1 property_datetime_2 property_string_1 property_decimal_1]
      }
    },

    departments: {
      "Operations" => {
        properties: {
          property_string_1: "Regional Scope",
          property_string_2: "SOP Revision Code",
          property_string_3: "Cross-Functional Project Sync Matrix Code",
          property_string_4: "Incident Escalation Commander Rotation Alias",
          property_integer_1: "Target Operational Efficiency Index Target",
          property_integer_2: "Total Regulated Compliance Audits Passed",
          property_boolean_1: "ISO 9001 Certification Standard Maintained",
          property_boolean_2: "Continuous Improvement Lean Kaizen Pipeline Active",
          property_decimal_1: "Overtime Staff Budget Overhead Buffer Factor",
          property_datetime_1: "Next Global Disaster Recovery Drill Window"
        },
        visible_columns: %w[name property_string_1 property_string_2 property_integer_1 property_boolean_1]
      },
      "Human Resources" => {
        properties: {
          property_string_1: "ATS Platform Integration",
          property_string_2: "Background Check Screening Vendor Handler",
          property_string_3: "Labor Union Collective Agreement Protocol Reference",
          property_string_4: "Primary EAP Mental Health Service Network Name",
          property_boolean_1: "Handles Payroll Directly",
          property_boolean_2: "Internal Training LMS Portal Engine Managed",
          property_integer_1: "Average Time-to-Hire Acquisition SLA Days",
          property_integer_2: "Target Employee Retention Goal Percentage",
          property_decimal_1: "Annual Training Budget Credit Allocation Per Head",
          property_datetime_1: "Next Benefits Packages Review Negotiation Window"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_integer_1 property_decimal_1]
      },
      "Finance" => {
        properties: {
          property_string_1: "Accounting Standard (IFRS/VAS)",
          property_string_2: "Primary Corporate Bank Account",
          property_string_3: "External Tax Auditor Firm Assignment Tag",
          property_string_4: "Corporate ERP Fiscal Reporting Channel Sync",
          property_boolean_1: "Foreign Exchange Currency Hedging Desk Enabled",
          property_boolean_2: "Automated Intercompany Reconciliation Active",
          property_integer_1: "Fiscal Month-End Close Sequence Target Days",
          property_integer_2: "Active Bank Line of Credit Accounts Tracking",
          property_decimal_1: "Materiality Threshold Margin Value (VND)",
          property_datetime_1: "Next Mandatory Statutory Tax Filing Target"
        },
        visible_columns: %w[name property_string_1 property_string_2 property_integer_1 property_boolean_1]
      },
      "Customer Service" => {
        properties: {
          property_string_1: "Helpdesk SLA Tier",
          property_string_2: "Support Communication Channels",
          property_string_3: "Omnichannel Chatbot Automation Framework Engine",
          property_string_4: "Customer Escalation Tier-3 Backstop Handle Team",
          property_integer_1: "Target First Response Time Target Threshold (Sec)",
          property_integer_2: "Max Concurrence Chat Assignment Load Per Agent",
          property_boolean_1: "AI Real-Time Sentiment Voice Coaching Enabled",
          property_boolean_2: "Multilingual Translation Auto-Routing Pipelines Active",
          property_decimal_1: "Minimum QA Call Recording Compliance Grading Score",
          property_datetime_1: "Last SLA Contract Alignment Review Assessment"
        },
        visible_columns: %w[name property_string_1 property_string_2 property_integer_1 property_decimal_1]
      },
      "Inventory Control" => {
        properties: {
          property_string_1: "Audit Cycle Frequency",
          property_string_2: "Shrinkage Analysis Framework Protocol Tag",
          property_string_3: "ABC Inventory Classification Stratification Target",
          property_string_4: "Barcode Serialization Architecture Standard Model",
          property_boolean_1: "Auto-Reorder Triggers Active",
          property_boolean_2: "RFID Real-Time Racking Telemetry Stream Synced",
          property_integer_1: "Maximum Warehousing Discrepancy Variance Threshold",
          property_integer_2: "Annual Stocktake Execution Core Resource Headcount",
          property_decimal_1: "Target Inventory Turnover Frequency Index Minimum",
          property_datetime_1: "Next Scheduled Blind Spot-Check Stock Audit Execution"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_integer_1 property_decimal_1]
      }
    },

    brands: {
      "Luxury" => {
        properties: {
          property_string_1: "Tier Level",
          property_string_2: "Global Creative Director Name Signature",
          property_string_3: "Authorized Boutique Exterior Design Manual SKU",
          property_string_4: "Exclusive Distribution Rights Contract Reference",
          property_decimal_1: "Minimum MSRP Markup Margin",
          property_decimal_2: "Annual Brand Protection Anti-Counterfeit Budget",
          property_integer_1: "Global Heritage Brand Foundation Founding Year",
          property_integer_2: "Max Worldwide Selected Elite Showrooms Allocation",
          property_boolean_1: "Strict Price Deflation Markdown Bans Imposed",
          property_boolean_2: "Individual Product Certificate of Authenticity Issued"
        },
        visible_columns: %w[name property_string_1 property_decimal_1 property_integer_1 property_boolean_1]
      },
      "Mass Market" => {
        properties: {
          property_string_1: "Distribution Channel Model",
          property_string_2: "Primary High-Volume Manufacturing Cluster Zone",
          property_string_3: "EDI Data Exchange Transmission Schema Variant",
          property_string_4: "FMCG Supply Chain Logistics Routing Category",
          property_integer_1: "Minimum Order Quantity (MOQ)",
          property_integer_2: "Pallet Ingestion Minimum Lead Ordering Days",
          property_integer_3: "Target Market Share Penetration Grading Index",
          property_boolean_1: "Co-Op Retailer Advertising Fund Contributor",
          property_boolean_2: "Cross-Docking Rapid Flow Infrastructure Supported",
          property_decimal_1: "Defective Return Allowance Reserve Margin %"
        },
        visible_columns: %w[name property_string_1 property_integer_1 property_integer_2 property_boolean_1]
      },
      "Indie" => {
        properties: {
          property_string_1: "Founder Region",
          property_string_2: "Social Media Platform Origin Catalyst Tag",
          property_string_3: "Shared Incubation Lab Facility Registration ID",
          property_string_4: "Crowdfunding Campaign Historical Reference Key",
          property_boolean_1: "Consignment Agreement Terms Active",
          property_boolean_2: "Clean Beauty Formulation Paradigm Compliant",
          property_integer_1: "Active Influencer Affiliate Roster Headcount",
          property_integer_2: "Batch Production Sourcing Iteration Run Index",
          property_decimal_1: "Direct-to-Consumer Revenue Allocation Split %",
          property_datetime_1: "Current Limited Edition Collaboration Drop Target Date"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_integer_1 property_decimal_1]
      },
      "Organic" => {
        properties: {
          property_string_1: "Certification Body Name",
          property_string_2: "Agricultural Sourcing Farm Traceability Track",
          property_string_3: "Prohibited Synthetic Chemistry Audit Log Check",
          property_string_4: "Eco-Labeling Marketing Compliance Verification ID",
          property_datetime_1: "Certificate Expiration Date",
          property_datetime_2: "Last Soil Bio-Screening Audit Assessment Timestamp",
          property_boolean_1: "GMO Free Non-Transgenic Verification Badge",
          property_boolean_2: "Fair Trade Sourcing Supply Chain Chain Audited",
          property_integer_1: "Percentage Raw Material Bio-Sourced (Minimum %)",
          property_decimal_1: "Max Allowed Carbon Equivalent Offset Deficit metric"
        },
        visible_columns: %w[name property_string_1 property_datetime_1 property_boolean_1 property_integer_1]
      },
      "Eco-friendly" => {
        properties: {
          property_string_1: "Sustainability Rating",
          property_string_2: "Packaging Material Base",
          property_string_3: "Post-Consumer Recycled Content Metric Class",
          property_string_4: "Zero-Waste Circular Supply Loop Registration Reference",
          property_boolean_1: "Biodegradable Degradation Verification Attained",
          property_boolean_2: "Renewable Clean Energy Manufacturing Track Backed",
          property_integer_1: "Product Lifecycle Durability Estimate Index Score",
          property_integer_2: "Water Preservation Conservation Sourcing Liters Savings",
          property_decimal_1: "Carbon Footprint Calculation Value (CO2e/Unit)",
          property_decimal_2: "Supply Chain Locality Kilometers Proximity Average"
        },
        visible_columns: %w[name property_string_1 property_string_2 property_boolean_1 property_decimal_1]
      }
    },

    customers: {
      "Retail VIP" => {
        properties: {
          property_integer_1: "Current Loyalty Reward Points",
          property_integer_2: "Dedicated Personal Shopper Staff ID Allocation",
          property_decimal_1: "Fixed Lifetime Discount Percentage",
          property_decimal_2: "Historical Average Order Value (AOV VND Benchmark)",
          property_datetime_1: "VIP Tier Expiration Date",
          property_datetime_2: "Last Premium Lounge Concierge Check-in Stamp",
          property_string_1: "Preferred Milestone Gift Kit Choice Track",
          property_string_2: "Exclusive Velvet-Rope Event Invitation Priority Tier",
          property_boolean_1: "Waived Home Delivery Fulfillment Charges Privilege",
          property_boolean_2: "Early-Access New Collection Beta Pre-Ordering Enabled"
        },
        visible_columns: %w[name email property_integer_1 property_decimal_1 property_datetime_1 property_decimal_2]
      },
      "Regular" => {
        properties: {
          property_integer_1: "Visit Frequency Count",
          property_integer_2: "Average Days Between Store Store Re-engagements",
          property_string_1: "Preferred Store Branch",
          property_string_2: "Primary Communication Channel Opt-In Channel",
          property_string_3: "Dominant Purchased Department Classification",
          property_string_4: "Referral Source Acquisition Pathway Descriptor",
          property_boolean_1: "Digital Marketing Newsletter Enrolled",
          property_boolean_2: "E-Receipt Default Preference Active",
          property_decimal_1: "Total Net Revenue Contributed To Date (VND)",
          property_datetime_1: "Last Checkout Lane Transaction Complete Date"
        },
        visible_columns: %w[name email property_integer_1 property_string_1 property_decimal_1 property_datetime_1]
      },
      "Wholesale" => {
        properties: {
          property_string_1: "Tax Identification Number (TIN)",
          property_string_2: "Credit Terms Granted (e.g., Net 30)",
          property_string_3: "Corporate Sub-Buyer Authorized Ordering Personnel",
          property_string_4: "Custom Packing/Pallet Labeling Standard Variant",
          property_decimal_1: "Credit Line Limit Amount",
          property_decimal_2: "Overdue Outstanding Balance Ledger Account (VND)",
          property_integer_1: "Consolidated Monthly Shipping Location Target Units",
          property_integer_2: "Minimum Multi-Pack Reorder Threshold Metric",
          property_boolean_1: "Exempt from Value-Added Tax (VAT Reverse Charge)",
          property_boolean_2: "Third-Party Logistics Freight Forwarding Self-Pickup"
        },
        visible_columns: %w[name email property_string_1 property_string_2 property_decimal_1 property_decimal_2]
      },
      "Occasional" => {
        properties: {
          property_string_1: "Acquisition Campaign Source",
          property_string_2: "Seasonal Trigger Catalyst Category Alignment",
          property_string_3: "Abandoned Cart Retargeting Sequence Tracking Hash",
          property_string_4: "One-Time Flash Promotion Code Redemptions Stamped",
          property_integer_1: "Total Promo Codes Ingested Over Account Lifetime",
          property_integer_2: "Dormancy Counter Window Days Tracking Flag",
          property_boolean_1: "Win-Back Incentive Sequence Active In Engine",
          property_boolean_2: "Direct SMS Telemarketing Block Flag Set",
          property_decimal_1: "Price Sensitivity Index Elasticity Rating Metric",
          property_datetime_1: "First Initial System Profile Creation Date"
        },
        visible_columns: %w[name email property_string_1 property_integer_1 property_boolean_1 property_datetime_1]
      },
      "Walk-in" => {
        properties: {
          property_string_1: "General Notes / Behavioral Tags",
          property_string_2: "Estimated Age Grouping Demographic Cohort",
          property_string_3: "Observed Product Interaction Category Touchpoint",
          property_string_4: "Peak Visit Hour Entry Band Tracker Token",
          property_boolean_1: "Anonymized Guest Profile Context Flag",
          property_boolean_2: "Refused Loyalty Registration Prompt Indicator",
          property_integer_1: "Estimated Minutes Spent Browsing Sales Floors",
          property_integer_2: "Accompanying Guest Shopping Group Unit Count",
          property_decimal_1: "Cash Versus Electronic Wallet Tender Propensity Factor",
          property_datetime_1: "Store Gate Attendance Sensor Ingestion Timestamp"
        },
        visible_columns: %w[name email property_string_1 property_boolean_2 property_integer_1]
      }
    },

    services: {
      "Skincare Consultation" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_integer_2: "Recommended Follow-up Consultation Window (Days)",
          property_string_1: "Required Analysis Equipment",
          property_string_2: "Diagnostic Software Session Parameter Preset",
          property_string_3: "Dermatological Patch-Test Material Formulation Lot",
          property_string_4: "Aesthetician Specialization Certification Requirements",
          property_boolean_1: "Requires Client Deep-Clean Facial Prep Sequence",
          property_boolean_2: "Includes Post-Consultation Complementary Sample Bundle",
          property_decimal_1: "Device Calibration Sensitivity Rating Boundary",
          property_datetime_1: "Last Diagnostic Hardware Re-Sterilization Routine"
        },
        visible_columns: %w[name property_integer_1 property_string_1 property_integer_2 property_boolean_1]
      },
      "Makeup Artistry" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_integer_2: "Lighting Setting Array Presets Required",
          property_decimal_1: "Consumables Material Surcharge Cost",
          property_decimal_2: "Intricate FX Detailing Premium Multiplier Add-on",
          property_string_1: "Occasion Theme Category (Wedding/Gala/Editorial)",
          property_string_2: "Branded Pigment Counter Affiliation Lock",
          property_string_3: "Sanitizer Disinfection Compound Variant Code",
          property_string_4: "Moodboard Reference Attachment Asset URL",
          property_boolean_1: "Allergy Screening Disclosure Agreement Signed",
          property_boolean_2: "Portfolio Photography Release Cleared By Client"
        },
        visible_columns: %w[name property_integer_1 property_decimal_1 property_string_1 property_boolean_1]
      },
      "Spa Treatment" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_integer_2: "Aromatherapy Essential Oil Diffuser Recipe Index",
          property_string_1: "Assigned Treatment Room",
          property_string_2: "Linen Restocking Bundle Configuration Code",
          property_string_3: "Audio Playlist Sequence Ambient Track ID",
          property_string_4: "Therapeutic Modality Style Tag (Deep Tissue/Swedish)",
          property_boolean_1: "Shower Facilities Required",
          property_boolean_2: "Pre-Service Hot Herbal Compresses Mandated",
          property_decimal_1: "Massage Table Electronic Incline Degrees Pitch",
          property_decimal_2: "Sauna Pre-Heat Temperature Target Metric (C)"
        },
        visible_columns: %w[name property_integer_1 property_string_1 property_boolean_1 property_integer_2]
      },
      "Delivery & Installation" => {
        properties: {
          property_string_1: "Logistics Vehicle Tier Required",
          property_string_2: "Heavy Lifting Equipment Rigging Tag Allocation",
          property_string_3: "Transit Secure Wrapping Material Specification",
          property_string_4: "Secondary Backup Driver Shift Manifest Assignment",
          property_decimal_1: "Base Distance Rate Buffer Zone",
          property_decimal_2: "Oversized Cargo Volumetric Density Factor Calculation",
          property_integer_1: "Estimated Structural Assembly Duration Hours",
          property_integer_2: "Minimum Flight of Stairs Access Clearance Limits",
          property_boolean_1: "Requires Multi-Crew Team Assembly Handlers",
          property_boolean_2: "Sign-Off Proof of Functional Operational Performance Cleared"
        },
        visible_columns: %w[name property_string_1 property_decimal_1 property_integer_1 property_boolean_1]
      },
      "Membership Registration" => {
        properties: {
          property_string_1: "Sign-up Welcome Gift Kit Code",
          property_string_2: "Data Privacy Consent Framework Legal Version Identifier",
          property_string_3: "Linked Banking Direct-Debit Mandate Token ID",
          property_string_4: "Omnichannel Customer Segment Initial Matrix Node",
          property_boolean_1: "Requires Physical Card Printing",
          property_boolean_2: "Instant Smart Wallet Pass Generation Dispatched",
          property_integer_1: "Account Activation Processing Queue Priority Rank",
          property_integer_2: "Complimentary Voucher Allocations Disbursed Count",
          property_decimal_1: "Initial Account Balance Points Multiplier Factor",
          property_datetime_1: "Mandatory Profile Re-Verification Security Cycle Date"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_integer_1 property_integer_2]
      }
    },

    facilities: {
      "Retail Floor" => {
        properties: {
          property_decimal_1: "Floor Space (Sqm)",
          property_decimal_2: "Zonal Lux Lighting Intention Target Value",
          property_integer_1: "Maximum Customer Capacity Count",
          property_integer_2: "Aisle Guideline Clearance Configuration Width (cm)",
          property_string_1: "HVAC Zone Air Conditioning Segment Key",
          property_string_2: "In-Store Digital Signage Display Network Playlist ID",
          property_string_3: "Visual Merchandising Blueprint Planogram Series Reference",
          property_string_4: "Dedicated Loss Prevention Floor Marshal Guard Post ID",
          property_boolean_1: "Wheelchair Wheel Access Ramp System Configured",
          property_boolean_2: "Ambient Scent Dispersion Nozzle Units Active"
        },
        visible_columns: %w[name property_decimal_1 property_integer_1 property_string_1 property_boolean_1]
      },
      "Storage Room" => {
        properties: {
          property_decimal_1: "Temperature Range Ceiling (C)",
          property_decimal_2: "Humidity Target Threshold %",
          property_boolean_1: "Biometric Lock Security Restricting Access",
          property_boolean_2: "Industrial Heavy Pallet Racking Seismic Bolts Affixed",
          property_integer_1: "Fire Safety High-Expandable Foam Nozzle Drop Nodes",
          property_integer_2: "Max Vertical Crate Stacking Limits Safety Index",
          property_string_1: "Intruder Motion Alarm Zone Sensor Segment Code",
          property_string_2: "Pest Extermination Bait Station Map Matrix Coordinates",
          property_string_3: "Hazardous Materials Spill Kit Depot Designation",
          property_datetime_1: "Last Calibration Log Electronic Environmental Sensor"
        },
        visible_columns: %w[name property_decimal_1 property_boolean_1 property_decimal_2 property_integer_2]
      },
      "Office Space" => {
        properties: {
          property_integer_1: "Configured Network Nodes Count",
          property_integer_2: "Desk Capacity Limit",
          property_integer_3: "VoIP Trunk Line Extension Range Boundaries",
          property_string_1: "Access Control Badge Readers Firmware Version String",
          property_string_2: "Confidential Shredding Bin Secure Seal Log Serial",
          property_string_3: "Local Department Hot-Desking Digital Map Sector",
          property_boolean_1: "Backup Uninterruptible Power Supply (UPS) Server Nodes Online",
          property_boolean_2: "Corporate Intranet Secure Local Area Wi-Fi Footprint Mesh",
          property_decimal_1: "Average Ergonomic Desk Workspace Metric Units (Sqm)",
          property_datetime_1: "Fire Warden Evacuation Team Drills Refresher Deadline"
        },
        visible_columns: %w[name property_integer_1 property_integer_2 property_string_1 property_boolean_1]
      },
      "Break Room" => {
        properties: {
          property_boolean_1: "Equipped with Refrigerator",
          property_boolean_2: "Water Purifier Installed",
          property_boolean_3: "Commercial Microwave Appliance Health Inspection Passed",
          property_integer_1: "Total Lockers Assembled For Personal Use Storage",
          property_integer_2: "First Aid Response Station Kit Contents Inventory Count",
          property_string_1: "Cleaning Duty Maintenance Checklist Rotational Roster Code",
          property_string_2: "Vending Machine Third Party Supplier Account ID",
          property_string_3: "Corporate Notice Board Communication Authorization Key",
          property_decimal_1: "Dedicated Break Area Layout Floor Dimensions (Sqm)",
          property_datetime_1: "Last Deep Chemical Sterilization Treatment Date"
        },
        visible_columns: %w[name property_boolean_1 property_boolean_2 property_integer_1 property_string_1]
      },
      "Parking Area" => {
        properties: {
          property_integer_1: "Motorbike Parking Stalls Count",
          property_integer_2: "Car Parking Stalls Count",
          property_integer_3: "EV Charging Infrastructure Stations Commissioned",
          property_boolean_1: "License Plate Recognition OCR Barrier Camera Active",
          property_boolean_2: "Shared Common Area Overhead Weather Canopy Assembled",
          property_decimal_1: "Monthly Contract Staff Parking Subsidy Deduction Rate",
          property_decimal_2: "Commercial Guest Parking Valet Rate Calculation Factor",
          property_string_1: "Security Patrol Route Checkpoint Barcode RFID Tag Key",
          property_string_2: "Emergency Flood Evacuation Drainage Valve Segment",
          property_datetime_1: "Last Asphalt Resurfacing Tar Application Inspection Complete"
        },
        visible_columns: %w[name property_integer_1 property_integer_2 property_boolean_1 property_boolean_2]
      },
      "Security Station" => {
        properties: {
          property_integer_1: "CCTV Monitor Matrices Hooked",
          property_integer_2: "Radio Communication Encrypted Handset Walkie Fleet Allocation",
          property_string_1: "Emergency Contact Keypad Trunk Line",
          property_string_2: "Master Fire Alarm Panel Relay Trigger Firmware Identity",
          property_string_3: "External Private Security Contractor Patrol Reference Protocol",
          property_string_4: "Digital Video Recorder Mainframe Server Array Enclosure ID",
          property_boolean_1: "Panic Button Silent Alarm Directly Interfaced To Local Police",
          property_boolean_2: "Backup Contingency Key Vault Steel Safe Double Authenticated",
          property_decimal_1: "Maximum Video Retention Capacity Storage Drives Terabytes",
          property_datetime_1: "Last Certified Safety Inspection Panic Hardware Interceptors"
        },
        visible_columns: %w[name property_integer_1 property_string_1 property_boolean_1 property_integer_2]
      }
    },

    warehouses: {
      "Distribution Center" => {
        properties: {
          property_integer_1: "Loading Bay Count",
          property_integer_2: "Cross-Dock Sorting Lane Segments Active",
          property_decimal_1: "Storage Capacity (sqm)",
          property_decimal_2: "Max Vertical Structural Safe Racking Load Ceiling (tons)",
          property_boolean_1: "Automated Sorting System Fitted",
          property_boolean_2: "Overhead Gantry Crane Rail Assembly Inspected",
          property_string_1: "Logistics Hub Carrier Dispatch Protocol Standard",
          property_string_2: "High-Speed Scanner Terminal Network Hardware Node ID",
          property_string_3: "Regional Logistics Supply Chain Cluster Tag",
          property_datetime_1: "Last Fleet Scale Mass Calibration Check Execution Time"
        },
        visible_columns: %w[name property_integer_1 property_decimal_1 property_boolean_1 property_integer_2 property_string_1]
      },
      "Cold Storage" => {
        properties: {
          property_decimal_1: "Min Temperature (C)",
          property_decimal_2: "Max Temperature (C)",
          property_decimal_3: "Max Ambient Relative Humidity Percentage Caps",
          property_boolean_1: "Backup Generator Installed",
          property_boolean_2: "Cryogenic Liquid Nitrogen Backup System Pipe Matrix Sealed",
          property_integer_1: "Defrost Thermal Melting Cycle Interval Frequency Hours",
          property_integer_2: "Acoustic Temperature Alarm Siren Decibel Volume Rating",
          property_string_1: "Refrigerant Compound Chemical Type Technical Label",
          property_string_2: "Hermetic Vault Door Gasket Seal Maintenance Batch Serial",
          property_datetime_1: "Last Environmental Sensor Telemetry Recalibration Timestamp"
        },
        visible_columns: %w[name property_decimal_1 property_decimal_2 property_boolean_1 property_integer_1]
      },
      "Fulfillment Hub" => {
        properties: {
          property_integer_1: "Max Daily Orders Capacity",
          property_integer_2: "Staff Count Per Shift",
          property_integer_3: "Packing Bench Assembly Station Nodes Configured",
          property_string_1: "Carrier Partnerships",
          property_string_2: "Pick-to-Light Subsystem Communication Interface Profile",
          property_string_3: "Manifest Print Station Driver API Routing Alias",
          property_boolean_1: "Intralogistics Autonomous Mobile Robots Fleet Active",
          property_boolean_2: "Weight Verification Inline Check-Weigher Conforming",
          property_decimal_1: "Average Order Processing Cycle Duration From Pick (Min)",
          property_decimal_2: "Dimensioner Volumetric Box Scanner Laser Accuracy Tolerances"
        },
        visible_columns: %w[name property_integer_1 property_integer_2 property_string_1 property_boolean_1]
      }
    },


    stock_transfers: {
      "Inter-Branch Transfer" => {
        properties: {
          property_string_1: "Origin Warehouse Name",
          property_string_2: "Destination Branch Name",
          property_string_3: "Contracted Third Party Courier Route Cargo Identifier",
          property_string_4: "Driver Bill of Lading Manifest Validation Check Token",
          property_integer_1: "Transit Time (Hours)",
          property_integer_2: "Transit Temperature Log Device Assigned Serial ID",
          property_boolean_1: "Requires Special Fragile Shock-Absorbent Strapping Layers",
          property_boolean_2: "Partial Delivery Container Split Allocations Allowed",
          property_decimal_1: "Prerated Intercompany Logistics Cost Distribution (VND)",
          property_datetime_1: "Mandatory Target Delivery Arrival Check-in Gate Window"
        },
        visible_columns: %w[name property_string_1 property_string_2 property_integer_1 property_boolean_1]
      },
      "Emergency Replenishment" => {
        properties: {
          property_string_1: "Urgency Reason Notes",
          property_string_2: "Stockout Event Operational Escalation Authority Alias",
          property_string_3: "Premium Expedited Delivery Carrier Service Class Code",
          property_string_4: "Alternative Source Sourcing Depot Redundant Fallback Node",
          property_boolean_1: "Approved by Manager",
          property_boolean_2: "Direct-to-Shelf Express Bypassing Inbound Standard Audits",
          property_integer_1: "Lost Revenue Opportunity Run-Rate Surcharge Penalty Index",
          property_integer_2: "Total Customer Backorder Fulfillment Queues Waiting Units",
          property_decimal_1: "Express Air Freight Surcharge Premium Outlay Fee (VND)",
          property_datetime_1: "Immediate Operational Delivery Deadline Ingestion Cutoff"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_string_2 property_decimal_1]
      }
    },

    stock_exports: {
      "Customer Sale" => {
        properties: {
          property_string_1: "Customer Order Reference Code",
          property_string_2: "Point of Sale (POS) Station Source Node Identifier",
          property_string_3: "Loyalty Tier Ingestion Context Tag Reference",
          property_string_4: "Outbound Dispatch Shipping Label Format Type Variant",
          property_integer_1: "Items Count In Shipment",
          property_integer_2: "Fulfillment Quality Assurance Scale Packing Bench ID",
          property_boolean_1: "Signature On Delivery Identity Verification Demanded",
          property_boolean_2: "E-Commerce Digital Channel Tracking Stream Broadcasted",
          property_decimal_1: "Total Gross Invoiced Line-Item Transaction Value (VND)",
          property_datetime_1: "Outbound Courier Hub Scanning Manifest Handoff Timestamp"
        },
        visible_columns: %w[name property_string_1 property_integer_1 property_boolean_1 property_decimal_1]
      },
      "Damaged Write-off" => {
        properties: {
          property_string_1: "Damage Description",
          property_string_2: "Root Cause Liability Categorization (Transit/Handling/Force)",
          property_string_3: "EHS Workplace Hazard Safety Assessment Reference Number",
          property_string_4: "Salvageable Component Scrappage Recovery Sorting Code",
          property_boolean_1: "Insurance Claim Filed Status",
          property_boolean_2: "Hazardous Materials Disposal Manifest Token Handled",
          property_integer_1: "Total Scrap Weight Density Scale Measurement Metric (g)",
          property_integer_2: "Incident Witness Statement Employee Database Reference ID",
          property_decimal_1: "Total Book Value Asset Capital Destruction Write-Off (VND)",
          property_datetime_1: "Mandatory Quality Assurance Review Signoff Finalization Date"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_string_2 property_decimal_1]
      },
      "Expired Disposal" => {
        properties: {
          property_datetime_1: "Expiration Date",
          property_datetime_2: "Actual Physical Disposals Incineration Execution Time",
          property_string_1: "Disposal Method Used",
          property_string_2: "Third-Party Certified Bio-Waste Contractor Registry ID",
          property_string_3: "Environmental Effluent Waste Stream Tracking Classification",
          property_string_4: "Batch Formulation Chemical Counter-Agent Neutralizer Lot",
          property_boolean_1: "Public Health Safety Mandatory Quarantine Executed Flag",
          property_boolean_2: "Landfill Diversion Carbon Penalty Exemption Voucher Applied",
          property_integer_1: "Total Itemized Shelf-Life Violation Lifespan Excess Days",
          property_decimal_1: "Total Direct Financial Product Purchase Cost Sunk Value (VND)"
        },
        visible_columns: %w[name property_datetime_1 property_string_1 property_boolean_1 property_decimal_1]
      }
    },

    orders: {
      "In-Store Purchase" => {
        properties: {
          property_string_1: "Sales Associate Name",
          property_string_2: "Payment Method Used",
          property_string_3: "Tender Sub-Type Transaction Clearing Gateway Identity",
          property_string_4: "Cash Drawer Physical Currency Drop Reference Tracking",
          property_integer_1: "Items Count",
          property_integer_2: "Customer Receipt Duplication Print Sequence Metric ID",
          property_boolean_1: "Tax Invoice Copy Directly Dispatched via Connected Email",
          property_boolean_2: "Point-of-Sale Loyalty Rewards Matrix Instantly Triggered",
          property_decimal_1: "Change Cash Amount Disbursed From Register Base (VND)",
          property_datetime_1: "Cashier Station Scanning Session Sequence Initialization"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1]
      },
      "Online Order" => {
        properties: {
          property_string_1: "Shipping Carrier Name",
          property_string_2: "E-Commerce Platform Checkout Session Identifier Token",
          property_string_3: "Customer IP Address Geolocational Fraud Analysis Score",
          property_string_4: "Selected Last-Mile Delivery Time Slot Allocation Windows",
          property_datetime_1: "Estimated Delivery Date",
          property_datetime_2: "Payment Gateway Webhook Verification Clearing Timestamp",
          property_boolean_1: "Gift Wrapping Requested",
          property_boolean_2: "Substituted Out-of-Stock Items via Merchant Discretion Ok",
          property_integer_1: "Total Dimensional Weight Cube Sizing Packing Matrix (cm3)",
          property_decimal_1: "Fulfillment Surcharge Delivery Logistics Quoted Rates (VND)"
        },
        visible_columns: %w[name code property_string_1 property_datetime_1 property_boolean_1 property_decimal_1]
      },
      "Phone Order" => {
        properties: {
          property_string_1: "Call Agent Name",
          property_string_2: "Customer Callback Number",
          property_string_3: "Call Center IVR Inbound Voice Session Recording Reference",
          property_string_4: "Manual Credit Card Ingestion Vault Sandbox Token Key",
          property_integer_1: "Total Agent Script Compliance Check Score Index Rating",
          property_integer_2: "Customer Hold Duration Wait Pipeline Queue Time (Sec)",
          property_boolean_1: "Order Summary Confirmation Dispatched Via Telephony SMS Link",
          property_boolean_2: "Customer Agreed To Recurring Periodic Subscription Enrolment",
          property_decimal_1: "Manual Order Processing Overhead Handling Fee Surcharge",
          property_datetime_1: "Agent Customer CRM Interaction Session Lifecycle Open Date"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_boolean_1 property_integer_1]
      }
    },

    stock_imports: {
      "Supplier Purchase" => {
        properties: {
          property_string_1: "Supplier Name",
          property_string_2: "Purchase Order Reference Identity Code Document Contract",
          property_string_3: "Country of Origin Customs Tariff Harmonized System Code",
          property_string_4: "Inbound Freight Carrier Pro-Bill Tracking Number String",
          property_datetime_1: "Expected Delivery Date",
          property_datetime_2: "Supplier Ship-Out Port Ingestion Logistics Verification Time",
          property_integer_1: "Purchase Order Line Items Count Summary",
          property_integer_2: "Total Master Carton Units Pallet Layer Count Delivered",
          property_boolean_1: "International Import Customs Bill of Entry Clearance Cleared",
          property_boolean_2: "Supplier Pro-Forma Packing Discrepancy Claims Active Flag"
        },
        visible_columns: %w[name property_string_1 property_datetime_1 property_integer_1 property_boolean_1]
      },
      "Customer Return" => {
        properties: {
          property_string_1: "Return Reason Category",
          property_string_2: "Original Sales Invoice Reference Authentication Token",
          property_string_3: "Customer Dispute Resolution Escalation Tracking Ticket ID",
          property_string_4: "Restocking Disposition Target (Return to Shelf/Rework/Scrap)",
          property_boolean_1: "Inspection Passed",
          property_boolean_2: "Customer Store Credit Balance Instantly Disbursed Systemic",
          property_integer_1: "Customer Account Age Days Since Initial Purchase Tracking",
          property_integer_2: "Return Verification Assessment Inspector Employee Key ID",
          property_decimal_1: "Restocking Processing Admin Fee Handling Penalty Charged",
          property_datetime_1: "Return Processing Receiving Station Checklist Completed Date"
        },
        visible_columns: %w[name property_string_1 property_boolean_1 property_string_2 property_decimal_1]
      },
      "Transfer In" => {
        properties: {
          property_string_1: "Source Warehouse Name",
          property_string_2: "Outbound Dispatch Inter-Depot Security Seal Serial Identifier",
          property_string_3: "Systemic Transit Discrepancy Ledger Reconciliation Reference",
          property_string_4: "Transfer Routing Logistics Driver Identity License Plate",
          property_integer_1: "Packing Slip Units Count Summary",
          property_integer_2: "Actual Physically Counted Received Stock Unit Ingestion total",
          property_boolean_1: "Total Quantities Match systemic Internal Manifests Integrity",
          property_boolean_2: "Transit Box Damaged Structural Claims Flag Checklist Triggered",
          property_decimal_1: "Internal Freight Cost Allocation Matrix Split Ratio Value",
          property_datetime_1: "Receiving Bay Roller Conveyor Shutter Gate Scan Execution Date"
        },
        visible_columns: %w[name property_string_1 property_integer_1 property_boolean_1 property_integer_2]
      }
    },

    invoices: {
      "B2C Retail Invoice" => {
        properties: {
          property_string_1: "Payment Method Type (Cash/Card/Wallet)",
          property_string_2: "POS Terminal Machine Identifier",
          property_string_3: "Connected Order Reference Code",
          property_string_4: "Cashier Employee Database ID",
          property_integer_1: "Total Line-Item Quantities Invoiced",
          property_integer_2: "Loyalty Program Reward Points Earned",
          property_decimal_1: "Value-Added Tax (VAT Amount VND)",
          property_decimal_2: "Applied Direct Promotional Discount (VND)",
          property_boolean_1: "Digital Receipt Emailed to Customer",
          property_datetime_1: "Fiscal Ledger Synchronization Timestamp"
        },
        visible_columns: %w[name code property_string_1 property_string_3 property_decimal_1 property_boolean_1]
      },
      "B2B Corporate Invoice" => {
        properties: {
          property_string_1: "Buyer Tax Identification Number (TIN)",
          property_string_2: "Registered Corporate Company Name",
          property_string_3: "Credit Payment Terms Granted (e.g., Net 30)",
          property_string_4: "Authorized Corporate Procurement Agent Name",
          property_integer_1: "Purchase Order (PO) Reference Document Number",
          property_integer_2: "Days Outstanding Until Late Penalty Trigger",
          property_decimal_1: "Total Gross Transaction Subtotal (VND)",
          property_decimal_2: "Approved Commercial Volume Discount Rate %",
          property_boolean_1: "Requires Split-Payment Milestone Clearing",
          property_boolean_2: "E-Invoice Electronic Signature Verified (Sign Digital)"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_string_3 property_decimal_1 property_boolean_2]
      },
      "Tax Refund Invoice" => {
        properties: {
          property_string_1: "Tourist International Passport Number",
          property_string_2: "Nationality / Country of Citizenship Registry",
          property_string_3: "Customs Inspection Gate Processing Location",
          property_string_4: "Tax Refund Agent Counter Clearance Reference",
          property_integer_1: "Flight / Voyage Outbound Departure Number",
          property_integer_2: "Days Left to Claim Refund Before Expiration",
          property_decimal_1: "Refundable Tax Value Amount (VND)",
          property_decimal_2: "Admin Processing Handling Fee Surcharge (VND)",
          property_boolean_1: "Customs Declaration Physical Stamp Cleared",
          property_datetime_1: "Port of Exit Border Ingestion Inspection Date"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_decimal_1 property_boolean_1 property_datetime_1]
      }
    }
  }.freeze

  # An array of popular company/brand names for seeding.
  POPULAR_BRANDS = [
    "Apple", "Samsung", "Google", "Microsoft", "Amazon", "Facebook", "Tesla",
    "Toyota", "Coca-Cola", "McDonald's", "Disney", "Nike", "Adidas", "Louis Vuitton",
    "Gucci", "Mercedes-Benz", "BMW", "Intel", "IBM", "Cisco", "Oracle", "SAP",
    "Accenture", "Deloitte", "PwC", "KPMG", "EY", "GE", "Honda", "Ford", "Pepsi",
    "Starbucks", "IKEA", "H&M", "Zara", "Uniqlo", "L'Oréal", "Gillette", "Pampers",
    "Colgate", "Nescafé", "Red Bull", "Mastercard", "Visa", "American Express",
    "J.P. Morgan", "Goldman Sachs", "Morgan Stanley", "Netflix", "Spotify"
  ].freeze

  def initialize(user:, email: Faker::Internet.email, name: nil)
    @multi_company_owner = user
    @name = name
    @retail = nil
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []
    @services = []
    @warehouses = []
    @pages = []
    @product_counter = 0
    @service_counter = 0
    @employee_counter = 0
    @customer_counter = 0
    @facility_counter = 0
    @email = email
    @email_domain = EmailService.new(email).full_domain
    seeding
  end

  def seeding
    print_header

    create_retail_company
    create_categories
    create_table_configs
    create_brands
    create_branches
    create_pages
    create_subscription_plans_for_company
    create_facilities_for_branches
    appoint_payment_methods_to_company
    setup_roles_and_permissions
    create_departments_for_company
    create_employees
    assign_employees_to_departments
    create_customers_for_company
    setup_loyalty_programs
    create_inventory
    create_warehouses_for_branches
    create_stocks_for_products
    create_stock_transfers
    create_stock_imports
    create_stock_exports
    create_customer_orders
    create_invoices
    create_billing_data

    print_footer
    true
  end

  private

  def print_header
    puts "\n\n🛍️  Starting Retail Company Group Seeding..."
    puts "========================================================="
  end

  def print_footer
    puts "\n========================================================="
    puts "🛍️  Retail Company Group Seeding Complete!"
    puts "========================================================="
  end

  def create_retail_company
    puts "Creating retail group..."
    @retail = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: @name || "Company #{Company.count + 1}",
      email: @email,
      description: "A group for multiple retail branch branches",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
  end


  def create_categories
    METADATA_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        Seed::CategoryService.create(
          company: @retail,
          name: name,
          resource_name: resource_name.to_s,
          properties: entry[:properties]
        )
      end
    end
  end

  def create_table_configs
    METADATA_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        keys = entry[:visible_columns]
        next unless keys.present?

        category = Category.find_by(company: @retail, resource_name: resource_name.to_s, name: name)
        next unless category

        Seed::TableConfigService.create(
          company: @retail,
          resource_name: resource_name.to_s,
          category: category,
          property_mapping: category.default_property_mapping,
          columns_metadata: keys.map { |k| field_hash(k, entry[:properties]) },
          name: "#{name} table config"
        )
      end
    end
  end

  def field_hash(key, properties = {})
    label = properties[key.to_sym] || key.humanize
    { "key" => key, "label" => label, "visible" => true,
      "sortable" => true, "align" => "left", "pinned" => nil,
      "width" => nil, "roles" => [], "is_virtual" => false,
      "render_config" => {} }
  end

  def create_brands
    POPULAR_BRANDS.each do |brand_name|
      Seed::BrandService.create(company: @retail, name: brand_name)
    end
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Branch #{i + 1}",
        description: "Description for Branch #{i + 1}",
        company: @retail
      )
      branch.attach_tag(key: "Branch #{branch.id} Tag")
      branch.address = Seed::AddressService.create
      branch.save!

      @branches << branch
    end
  end

  def create_pages
    puts "Creating pages for each branch..."
    @branches.each do |branch|
      Seed::PageService.create(
        company: @retail,
        branch: branch,
        name: "Retail Cashier",
        target_role: :retail_cashier,
        target_resolution: :desktop_widescreen,
        layout_manifest: {
          grid_columns: 12,
          default_sidebar: "customer_loyalty_panel",
          enabled_components: [
            { id: "barcode_listener_daemon", position: "background" },
            { id: "product_search_matrix", position: "span-8", items_per_row: 6 },
            { id: "checkout_summary_card", position: "span-4" }
          ],
          features: {
            quick_cash_buttons: [ 10000, 20000, 50000, 100000, 200000, 500000 ],
            gift_card_redemption: true
          }
        }
      )

      Seed::PageService.create(
        company: @retail,
        branch: branch,
        name: "Retail Store Manager",
        target_role: :retail_store_manager,
        target_resolution: :desktop_widescreen,
        layout_manifest: {
          grid_columns: 12,
          default_sidebar: "analytics_panel",
          enabled_components: [
            { id: "sales_kpi_dashboard", position: "span-6" },
            { id: "inventory_alerts", position: "span-6" },
            { id: "staff_on_duty", position: "span-4" },
            { id: "daily_revenue_chart", position: "span-8" }
          ],
          features: {
            approve_discounts: true,
            view_profit_margins: true,
            export_reports: true
          }
        }
      )
    end
  end

  def create_subscription_plans_for_company(count: 3)
    count.times do |i|
      Seed::SubscriptionPlanService.create(
        company: @retail,
        name: "Plan #{i + 1}",
        duration_days: rand(30..365)
      )
    end
  end

  def create_subscriptions_for_company(count: 3)
    count.times do |i|
      Seed::SubscriptionService.create(
        company: @retail,
        name: "Retail Company Group Subscription #{i + 1}",
        description: "Subscription plan #{i + 1} for #{@retail.name}"
      )
    end
  end

  def create_facilities_for_branches
    @branches.each do |branch|
      facility_count = rand(1..3)
      facility_count.times do |i|
        @facility_counter += 1
        facility = Seed::FacilityService.create(
          company: @retail,
          branch: branch,
          name: "Facility #{@facility_counter}",
          description: "A facility location for #{branch.name}"
        )
        facility.attach_tag(key: "Facility #{facility.id} Tag")
        facility.save!
        @facilities << facility
      end
    end
  end

  def appoint_payment_methods_to_company
    @branches.each do |branch|
      3.times { Seed::PaymentMethodAppointmentService.create(company: @retail) }
    end
  end

  def setup_roles_and_permissions
    RETAIL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @retail,
        name: role_name,
        description: "#{role_name} role for #{@retail.name}"
      )
    end
    configure_retail_permissions
  end

  def create_departments_for_company
    [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each do |dept_name|
      department = Seed::DepartmentService.create(
        company: @retail,
        name: dept_name,
        description: "Department: #{dept_name}"
      )
      department.attach_tag(key: "Department #{department.id} Tag")
      department.save!
      @departments << department
    end
  end

  def create_employees
    @branches.each_with_index do |branch, index|
      branch_employees = []

      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "#{role_name}_#{i + 1}_retail_branch_#{index + 1}@#{@email_domain}",
            system_role: :company_employee
          )
          @employee_counter += 1
          employee = Seed::EmployeeService.create(
            user: user, company: @retail, branch: branch,
            name: "Employee #{@employee_counter}"
          )
          employee.attach_role(role_name)
          employee.save!
          branch_employees << employee
        end
      end

      @employees.concat(branch_employees)
    end
  end

  def assign_employees_to_departments
    @employees.each do |employee|
      Seed::DepartmentAppointmentService.create(
        company: @retail,
        department: @departments.sample,
        appoint_to: employee
      )
    end
  end

  def create_customers_for_company
    @branches.each do |branch|
      CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "customer_#{i + 1}_#{branch.id}@example.com",
            system_role: :company_customer
          )
          @customer_counter += 1
          customer = Seed::CustomerService.create(
            user: user, company: @retail, branch: branch, name: "Customer #{@customer_counter}"
          )
          @customers << customer
        end
      end
    end
  end

  def setup_loyalty_programs
    @branches.each do |branch|
      2.times do |i|
        lp = Seed::CustomerGroupService.create(
          company: @retail, branch: branch, name: "Loyalty Program #{i + 1} - #{branch.name}"
        )
        @loyalty_programs << lp

        branch_customers = @customers.select { |c| c.branch_id == branch.id }
        branch_customers.sample(10).each do |customer|
          Seed::CustomerGroupAppointmentService.create(company: @retail, customer_group: lp, appoint_to: customer)
        end
      end
    end
  end

  def create_inventory
    @branches.each do |branch|
      # 1. Seed 14 Products per branch with index-based naming
      14.times do
        @product_counter += 1
        product = Seed::ProductService.create(
          company: @retail,
          branch: branch,
          name: "Product #{@product_counter}",
          description: "High-quality skincare product"
        )
        @products << product
      end

      # 2. Seed 5 Services per branch with index-based naming
      5.times do
        @service_counter += 1
        service = Seed::ServiceService.create(
          company: @retail,
          branch: branch,
          name: "Service #{@service_counter}",
          duration: [ 30, 45, 60, 90 ].sample
        )
        @services << service
      end
    end
  end

  def create_warehouses_for_branches
    @branches.each do |branch|
      warehouse = Seed::WarehouseService.create(
        company: @retail,
        branch: branch,
        name: "#{branch.name} Warehouse",
        business_type: :distribution
      )

      @warehouses ||= []
      @warehouses << warehouse
    end
  end

  def create_stocks_for_products
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each do |product|
        Seed::StockService.create(
          warehouse: warehouse,
          product_id: product.id,
          quantity: rand(50..200),
          reorder: rand(10..30),
          name: product.name
        )
      end
    end
  end

  def create_stock_transfers
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each do |product|
        stock = Stock.find_by(name: product.name, warehouse: warehouse)
        next unless stock

        Seed::StockTransferService.create(
          company: @retail,
          branch: warehouse.branch,
          warehouse: warehouse,
          product: product,
          appoint_from: warehouse,
          appoint_to: warehouse.branch,
          quantity: stock.quantity,
          workflow_status: :completed,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_stock_imports
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockImportService.create(
          company: @retail,
          branch: branch,
          warehouse: branch_warehouse,
          product: product,
          code: "STKIM-#{SecureRandom.hex(4).upcase}",
          quantity: rand(10..100),
          business_type: StockImport.business_types.keys.sample,
          workflow_status: StockImport.workflow_statuses.keys.sample,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_stock_exports
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockExportService.create(
          company: @retail,
          branch: branch,
          warehouse: branch_warehouse,
          product: product,
          code: "STKEX-#{SecureRandom.hex(4).upcase}",
          quantity: rand(5..50),
          business_type: StockExport.business_types.keys.sample,
          workflow_status: StockExport.workflow_statuses.keys.sample,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_customer_orders
    @branches.each do |branch|
      branch_customers = @customers.select { |c| c.branch_id == branch.id }
      next if branch_customers.empty?

      5.times do |i|
        customer = branch_customers.sample
        order = Seed::OrderService.create(
          company: @retail, branch: branch, customer: customer, name: "Order #{i + 1} for #{customer.name}"
        )
        attach_items_to_order(branch, order)
      end
    end
  end

  def attach_items_to_order(branch, order)
    # Attach Products
    branch_products = @products.select { |p| p.branch_id == branch.id }
    branch_products.sample(rand(2..3)).each do |product|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(10.0..100.0).round(2), total_price: 0)
    end

    # Attach Services
    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..200.0).round(2), total_price: 0)
    end
  end

  def create_invoices
    puts "Creating invoices for orders..."
    @branches.each do |branch|
      branch_orders = Order.where(company: @retail, branch: branch)
      next if branch_orders.empty?

      branch_orders.sample(rand(3..5)).each do |order|
        Seed::InvoiceService.create(order: order)
      end
    end
    puts "  -> #{Invoice.where(company: @retail).count} invoices created"
  end

  def create_billing_data
    puts "Generating 7 days of billing history..."
    Seed::BillingDataService.create(company: @retail)
    puts "  -> Billing data generated (DailyMetricLog: #{DailyMetricLog.where(company: @retail).count}, " \
         "DailyFeatureLog: #{DailyFeatureLog.where(company: @retail).count}, " \
         "Invoices: #{BillingInvoice.where(company: @retail).count})"
  end

  def configure_retail_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  def create_all_crud_policies
    crud_actions = %w[create read update delete]

    @retail.resource_names.each do |resource|
      crud_actions.each do |action|
        create_policy(resource: resource, action: action)
      end
    end
  end

  def all_actions
    %w[create read update delete]
  end

  def create_policy(resource:, action:)
    policy_name = "Can #{action} #{resource}"
    Policy.find_or_create_by!(
      name: policy_name,
      company: @retail,
      resource: resource,
      action: action
    ) do |p|
      p.description = "Allows #{action} operations on #{resource}"
      p.business_type = :operational
      p.lifecycle_status = :active
      p.branch_id = @branches.first.id
    end
  end

  def assign_policies_to_roles
    role_definitions = {
      Admin: {
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: true, read: true, update: true, delete: false },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true }
      },
      Manager: {
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
        "Branch" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "Course" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Department" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Exam" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true },
        "Guest" => { create: true, read: true, update: true, delete: true },
        "Invoice" => { create: true, read: true, update: true, delete: true },
        "Membership" => { create: true, read: true, update: true, delete: true },
        "Order" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: true },
        "Payment" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: false, read: true, update: false, delete: false },
        "Product" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "Reservation" => { create: true, read: true, update: true, delete: true },
        "Room" => { create: true, read: true, update: true, delete: true },
        "Service" => { create: true, read: true, update: true, delete: true },
        "Stock" => { create: true, read: true, update: true, delete: true },
        "StockExport" => { create: true, read: true, update: true, delete: true },
        "StockImport" => { create: true, read: true, update: true, delete: true },
        "StockTransfer" => { create: true, read: true, update: true, delete: true },
        "Student" => { create: true, read: true, update: true, delete: true },
        "Table" => { create: true, read: true, update: true, delete: true }
      },
      Cashier: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Customer" => { create: true, read: true, update: false, delete: false },
        "Brand" => { create: false, read: true, update: false, delete: false }
      },
      Seller: {
        "Order" => { create: true, read: true, update: false, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Customer" => { create: false, read: true, update: false, delete: false },
        "Brand" => { create: false, read: true, update: false, delete: false }
      },
      Security: {
        "Product" => { create: false, read: true, update: false, delete: false },
        "Order" => { create: false, read: true, update: false, delete: false }
      },
      Doctor: {
        "Order" => { read: true, update: true },
        "Service" => { read: true },
        "Brand" => { create: false, read: true, update: false, delete: false },
        "Facility" => { create: true, read: true, update: true, delete: false }
      },
      Therapist: {
        "Order" => { read: true },
        "Facility" => { create: false, read: true, update: false, delete: false }
      },
      Consultant: {
        "Customer" => { create: true, read: true, update: true },
        "Order" => { create: true, read: true },
        "Brand" => { create: false, read: true, update: false, delete: false }
      }
    }

    role_definitions.each do |role_name, resources|
      role = Role.find_by(name: role_name, company: @retail)
      next unless role

      resources.each do |resource_name, actions_hash|
        actions_hash.each do |action, is_active|
          policy = Policy.find_by!(company: @retail, resource: resource_name, action: action)
          appointment = PolicyAppointment.find_or_create_by!(
            company: @retail,
            policy: policy,
            appoint_to: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end
