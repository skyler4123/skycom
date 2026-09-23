# frozen_string_literal: true

# Executes a StockAdjustment: one ledger row per StockItemAppointment line with
# transaction_type: adjustment — `add` when the document is an increase, `remove`
# when it is a decrease (remove follows the hold-aware floor). pending → completed.
class StockMovementService::Adjustments::CreateService < StockMovementService::BaseService
  def self.execute!(document:, employee:)
    raise StockMovementService::Error, "Adjustment has no stock lines" if document.stock_item_appointments.empty?

    direction = document.increase? ? :add : :remove
    transaction_type = :adjustment

    document.stock_item_appointments.each do |line|
      call(
        stock: line.stock,
        quantity: line.quantity,
        direction: direction,
        transaction_type: transaction_type,
        document: document,
        employee: employee
      )
    end

    document.update!(workflow_status: :completed)
    document
  end
end
