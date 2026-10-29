# frozen_string_literal: true

# Seed-only paid-leave data: one balance per employee plus approved/pending
# requests so the mobile Home card is driven by real records.
class Seed::LeaveService
  ENTITLED_DAYS = 14.0
  APPROVED_DAYS = [ 2.0, 1.0 ].freeze
  PENDING_EVERY = 3

  def self.create_samples!(company:)
    new(company: company).call
  end

  def initialize(company:)
    @company = company
    @employees = company.employees.order(:created_at).to_a
  end

  def call
    @employees.each_with_index do |employee, index|
      create_balance(employee)
      create_request(employee, status: :approved, offset: index * 11 + 5, days: APPROVED_DAYS[index % APPROVED_DAYS.size])
      create_request(employee, status: :approved, offset: index * 11 + 30, days: 1.0)
      create_request(employee, status: :pending, offset: index * 11 + 60, days: 1.0) if (index % PENDING_EVERY).zero?
    end
  end

  private

  def create_balance(employee)
    balance = LeaveBalance.find_or_initialize_by(employee: employee, year: Date.current.year)
    balance.company = @company
    balance.entitled_days = ENTITLED_DAYS
    balance.save! if balance.changed?
  end

  def create_request(employee, status:, offset:, days:)
    date = request_date(offset)
    request = LeaveRequest.find_or_initialize_by(employee: employee, leave_type: :paid, start_date: date)
    request.assign_attributes(
      company: @company,
      branch: employee.branch,
      end_date: date + (days.to_i - 1).days,
      days: days,
      status: status,
      reason: status == :pending ? "Upcoming personal leave" : "Seeded paid leave",
      decided_by: status == :approved ? approver_for(employee) : nil
    )
    request.save! if request.changed?
  end

  def approver_for(employee)
    employee.manager || @company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
  end

  def request_date(offset)
    date = Date.current.beginning_of_year + (offset % 300).days
    date = Date.current - 1.day if date >= Date.current
    date += 1.day while date.saturday? || date.sunday?
    date
  end
end
