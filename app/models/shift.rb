class Shift < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :period
end
