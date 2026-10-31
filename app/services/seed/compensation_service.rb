# frozen_string_literal: true

# Seed-only HR setup: branch teams, reporting lines, salary/allowance, and
# contract renewal dates for every employee of a company. Called from the enrich
# services.
class Seed::CompensationService
  LEADERSHIP_GROUP_NAME = "Leadership"

  # Monthly salary in cents by currency and role tier.
  SALARY_TIERS = {
    usd: {
      owner: 9_000 * 100,
      manager: 6_000 * 100,
      admin: 5_000 * 100,
      staff: 3_500 * 100,
      intern: 1_200 * 100
    },
    vnd: {
      owner: 60_000_000 * 100,
      manager: 40_000_000 * 100,
      admin: 30_000_000 * 100,
      staff: 18_000_000 * 100,
      intern: 6_000_000 * 100
    }
  }.freeze

  ALLOWANCE_RATE = 0.08
  CONTRACT_MONTHS = (3..18).freeze

  def self.assign!(company:)
    new(company: company).call
  end

  def initialize(company:)
    @company = company
    @owner = company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
  end

  def call
    attach_owner_to_first_branch
    assign_teams

    @company.employees.find_each do |employee|
      assign_compensation(employee)
    end

    @company.employees.count
  end

  private

  def attach_owner_to_first_branch
    return if @owner.nil? || @owner.branch_id.present?

    branch = @company.branches.order(:created_at).first
    @owner.update!(branch: branch) if branch
  end

  def assign_teams
    managers_by_branch = branch_managers
    covered_employee_ids = []

    @company.branches.order(:created_at).find_each do |branch|
      members = @company.employees.where(branch: branch).where.not(id: @owner&.id).to_a
      next if members.empty?

      manager = managers_by_branch[branch.id]&.first || @owner
      team = Seed::EmployeeGroupService.find_or_create!(
        company: @company,
        name: "#{branch.name} Team",
        branch: branch,
        manager: manager
      )
      enroll(team, members + [ manager ])
      covered_employee_ids.concat(members.map(&:id))
      covered_employee_ids << manager.id if manager
    end

    leadership = Seed::EmployeeGroupService.find_or_create!(
      company: @company,
      name: LEADERSHIP_GROUP_NAME,
      branch: @owner&.branch,
      manager: @owner
    )
    leaders = managers_by_branch.values.map(&:first)
    leftovers = @company.employees.where.not(id: covered_employee_ids.uniq)
    enroll(leadership, leaders + [ @owner ] + leftovers.to_a)
  end

  def enroll(employee_group, employees)
    employees.compact.uniq.each do |employee|
      EmployeeEmployeeGroupAppointment.find_or_create_by!(
        company: @company,
        employee: employee,
        employee_group: employee_group
      )
    end
  end

  def branch_managers
    @company.employees
      .joins(:roles)
      .where(roles: { name: "Manager" })
      .group_by(&:branch_id)
  end

  def assign_compensation(employee)
    salary = salary_for(employee)
    employee.assign_attributes(
      monthly_salary_cents: salary,
      monthly_allowance_cents: (salary * ALLOWANCE_RATE).round,
      expiration_date: employee.expiration_date || Date.current + rand(CONTRACT_MONTHS).months
    )
    employee.save! if employee.changed?
  end

  def salary_for(employee)
    currency = salary_currency(employee)
    SALARY_TIERS.fetch(currency).fetch(salary_tier(employee))
  end

  def salary_currency(employee)
    return @company.currency.to_sym if employee.owner? && @company.currency.present?

    currency = employee.currency.to_sym
    SALARY_TIERS.key?(currency) ? currency : :usd
  end

  def salary_tier(employee)
    return :owner if employee.owner?
    return :manager if employee.has_role?("Manager")
    return :admin if employee.has_role?("Admin")
    return :intern if employee.intern?

    :staff
  end
end
