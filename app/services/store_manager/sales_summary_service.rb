# frozen_string_literal: true

# StoreManager::SalesSummaryService — the one sales formula for the Store
# Manager console, its cashier cards and the close sheet.
#
# Gross sales is the sum of paid invoice totals for the branch's calendar day
# (tax and order-level adjustments included). Tender/cash figures come from the
# completed transactions on those invoices. The same service is called for
# yesterday, so the comparison cannot use a different formula.
#
# Docs: docs/MONEY_FLOW.md, docs/business_analysis/06-store-manager.md
class StoreManager::SalesSummaryService
  CANCELLED_STATUSES = %w[cancelled refunded].freeze

  def self.call(company:, branch:, date:)
    new(company: company, branch: branch, date: date).call
  end

  def initialize(company:, branch:, date:)
    @company = company
    @branch = branch
    @date = date.to_date
  end

  def call
    {
      gross_sales_cents: gross_sales_cents,
      orders_count: paid_orders_count,
      discounts_cents: discounts_cents,
      tax_cents: tax_cents,
      cash_sales_cents: tender_totals.fetch("cash", 0),
      qr_sales_cents: tender_totals.fetch("qr", 0),
      other_sales_cents: tender_totals.fetch("other", 0),
      cash_received_cents: cash_received_cents,
      change_cents: change_cents,
      tender_lines: tender_lines,
      cashiers: cashiers,
      unassigned_orders_count: unassigned_orders_count
    }
  end

  private

  attr_reader :company, :branch, :date

  def day_range
    @day_range ||= LocalTime.day_range(date, branch)
  end

  def cancelled_order_statuses
    Order.workflow_statuses.values_at(*CANCELLED_STATUSES)
  end

  def paid_invoices
    @paid_invoices ||= company.invoices
      .joins(:order)
      .where(branch_id: branch.id, payment_status: :paid, discarded_at: nil, credited_invoice_id: nil)
      .where(orders: {
        branch_id: branch.id,
        created_at: day_range,
        discarded_at: nil
      })
      .where.not(orders: { workflow_status: cancelled_order_statuses })
      .includes(:discounts, transactions: :payment_method, order: [ :employee, :invoices ])
      .to_a
  end

  def paid_order_ids
    @paid_order_ids ||= paid_invoices.map(&:order_id).uniq
  end

  def paid_orders_count
    paid_order_ids.length
  end

  def gross_sales_cents
    @gross_sales_cents ||= paid_invoices.sum { |invoice| invoice_total_cents(invoice) }
  end

  def discounts_cents
    @discounts_cents ||= paid_invoices.sum do |invoice|
      invoice.discounts.select(&:used?).sum { |discount| discount.amount_cents.to_i }
    end
  end

  def tax_cents
    @tax_cents ||= paid_invoices.sum { |invoice| invoice.tax_cents.to_i }
  end

  def completed_transactions
    @completed_transactions ||= paid_invoices.flat_map do |invoice|
      invoice.transactions.select(&:completed?)
    end
  end

  def tender_totals
    @tender_totals ||= completed_transactions.each_with_object(Hash.new(0)) do |transaction, totals|
      totals[tender_key(transaction)] += transaction.price_cents.to_i
    end
  end

  def cash_transactions
    @cash_transactions ||= completed_transactions.select { |transaction| tender_key(transaction) == "cash" }
  end

  def cash_received_cents
    @cash_received_cents ||= cash_transactions.sum do |transaction|
      transaction.cash_received_cents.presence&.to_i || transaction.price_cents.to_i
    end
  end

  def change_cents
    @change_cents ||= cash_transactions.sum { |transaction| transaction.change_cents.to_i }
  end

  def tender_lines
    [
      { key: "cash", label: "Cash", amount_cents: tender_totals.fetch("cash", 0) },
      { key: "qr", label: "QR", amount_cents: tender_totals.fetch("qr", 0) },
      { key: "other", label: "Other", amount_cents: tender_totals.fetch("other", 0) }
    ].select { |line| line[:amount_cents].positive? }
  end

  def cashiers
    @cashiers ||= begin
      rows = paid_invoices.group_by { |invoice| invoice.order.employee }.filter_map do |employee, invoices|
        next if employee.nil?

        {
          employee_id: employee.id,
          name: employee.name,
          role: employee_role(employee),
          sales_cents: invoices.sum { |invoice| invoice_total_cents(invoice) },
          orders_count: invoices.map(&:order_id).uniq.length
        }
      end

      rows.sort_by { |row| [ -row[:sales_cents], row[:name].to_s ] }
    end
  end

  def unassigned_orders_count
    @unassigned_orders_count ||= paid_invoices
      .select { |invoice| invoice.order.employee_id.nil? }
      .map(&:order_id)
      .uniq
      .length
  end

  def employee_role(employee)
    role = employee.category&.name.presence
    return nil if role.blank? || role == "Employees"

    role
  end

  def tender_key(transaction)
    case transaction.payment_method&.payment_mode
    when "cash" then "cash"
    when "qr" then "qr"
    else "other"
    end
  end

  def invoice_total_cents(invoice)
    total = invoice.total_cents.to_i
    total.positive? ? total : invoice.price_cents.to_i
  end
end
