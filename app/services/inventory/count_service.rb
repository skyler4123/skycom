# frozen_string_literal: true

# Inventory::CountService — the Count sheet's write path. Starts a cycle count
# for one warehouse (snapshotting expected quantities), saves progress, and
# submits variances through StockAdjustment rows so the ledger matches the
# counted numbers.
# Docs: docs/STOCK.md §4.7, docs/business_analysis/05-inventory.md §7
class Inventory::CountService
  def self.start(company:, warehouse:, employee:, notes: nil)
    new(company: company, warehouse: warehouse, employee: employee).start(notes: notes)
  end

  def self.show(company:, warehouse:, count_id:)
    new(company: company, warehouse: warehouse, employee: nil).show(count_id: count_id)
  end

  def self.save_progress(company:, warehouse:, count_id:, lines:, employee: nil)
    new(company: company, warehouse: warehouse, employee: employee).save_progress(count_id: count_id, lines: lines)
  end

  def self.submit(company:, warehouse:, employee:, count_id:, lines: [])
    new(company: company, warehouse: warehouse, employee: employee).submit(count_id: count_id, lines: lines)
  end

  def self.serialize(count, with_lines: false)
    new(company: count.company, warehouse: count.warehouse, employee: nil).serialize(count, with_lines: with_lines)
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def start(notes: nil)
    count = nil
    line_count = 0

    Warehouse.find(warehouse.id).with_lock do
      existing = company.stock_counts.where(warehouse_id: warehouse.id).open_counts.recent_first.first
      raise Inventory::Error, "A count is already in progress for this warehouse." if existing.present?

      stocks = company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil).order(:name).to_a
      raise Inventory::Error, "There are no stock rows to count in this warehouse." if stocks.empty?

      count = company.stock_counts.create!(
        company: company,
        warehouse: warehouse,
        created_by_employee: employee,
        count_type: :cycle,
        status: :in_progress,
        started_at: Time.current,
        scheduled_on: Date.current,
        notes: notes.presence
      )

      stocks.each do |stock|
        count.stock_count_lines.create!(
          company: company,
          stock: stock,
          expected_quantity: stock.quantity.to_i
        )
      end
      line_count = stocks.length
    end

    {
      message: "Count started · #{line_count} rows.",
      count: serialize(count, with_lines: true)
    }
  end

  def show(count_id:)
    count = find_count!(count_id)
    { count: serialize(count, with_lines: true) }
  end

  def save_progress(count_id:, lines:)
    count = find_count!(count_id)
    ensure_open!(count)
    apply_lines!(count, lines)

    {
      message: "Count progress saved.",
      count: serialize(count, with_lines: true)
    }
  end

  def submit(count_id:, lines: [])
    count = find_count!(count_id)
    ensure_open!(count)
    apply_lines!(count, lines) if lines.present?

    errors = []
    adjusted = 0

    count.stock_count_lines.includes(:stock).where.not(counted_quantity: nil).find_each do |line|
      stock = line.stock
      target = line.counted_quantity.to_i
      reserved = stock.pending.to_i

      if target < reserved
        errors << "#{item_name(stock)}: on hand cannot be less than the #{reserved} reserved."
        next
      end

      delta = target - stock.quantity.to_i
      next if delta.zero?

      begin
        ActiveRecord::Base.transaction do
          adjustment = build_adjustment(count, stock, delta)
          adjustment.save!
          adjustment.stock_adjustment_stock_appointments.create!(
            company: company,
            stock: stock,
            quantity: delta.abs
          )
          StockMovementService::Adjustments::CreateService.execute!(document: adjustment, employee: employee)
        end
        adjusted += 1
      rescue StockMovementService::Error, ActiveRecord::RecordInvalid => e
        errors << "#{item_name(stock)}: #{e.message}"
      end
    end

    metadata = (count.metadata || {}).merge(
      "completed_by_name" => employee&.name,
      "failed_lines" => errors
    )
    count.update!(status: :completed, completed_at: Time.current, metadata: metadata)

    {
      message: submit_message(adjusted, errors),
      errors: errors,
      count: serialize(count, with_lines: false)
    }
  end

  def serialize(count, with_lines: false)
    payload = {
      id: count.id,
      status: count.status,
      status_label: count.status.to_s.humanize,
      date: (count.started_at || count.created_at).iso8601,
      started_at: count.started_at&.iso8601,
      completed_at: count.completed_at&.iso8601,
      employee_name: count.metadata&.dig("completed_by_name").presence || count.created_by_employee&.name,
      rows_counted: count.rows_counted,
      rows_total: count.rows_total,
      net_variance: count.variance_quantity,
      failed_count: Array(count.metadata&.dig("failed_lines")).size
    }
    return payload unless with_lines

    points = reorder_points_for(count)
    payload.merge(
      lines: count.stock_count_lines.includes(:stock).map { |line| serialize_line(line, points) }
        .sort_by { |line| [ line[:name].to_s.downcase, line[:code].to_s ] }
    )
  end

  private

  attr_reader :company, :warehouse, :employee

  def find_count!(count_id)
    company.stock_counts.where(warehouse_id: warehouse.id).find(count_id)
  end

  def ensure_open!(count)
    return if count.status_draft? || count.status_in_progress?

    raise Inventory::Error, "Count is already #{count.status}."
  end

  def apply_lines!(count, lines)
    Array(lines).each do |line_params|
      line_id = line_params[:id] || line_params["id"]
      line = count.stock_count_lines.find_by(id: line_id)
      raise Inventory::Error, "Count line not found." if line.blank?

      line.record_count!(normalize_counted(line_params[:counted_quantity] || line_params["counted_quantity"]))
    end
  end

  def normalize_counted(value)
    return nil if value.nil? || value == ""

    number = Integer(value, exception: false)
    raise Inventory::Error, "Counted quantity must be a whole number 0 or more." unless number && number >= 0

    number
  end

  def build_adjustment(count, stock, delta)
    company.stock_adjustments.new(
      company: company,
      branch: stock.branch,
      warehouse: warehouse,
      category: stock.category,
      property_mapping: stock.property_mapping,
      code: "STKAD-#{SecureRandom.hex(4).upcase}",
      name: "Count correction #{item_name(stock)}",
      description: "Cycle count #{count.id}",
      reason: "Count",
      direction: delta.positive? ? :increase : :decrease,
      workflow_status: :pending
    )
  end

  def reorder_points_for(count)
    product_ids = count.stock_count_lines.includes(:stock).map { |line| line.stock.product_id }.uniq
    return {} if product_ids.empty?

    ReorderRule.where(
      company_id: company.id,
      warehouse_id: warehouse.id,
      product_id: product_ids,
      is_active: true,
      discarded_at: nil
    ).each_with_object({}) do |rule, map|
      map[rule.product_id] = rule.min_quantity.to_i + rule.safety_stock.to_i
    end
  end

  def serialize_line(line, points)
    stock = line.stock
    on_hand = stock.quantity.to_i
    reserved = stock.pending.to_i
    available = [ on_hand - reserved, 0 ].max
    reorder_point = points.fetch(stock.product_id, LOW_STOCK_THRESHOLD)

    {
      id: line.id,
      stock_id: stock.id,
      name: item_name(stock),
      code: stock.code.presence || stock.product&.code.presence || "—",
      location: stock.property_string_1.presence,
      expected_quantity: line.expected_quantity.to_i,
      counted_quantity: line.counted_quantity,
      variance_quantity: line.variance_quantity.to_i,
      available: available,
      reorder_point: reorder_point,
      low: available <= reorder_point
    }
  end

  def submit_message(adjusted, errors)
    if errors.any?
      "Count submitted · #{adjusted} lines adjusted · #{errors.size} skipped."
    else
      "Count submitted · #{adjusted} lines adjusted."
    end
  end

  def item_name(stock)
    stock.name.presence || stock.product&.name.presence || stock.code.presence || "Item"
  end
end
