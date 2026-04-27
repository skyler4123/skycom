class EventGroup < ApplicationRecord
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
end
