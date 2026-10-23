// app/javascript/controllers/helpers/enums.js
// Static enum definitions (moved out of client cache — enums rarely change).
// Source of truth for names/values lives in the Rails models; regenerate this
// file (pretty-printed) when a model enum changes.
const ENUMS = {
  "employee": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Owner",
        "value": "owner"
      },
      {
        "name": "Full time",
        "value": "full_time"
      },
      {
        "name": "Part time",
        "value": "part_time"
      },
      {
        "name": "Contractor",
        "value": "contractor"
      },
      {
        "name": "Intern",
        "value": "intern"
      }
    ]
  },
  "branch": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Storefront",
        "value": "storefront"
      },
      {
        "name": "Kiosk",
        "value": "kiosk"
      },
      {
        "name": "Showroom",
        "value": "showroom"
      },
      {
        "name": "Warehouse",
        "value": "warehouse"
      },
      {
        "name": "Distribution center",
        "value": "distribution_center"
      },
      {
        "name": "Dark store",
        "value": "dark_store"
      },
      {
        "name": "Service point",
        "value": "service_point"
      },
      {
        "name": "Clinic wing",
        "value": "clinic_wing"
      },
      {
        "name": "Classroom annex",
        "value": "classroom_annex"
      },
      {
        "name": "Headquarters",
        "value": "headquarters"
      },
      {
        "name": "Administrative",
        "value": "administrative"
      },
      {
        "name": "Virtual",
        "value": "virtual"
      }
    ]
  },
  "department": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Sales",
        "value": "sales"
      },
      {
        "name": "Marketing",
        "value": "marketing"
      },
      {
        "name": "Operations",
        "value": "operations"
      },
      {
        "name": "Finance",
        "value": "finance"
      },
      {
        "name": "Human resources",
        "value": "human_resources"
      },
      {
        "name": "Information technology",
        "value": "information_technology"
      },
      {
        "name": "Customer service",
        "value": "customer_service"
      },
      {
        "name": "Research and development",
        "value": "research_and_development"
      },
      {
        "name": "Legal",
        "value": "legal"
      },
      {
        "name": "Administrative",
        "value": "administrative"
      }
    ]
  },
  "brand": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Manufacturer",
        "value": "manufacturer"
      },
      {
        "name": "Retailer",
        "value": "retailer"
      },
      {
        "name": "Service provider",
        "value": "service_provider"
      },
      {
        "name": "Technology",
        "value": "technology"
      }
    ]
  },
  "facility": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Publicly traded",
        "value": "publicly_traded"
      },
      {
        "name": "Privately held",
        "value": "privately_held"
      }
    ]
  },
  "warehouse": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Main",
        "value": "main"
      },
      {
        "name": "Distribution",
        "value": "distribution"
      },
      {
        "name": "Fulfillment",
        "value": "fulfillment"
      },
      {
        "name": "Cold storage",
        "value": "cold_storage"
      }
    ]
  },
  "category": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "resource_names": [
      "products",
      "employees",
      "branches",
      "departments",
      "brands",
      "suppliers",
      "customers",
      "services",
      "facilities"
    ]
  },
  "product": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Physical",
        "value": "physical"
      },
      {
        "name": "Digital",
        "value": "digital"
      },
      {
        "name": "Service based",
        "value": "service_based"
      }
    ]
  },
  "service": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "B2b",
        "value": "b2b"
      },
      {
        "name": "B2c",
        "value": "b2c"
      }
    ]
  },
  "order": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Online",
        "value": "online"
      },
      {
        "name": "In store",
        "value": "in_store"
      },
      {
        "name": "Phone",
        "value": "phone"
      }
    ],
    "currencies": [
      {
        "name": "Usd",
        "value": "usd"
      },
      {
        "name": "Vnd",
        "value": "vnd"
      }
    ]
  },
  "customer": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Individual",
        "value": "individual"
      },
      {
        "name": "Small business",
        "value": "small_business"
      },
      {
        "name": "Enterprise",
        "value": "enterprise"
      }
    ]
  },
  "invoice": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Sales",
        "value": "sales"
      },
      {
        "name": "Service",
        "value": "service"
      },
      {
        "name": "Subscription",
        "value": "subscription"
      }
    ],
    "currencies": [
      {
        "name": "Usd",
        "value": "usd"
      },
      {
        "name": "Vnd",
        "value": "vnd"
      }
    ]
  },
  "company": {
    "business_types": [
      {
        "name": "Retail",
        "value": "retail"
      },
      {
        "name": "Restaurant",
        "value": "restaurant"
      },
      {
        "name": "Hospital",
        "value": "hospital"
      },
      {
        "name": "Education",
        "value": "education"
      },
      {
        "name": "Hotel",
        "value": "hotel"
      },
      {
        "name": "Fitness",
        "value": "fitness"
      },
      {
        "name": "System",
        "value": "system"
      }
    ]
  },
  "stock": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Inventory",
        "value": "inventory"
      },
      {
        "name": "Raw material",
        "value": "raw_material"
      },
      {
        "name": "Finished good",
        "value": "finished_good"
      },
      {
        "name": "Return",
        "value": "return"
      }
    ]
  },
  "stock_transfer": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Transfer",
        "value": "transfer"
      },
      {
        "name": "Adjustment",
        "value": "adjustment"
      },
      {
        "name": "Return",
        "value": "return"
      },
      {
        "name": "Exchange",
        "value": "exchange"
      }
    ]
  },
  "stock_import": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Purchase",
        "value": "purchase"
      },
      {
        "name": "Return",
        "value": "return"
      },
      {
        "name": "Transfer in",
        "value": "transfer_in"
      },
      {
        "name": "Adjustment",
        "value": "adjustment"
      }
    ]
  },
  "stock_export": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Sale",
        "value": "sale"
      },
      {
        "name": "Transfer out",
        "value": "transfer_out"
      },
      {
        "name": "Return to supplier",
        "value": "return_to_supplier"
      },
      {
        "name": "Adjustment",
        "value": "adjustment"
      },
      {
        "name": "Damaged",
        "value": "damaged"
      },
      {
        "name": "Expired",
        "value": "expired"
      }
    ]
  },
  "supplier": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Manufacturer",
        "value": "manufacturer"
      },
      {
        "name": "Distributor",
        "value": "distributor"
      },
      {
        "name": "Wholesaler",
        "value": "wholesaler"
      },
      {
        "name": "Service provider",
        "value": "service_provider"
      }
    ]
  },
  "purchase": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Pending",
        "value": "pending"
      },
      {
        "name": "Confirmed",
        "value": "confirmed"
      },
      {
        "name": "In progress",
        "value": "in_progress"
      },
      {
        "name": "Completed",
        "value": "completed"
      },
      {
        "name": "Paid",
        "value": "paid"
      },
      {
        "name": "Cancelled",
        "value": "cancelled"
      },
      {
        "name": "Refunded",
        "value": "refunded"
      },
      {
        "name": "Failed",
        "value": "failed"
      },
      {
        "name": "Initiated",
        "value": "initiated"
      },
      {
        "name": "Received",
        "value": "received"
      },
      {
        "name": "Shipped",
        "value": "shipped"
      }
    ],
    "business_types": [
      {
        "name": "Office supply",
        "value": "office_supply"
      },
      {
        "name": "Equipment",
        "value": "equipment"
      },
      {
        "name": "Service",
        "value": "service"
      }
    ],
    "currencies": [
      {
        "name": "Usd",
        "value": "usd"
      },
      {
        "name": "Vnd",
        "value": "vnd"
      }
    ]
  },
  "document": {
    "lifecycle_statuses": [
      {
        "name": "Active",
        "value": "active"
      },
      {
        "name": "Inactive",
        "value": "inactive"
      },
      {
        "name": "Archived",
        "value": "archived"
      },
      {
        "name": "Deleted",
        "value": "deleted"
      }
    ],
    "workflow_statuses": [
      {
        "name": "Draft",
        "value": "draft"
      },
      {
        "name": "Published",
        "value": "published"
      },
      {
        "name": "Archived",
        "value": "archived"
      }
    ],
    "business_types": [
      {
        "name": "General",
        "value": "general"
      },
      {
        "name": "Policy",
        "value": "policy"
      },
      {
        "name": "Guide",
        "value": "guide"
      },
      {
        "name": "Announcement",
        "value": "announcement"
      }
    ]
  },
  "workflow": {
    "process_types": [
      {
        "name": "Purchase process",
        "value": "purchase_process"
      },
      {
        "name": "Leave process",
        "value": "leave_process"
      },
      {
        "name": "Ticket process",
        "value": "ticket_process"
      }
    ]
  }
}

export { ENUMS }
