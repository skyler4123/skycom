# frozen_string_literal: true

# Shared create flow for stock movement documents (StockImport / StockExport /
# StockAdjustment). Builds the document + atomic stock lines from params, then
# executes the movement through the StockMovementService epic inside ONE
# transaction: document + lines + ledger rows + quantity changes all-or-nothing
# (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §2).
# Failure → 422 { errors: [...] }, nothing persisted (docs/API_ERROR_FORMAT.md).
#
# Including controllers must define `format_<singular>(record)` for the JSON
# response and include this concern AFTER their format helpers are defined
# (Ruby method resolution — private methods are fine).
module Companies::StockMovementConcern
  extend ActiveSupport::Concern

  private

  def create_movement_document(document_class, service_class)
    document = document_class.new(movement_document_params(document_class))
    lines = document.public_send(line_assoc_for(document_class))

    validate_stock_items!(stock_items_params)

    stock_items_params.each do |item|
      lines.build(
        company: current_company,
        stock: current_company.stocks.find(item[:stock_id]),
        quantity: item[:quantity]
      )
    end

    # Display/filter compat (only on documents that carry the legacy columns):
    # first line's product + total quantity on the document.
    document.product_id ||= lines.first&.stock&.product_id if document.has_attribute?(:product_id)
    document.quantity = lines.sum(&:quantity) if document.has_attribute?(:quantity)

    validate_line_warehouses!(document, lines)

    ActiveRecord::Base.transaction do
      document.save!
      execute_movement(document, service_class)
    end

    render_movement_document(document)
  rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def execute_movement(document, service_class)
    service_class.execute!(document: document, employee: current_employee)
  end

  def render_movement_document(document)
    formatter = "format_#{document.class.model_name.singular}"
    render json: {
      document.class.model_name.singular => send(formatter, document),
      status: "ok"
    }
  end

  def movement_document_params(document_class)
    permitted = [ :warehouse_id, :branch_id, :name, :description, :business_type, :category_id,
      *movement_property_keys ]
    permitted += [ :direction, :reason ] if document_class == StockAdjustment

    params.require(document_class.model_name.singular).permit(*permitted).tap do |h|
      h[:company] = current_company
      h[:code] = "#{document_class::CODE_PREFIX}-#{SecureRandom.hex(4).upcase}"
    end
  end

  # Each document carries its own atomic line table (one table per pair —
  # docs/RESOURCES.md §4). The concern stays shared by resolving the
  # association from the document class.
  def line_assoc_for(document_class)
    {
      StockImport => :stock_import_stock_appointments,
      StockExport => :stock_export_stock_appointments,
      StockAdjustment => :stock_adjustment_stock_appointments
    }.fetch(document_class)
  end

  # Ledger rows inherit the line's stock warehouse — a line from another
  # warehouse would silently move the wrong shelf while the document names
  # this one. Reject up front (rescued → 422 { errors: [...] }).
  def validate_line_warehouses!(document, lines)
    return if document.warehouse_id.blank?

    lines.each do |line|
      next if line.stock.warehouse_id == document.warehouse_id

      raise StockMovementService::Error,
        "Stock #{line.stock.code} belongs to another warehouse"
    end
  end

  def stock_items_params
    params.permit(stock_items: [ :stock_id, :quantity ]).to_h[:stock_items] || []
  end

  # Rejects blank/non-numeric/zero quantities up front with a 422 business
  # error. Without this, "" casts to nil on the integer column and
  # `lines.sum(&:quantity)` raises TypeError (500). Mirrors the line-model
  # `greater_than: 0` rule so API and UI agree. Normalizes numeric strings
  # in place so downstream sums never see a String.
  def validate_stock_items!(items)
    items.each do |item|
      quantity = item[:quantity]
      quantity = quantity.to_i if quantity.is_a?(String)
      unless quantity.is_a?(Integer) && quantity.positive?
        raise StockMovementService::Error, "Quantity must be a positive integer"
      end
      item[:quantity] = quantity
    end
  end

  # Dynamic-schema columns shared by all movement documents (mirrors
  # Companies::PurchasesController#property_keys).
  def movement_property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end
end
