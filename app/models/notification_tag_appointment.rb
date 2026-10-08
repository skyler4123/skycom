class NotificationTagAppointment < ApplicationRecord
  # Publish link — atomic pairwise row binding one NotificationTag to its notification.
  #
  # Why it exists: a system-generated notification broadcasts to tag audiences;
  # this table records WHICH tags it was published to.
  # How to use: created by Notifications::CreateService via bulk insert; read via
  # `notification.notification_tags`.
  # How it works: company_id derives from the notification via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :notification
  belongs_to :notification_tag

  # --- Validations ---
  validates :notification_id, uniqueness: { scope: [ :company_id, :notification_tag_id ] }
end
