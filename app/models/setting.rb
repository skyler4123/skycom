class Setting < ApplicationRecord
  belongs_to :setting_group
  belongs_to :company_group
  belongs_to :company
end
