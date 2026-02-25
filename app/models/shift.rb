class Shift < ApplicationRecord
  belongs_to :company_group
  belongs_to :branch, optional: true
  belongs_to :period
end
