class AttendanceRequest < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, { pending: 0, approved: 1, rejected: 2 }, prefix: true, default: :pending
  enum :business_type, { onsite_miss: 0, remote_work: 1, field_work: 2 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :decided_by, class_name: "Employee", optional: true

  # --- Validations ---
  validates :attendance_date, presence: true
  validates :check_in, presence: true
  validates :reason, presence: true
  validate :attendance_date_not_in_future
  validate :check_out_after_check_in
  validate :only_one_live_request_per_employee_date, on: :create
  validate :employee_belongs_to_company

  # The AttendanceDay created on approval (nil until approved).
  def attendance_day
    AttendanceDay.find_by(company_id: company_id, employee_id: employee_id, attendance_date: attendance_date)
  end

  private

  def attendance_date_not_in_future
    return if attendance_date.blank?
    return unless attendance_date > Date.current

    errors.add(:attendance_date, "cannot be in the future")
  end

  def check_out_after_check_in
    return if check_out.blank? || check_in.blank?
    return if check_out > check_in

    errors.add(:check_out, "must be after check in")
  end

  def only_one_live_request_per_employee_date
    return if company_id.blank? || employee_id.blank? || attendance_date.blank?

    exists = AttendanceRequest.where(
      company_id: company_id, employee_id: employee_id, attendance_date: attendance_date, discarded_at: nil
    ).where.not(id: id).exists?
    errors.add(:attendance_date, "already has a request for this employee and date") if exists
  end

  def employee_belongs_to_company
    return if employee.blank? || company_id.blank?
    return if employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end
end
