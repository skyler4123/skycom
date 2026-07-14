# app/models/membership.rb
class Membership < ApplicationRecord
  attribute :metadata, :jsonb, array: true, default: []
  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  include CategoryConcern
  include PropertyMappingConcern
  include ImmutableRecordConcern

  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true

  enum :business_type, { loyalty: 1, subscription: 2, segment: 3 }

  has_many :membership_appointments, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end
