# frozen_string_literal: true

class PayrollConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  store_accessor :metadata,
    :date_basis,
    :include_attendance_months,
    :include_attendance_days,
    :branch_ids,
    :employee_ids,
    :excluded_lifecycle_statuses,
    :excluded_workflow_statuses,
    :business_types
  belongs_to :company

  validates :company_id, uniqueness: true


  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.metadata = {} if metadata.blank?
    self.date_basis = "month" if date_basis.blank?
    self.include_attendance_months = true if include_attendance_months.nil?
    self.include_attendance_days = false if include_attendance_days.nil?
    self.branch_ids = [] if branch_ids.nil?
    self.employee_ids = [] if employee_ids.nil?
    self.excluded_lifecycle_statuses = [] if excluded_lifecycle_statuses.nil?
    self.excluded_workflow_statuses = [] if excluded_workflow_statuses.nil?
    self.business_types = [] if business_types.nil?
  end

  def self.for_company!(company)
    find_by(company: company) || begin
      create!(company: company)
    rescue ActiveRecord::RecordNotUnique
      find_by!(company: company)
    end
  end
end
