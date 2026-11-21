# frozen_string_literal: true

# OrderProcessingV1::OrderTotalsService — one money calculation for the POS.
#
# The order carries the tax snapshot taken at ORDER time; the invoice carries
# the snapshot taken at pay time. Tax is added on top of the discounted
# subtotal, and every figure is integer cents (or whole dong for VND) so the
# screen, invoice, transaction, and receipt cannot disagree.
module OrderProcessingV1
  class OrderTotalsService
    Result = Struct.new(
      :subtotal_cents, :discount_cents, :tax_cents, :total_cents,
      :currency, :tax_rate_bp, :tax_name,
      keyword_init: true
    )

    def self.call(order:, discount_cents: 0)
      new(order: order, discount_cents: discount_cents).call
    end

    def initialize(order:, discount_cents: 0)
      @order = order
      @discount_cents = discount_cents.to_i
    end

    def call
      subtotal = subtotal_cents
      discount = [ [ @discount_cents, 0 ].max, subtotal ].min
      taxable = subtotal - discount
      Result.new(
        subtotal_cents: subtotal,
        discount_cents: discount,
        tax_cents: tax_cents_for(taxable),
        total_cents: taxable + tax_cents_for(taxable),
        currency: @order.currency,
        tax_rate_bp: tax_rate_bp,
        tax_name: tax_name
      )
    end

    private

    def subtotal_cents
      Money.from_amount(@order.line_total, @order.currency).cents
    end

    def tax_cents_for(taxable_cents)
      (taxable_cents * tax_rate_bp / 10_000.0).round
    end

    def tax_rate_bp
      snapshot = @order.pos_tax_rate_bp
      return snapshot.to_i unless snapshot.nil?

      TaxConfig.for_company!(@order.company).pos_tax_rate_bp.to_i
    end

    def tax_name
      @order.pos_tax_name.presence ||
        TaxConfig.for_company!(@order.company).pos_tax_name.presence ||
        "Tax"
    end
  end
end
