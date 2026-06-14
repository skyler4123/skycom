class Page < ApplicationRecord
  belongs_to :company
  belongs_to :branch

  enum :business_type, {
    retail: 10,
    restaurant: 20,
    hospital: 30,
    education: 40
  }, prefix: true

  # Unified target role mapping
  enum :target_role, {
    # Retail Roles
    retail_cashier: 110,
    retail_store_manager: 120,

    # Restaurant Roles
    restaurant_cashier: 210,
    restaurant_waiter: 220,
    restaurant_kitchen_staff: 230,

    # Hospital Roles
    hospital_receptionist: 310,
    hospital_doctor: 320,
    hospital_nurse: 330
  }

  enum :target_resolution, {
    mobile_portrait: 10,    # Waiter taking orders at a table
    tablet_landscape: 20,   # Quick-service restaurant counter or hotel check-in
    desktop_widescreen: 30  # Heavy-duty Retail POS or Hospital Receptionist board
  }, prefix: true

  enum :lifecycle_status, { active: 10, draft: 20, archived: 30 }, prefix: true
  enum :workflow_status, { pending_review: 10, approved: 20, deployed: 30 }, prefix: true
end
