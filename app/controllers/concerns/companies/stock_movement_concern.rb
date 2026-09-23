# frozen_string_literal: true

# Shared create flow for stock movement documents (StockImport / StockExport /
# StockAdjustment). Builds the document + StockItemAppointment lines from params,
# then executes the movement through the StockMovementService epic inside ONE
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

    stock_items_params.each do |item|
      document.stock_item_appointments.build(
        company: current_company,
        stock: current_company.stocks.find(item[:stock_id]),
        quantity: item[:quantity]
      )
    end

    # Display/filter compat (only on documents that carry the legacy columns):
    # first line's product + total quantity on the document.
    document.product_id ||= document.stock_item_appointments.first&.stock&.product_id if document.has_attribute?(:product_id)
    document.quantity = document.stock_item_appointments.sum(&:quantity) if document.has_attribute?(:quantity)

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
    permitted = [ :warehouse_id, :branch_id, :name, :description, :business_type ]
    permitted += [ :direction, :reason ] if document_class == StockAdjustment

    params.require(document_class.model_name.singular).permit(*permitted).tap do |h|
      h[:company] = current_company
      h[:code] = "#{document_class::CODE_PREFIX}-#{SecureRandom.hex(4).upcase}"
    end
  end

  def stock_items_params
    params.permit(stock_items: [ :stock_id, :quantity ]).to_h[:stock_items] || []
  end
end
