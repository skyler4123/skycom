# frozen_string_literal: true

# Executes a StockExport: one `remove` ledger row per StockItemAppointment line
# (transaction_type: export, appoint_for: export). Free-standing removal — the
# hold-aware floor (quantity - pending >= qty) applies per line; a violation
# raises StockMovementService::Error so the caller's transaction rolls back the
# document, lines, ledger and quantities together. pending → shipped.
class StockMovementService::Exports::CreateService < StockMovementService::BaseService
  def self.execute!(document:, employee:)
    raise StockMovementService::Error, "Export has no stock lines" if document.stock_item_appointments.empty?

    document.stock_item_appointments.each do |line|
      call(
        stock: line.stock,
        quantity: line.quantity,
        direction: :remove,
        transaction_type: :export,
        document: document,
        employee: employee
      )
    end

    document.update!(workflow_status: :shipped)
    document
  end
end
