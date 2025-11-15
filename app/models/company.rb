class Company < ApplicationRecord
  belongs_to :user

  has_many :tags, dependent: :destroy
  has_many :employee_groups, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :policies, dependent: :destroy

  has_many :child_companies, class_name: "Company", foreign_key: "parent_company_id", dependent: :destroy
  belongs_to :parent_company, class_name: "Company", optional: true

end
