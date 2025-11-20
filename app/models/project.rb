class Project < ApplicationRecord
  belongs_to :company
  belongs_to :project_group
end
