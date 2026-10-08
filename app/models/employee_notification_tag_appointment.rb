class EmployeeNotificationTagAppointment < ApplicationRecord
  # Subscription link — atomic pairwise row binding one NotificationTag to its subscriber.
  #
  # Why it exists: an employee listens to notifications via shared tags (never a
  # direct employee↔notification link); this table records the subscription.
  # How to use: created from the notification settings UI; read via
  # `employee.subscribed_notification_tags`.
  # How it works: company_id derives from the employee via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :notification_tag

  # --- Validations ---
  validates :employee_id, uniqueness: { scope: [ :company_id, :notification_tag_id ] }
end
