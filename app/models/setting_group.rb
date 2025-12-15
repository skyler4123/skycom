class SettingGroup < ApplicationRecord
  belongs_to :company_group
  belongs_to :company
end
