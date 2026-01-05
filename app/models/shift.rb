class Shift < ApplicationRecord
  belongs_to :company_group
  belongs_to :company
  belongs_to :period
end
