# frozen_string_literal: true

# KpiConfig — Atomic purpose: one company-defined employee KPI rule.
#
# Why it exists: companies measure different things (orders sold, revenue, later
# tasks/projects). The rule — metric + target + weight + period + scope — is
# data, so owner can change it without a deploy.
# How it works: metric_key resolves through Kpi::Metrics; ScorecardService and
# LeaderboardService compute actuals on demand (no result snapshots). Optional
# category/branch/department/role IDs narrow which employees the rule applies
# to; all blank means every employee in the company.
# Main associations: belongs_to :company; optional :category, :branch,
# :department, :role.
class KpiConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, { inactive: 0, active: 1 }, prefix: true, default: :active
  enum :business_type, { performance: 0 }, prefix: true, default: :performance
  enum :direction, { higher_better: 0, lower_better: 1 }, prefix: true, default: :higher_better
  enum :period_type, { month: 0, quarter: 1, year: 2 }, prefix: true, default: :month

  # --- Associations ---
  belongs_to :company
  belongs_to :category, optional: true
  belongs_to :branch, optional: true
  belongs_to :department, optional: true
  belongs_to :role, optional: true

  scope :active, -> { where(workflow_status: :active, discarded_at: nil) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :metric_key, presence: true, inclusion: { in: ->(_) { Kpi::Metrics.keys } }
  validates :direction, presence: true
  validates :period_type, presence: true
  validates :weight, numericality: { greater_than: 0 }
  validates :target_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :scoped_records_belong_to_company

  def metric
    Kpi::Metrics.find(metric_key)
  end

  def applies_to?(employee)
    return false unless employee.company_id == company_id
    return false if category_id.present? && employee.category_id != category_id
    return false if branch_id.present? && employee.branch_id != branch_id

    if department_id.present?
      return false unless employee.department_employee_appointments.any? do |appointment|
        appointment.department_id == department_id && appointment.discarded_at.nil?
      end
    end

    if role_id.present?
      return false unless employee.employee_role_appointments.any? do |appointment|
        appointment.role_id == role_id && appointment.discarded_at.nil?
      end
    end

    true
  end

  private

  def scoped_records_belong_to_company
    %i[category branch department role].each do |association|
      record = public_send(association)
      next if record.nil? || company_id.nil? || record.company_id == company_id

      errors.add(association, "must belong to the same company")
    end
  end
end
