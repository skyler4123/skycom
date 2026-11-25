# frozen_string_literal: true

# OrderProcessingV1::PersistLineTaxesService — writes the final line tax
# snapshot after a discount is known.
#
# Why it exists: `OrderTotalsService` is a pure calculator; the order line is the
# durable audit row. Checkout persists the no-discount snapshot, and payment
# persists the discounted one.
# How it works: updates `taxable_cents` / `tax_cents` on the concrete
# appointment row named by the calculator's LineTax struct.
# Main associations: OrderProductAppointment / OrderServiceAppointment.
module OrderProcessingV1
  class PersistLineTaxesService
    def self.call(line_taxes:)
      line_taxes.each do |line|
        klass = line.appointment_type.constantize
        klass.where(id: line.appointment_id).update_all(
          taxable_cents: line.taxable_cents,
          tax_cents: line.tax_cents
        )
      end
    end
  end
end
