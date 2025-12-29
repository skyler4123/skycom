class Subscription < ApplicationRecord
  include ImmutableRecordConcern
  # Assuming you use Discard for the 'discarded_at' column in migration
  # include Discard::Model

  # --- Associations ---
  belongs_to :subscription_group, optional: true
  belongs_to :price
  belongs_to :period

  # A plan has many instances (appointments)
  has_many :subscription_appointments, dependent: :restrict_with_error

  # --- Validations ---
  validates :tier, presence: true

  # Ensure the definition components are always present
  validates :price, :period, presence: true

  enum :country_code, COUNTRIE_CODES, prefix: true

end
