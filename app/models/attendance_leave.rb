# frozen_string_literal: true

class AttendanceLeave < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :leave_type, { paid: 0, sick: 1, unpaid: 2 }
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :decided_by, class_name: "Employee", optional: true

  # --- Scopes ---
  scope :for_year, ->(year) { where(start_date: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }

  # --- Validations ---
  validates :start_date, :end_date, presence: true
  validates :days, numericality: { greater_than: 0 }
  validate :end_date_after_start_date
  validate :employee_belongs_to_company
  validate :branch_belongs_to_company

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start date")
  end

  def employee_belongs_to_company
    return if employee.blank? || company_id.blank?
    return if employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end

  def branch_belongs_to_company
    return if branch.blank? || company_id.blank?
    return if branch.company_id == company_id

    errors.add(:branch, "must belong to the same company")
  end
end
