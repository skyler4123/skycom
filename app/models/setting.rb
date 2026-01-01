class Setting < ApplicationRecord
  include TagConcern

  belongs_to :setting_group
  belongs_to :company_group
  belongs_to :company
end
