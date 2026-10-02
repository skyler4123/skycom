class EventConfig < ApplicationRecord
  # Per-category rule holder for the Event domain (config-style: no dynamic
  # property slots, no CategoryConcern — the Workflow/DiscountGroup precedent).
  #
  # Why it exists: different event types need different mechanics — a banquet
  # holds stock and bills an order, a standup meeting needs neither. One row
  # per company + category answers: hold stock? block or warn when a hold
  # fails? create an order on completion? warn on double-booked facilities
  # or hosts?
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :category

  validates :category_id, uniqueness: { scope: :company_id }
end
