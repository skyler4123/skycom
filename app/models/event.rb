class Event < ApplicationRecord
  belongs_to :event_group
  belongs_to :company_group
  belongs_to :company
end
