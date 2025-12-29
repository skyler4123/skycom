class SubscriptionGroup < ApplicationRecord
  include ImmutableRecordConcern
  # Assuming you use Discard for the 'discarded_at' column in migration
  # include Discard::Model 

  # --- Associations ---
  belongs_to :price
  belongs_to :period
  
  # A plan has many instances (appointments)
  has_many :subscription_group_appointments, dependent: :restrict_with_error

  # --- Validations ---
  validates :name, presence: true
  validates :code, uniqueness: true, allow_blank: true
  
  # Ensure the definition components are always present
  validates :price, :period, presence: true
end
