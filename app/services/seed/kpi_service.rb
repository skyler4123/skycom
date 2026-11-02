# frozen_string_literal: true

# Seed-only KPI demo data: one company-wide orders-sold rule plus paid orders
# attributed to employees, so the owner's Performance page is never empty.
# One order per branch is credited to the owner; remaining orders go to staff
# round-robin, and one stays unattributed so the leaderboard's unattributed
# banner remains visible.
class Seed::KpiService
  CONFIG_NAME = "Orders sold"
  TARGET_ORDERS = 5
  OWNER_PAID_ORDERS_PER_BRANCH = 1
  PAID_ORDER_EVERY = 2

  def self.create_samples!(company:)
    new(company: company).call
  end

  def initialize(company:)
    @company = company
    @owner = company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
    @employees = company.employees.where(discarded_at: nil).order(:created_at).to_a
  end

  def call
    create_config
    attribute_orders
  end

  private

  attr_reader :company, :owner, :employees

  def create_config
    KpiConfig.find_or_create_by!(company: company, name: CONFIG_NAME) do |config|
      config.metric_key = "orders_count"
      config.direction = :higher_better
      config.period_type = :month
      config.target_value = TARGET_ORDERS
      config.weight = 1
      config.lifecycle_status = :active
      config.workflow_status = :active
      config.business_type = :performance
    end
  end

  def attribute_orders
    return if owner.nil? || employees.empty?

    orders = company.orders.where(discarded_at: nil).order(:created_at).to_a
    return if orders.empty?

    owner_orders = owner_orders_for(orders)
    attribute_to_owner(owner_orders)
    attribute_to_staff(orders - owner_orders)
  end

  def owner_orders_for(orders)
    branches = company.branches.order(:created_at).to_a

    if branches.empty?
      return [] if owner_has_paid_order?(orders)
      return orders.select { |order| order.employee_id.nil? }.first(OWNER_PAID_ORDERS_PER_BRANCH)
    end

    branches.filter_map do |branch|
      next if owner_has_paid_order_in?(orders, branch)

      orders.find { |order| order.branch_id == branch.id && order.employee_id.nil? }
    end
  end

  def owner_has_paid_order?(orders)
    orders.any? { |order| order.employee_id == owner.id && order.workflow_status_paid? }
  end

  def owner_has_paid_order_in?(orders, branch)
    orders.any? do |order|
      order.branch_id == branch.id &&
        order.employee_id == owner.id &&
        order.workflow_status_paid?
    end
  end

  def attribute_to_owner(owner_orders)
    owner_orders.each do |order|
      order.update!(employee: owner, workflow_status: :paid)
    end
  end

  def attribute_to_staff(orders)
    return if orders.empty? || staff.empty?

    unattributed = orders.reverse.find { |order| order.employee_id.nil? }

    orders.each_with_index do |order, index|
      next if order.id == unattributed&.id # keep one order unattributed for the demo banner
      next if order.employee_id.present?

      attributes = { employee: staff[index % staff.length] }
      attributes[:workflow_status] = :paid if (index % PAID_ORDER_EVERY).zero?
      order.update!(attributes)
    end
  end

  def staff
    @staff ||= employees.reject { |employee| employee.id == owner.id }
  end
end
