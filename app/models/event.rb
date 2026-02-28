class Event < ApplicationRecord
  include TagConcern

  belongs_to :event_group
  belongs_to :company
  belongs_to :branch, optional: true
end
