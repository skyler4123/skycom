class TagAppointment < ApplicationRecord
  # --- Associations ---
  belongs_to :tag
  belongs_to :appoint_to, polymorphic: true

  # --- Validations ---

  # Ensure all necessary references are present
  validates :tag, presence: true
  validates :appoint_to, presence: true
  
  # The value of the tag is often required, but may be optional depending on your needs.
  # Assuming the value is important for the tag's purpose:
  # validates :value, presence: true

  # CRITICAL: Enforce the "AWS-style" uniqueness constraint.
  # A single resource (appoint_to) can only be linked to a specific Tag (tag_id) once.
  # This prevents an Employee from having the same tag name twice, even with different values.
  validates :tag_id, 
            uniqueness: { 
              scope: [:appoint_to_type, :appoint_to_id],
              message: "This resource is already tagged with this specific key (tag name)."
            }
end
