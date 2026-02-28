class Setting < ApplicationRecord
  include TagConcern

  belongs_to :setting_group
  belongs_to :company
  belongs_to :branch, optional: true
end
