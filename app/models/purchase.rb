class Purchase < ApplicationRecord
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
end
