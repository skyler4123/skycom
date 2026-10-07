class Notification < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company

  # --- Validations ---
  validates :title, presence: true
end
