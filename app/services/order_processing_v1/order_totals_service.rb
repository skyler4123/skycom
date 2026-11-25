# frozen_string_literal: true

# OrderProcessingV1::OrderTotalsService — one money calculation for the POS.
#
# Why it exists: a sale can mix tax-added and tax-included lines at different
# rates. The order carries each line's tax snapshot; the invoice carries the
# grouped breakdown. Every figure is integer cents (or whole dong for VND) so
# the screen, invoice, transaction, and receipt cannot disagree.
# How it works: allocates the discount proportionally across line gross, then
# rounds tax per line and sums. Discount cents are distributed exactly with the
# largest-remainder method.
# Main associations: reads Order's product/service appointments and the company
# default tax code for legacy lines without a snapshot.
module OrderProcessingV1
  class OrderTotalsService
    Line = Struct.new(
      :appointment_type, :appointment_id, :gross_cents, :tax_code_id,
      :tax_name, :rate_bp, :inclusive,
      keyword_init: true
    )

    LineTax = Struct.new(
      :appointment_type, :appointment_id, :taxable_cents, :tax_cents,
      keyword_init: true
    )

    Result = Struct.new(
      :subtotal_cents, :discount_cents, :tax_cents, :added_tax_cents,
      :total_cents, :currency, :tax_lines, :line_taxes,
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
      lines = build_lines
      subtotal = lines.sum(&:gross_cents)
      discount = [ [ @discount_cents, 0 ].max, subtotal ].min
      shares = discount_shares(lines, discount, subtotal)

      line_taxes = []
      groups = {}

      lines.each_with_index do |line, index|
        net_gross = line.gross_cents - shares[index]
        breakdown = tax_breakdown(net_gross, line.rate_bp, line.inclusive)

        line_taxes << LineTax.new(
          appointment_type: line.appointment_type,
          appointment_id: line.appointment_id,
          taxable_cents: breakdown[:taxable_cents],
          tax_cents: breakdown[:tax_cents]
        )

        key = [ line.tax_code_id, line.tax_name, line.rate_bp, line.inclusive ]
        group = groups[key] ||= {
          tax_code_id: line.tax_code_id,
          name: line.tax_name,
          rate_bp: line.rate_bp,
          rate_percent: line.rate_bp / 100.0,
          inclusive: line.inclusive,
          taxable_cents: 0,
          tax_cents: 0
        }
        group[:taxable_cents] += breakdown[:taxable_cents]
        group[:tax_cents] += breakdown[:tax_cents]
      end

      added_tax_cents = lines.each_with_index.sum do |line, index|
        line.inclusive ? 0 : line_taxes[index].tax_cents
      end

      Result.new(
        subtotal_cents: subtotal,
        discount_cents: discount,
        tax_cents: line_taxes.sum(&:tax_cents),
        added_tax_cents: added_tax_cents,
        total_cents: subtotal - discount + added_tax_cents,
        currency: @order.currency,
        tax_lines: groups.values.reject { |row| row[:tax_cents].zero? },
        line_taxes: line_taxes
      )
    end

    private

    def build_lines
      product_lines + service_lines
    end

    def product_lines
      @order.order_product_appointments.order(:created_at, :id).map do |appointment|
        build_line(appointment, "OrderProductAppointment")
      end
    end

    def service_lines
      @order.order_service_appointments.order(:created_at, :id).map do |appointment|
        build_line(appointment, "OrderServiceAppointment")
      end
    end

    def build_line(appointment, appointment_type)
      snapshot_name = appointment.tax_name.presence
      code = snapshot_name ? nil : default_tax_code

      Line.new(
        appointment_type: appointment_type,
        appointment_id: appointment.id,
        gross_cents: money_to_cents(appointment.total_price),
        tax_code_id: appointment.tax_code_id || code&.id,
        tax_name: snapshot_name || code&.name.presence || "Tax",
        rate_bp: snapshot_name ? appointment.tax_rate_bp.to_i : code&.rate_bp.to_i,
        inclusive: snapshot_name ? appointment.tax_inclusive? : code&.is_inclusive || false
      )
    end

    def money_to_cents(value)
      return 0 if value.nil?

      Money.from_amount(value, @order.currency).cents
    end

    def default_tax_code
      return @default_tax_code if defined?(@default_tax_code)

      @default_tax_code = TaxConfig.for_company!(@order.company).default_tax_code
    end

    # Allocates the discount proportionally to line gross, then gives the
    # leftover cents to the largest remainders (ties keep line order).
    def discount_shares(lines, discount, subtotal)
      shares = Array.new(lines.length, 0)
      return shares if discount.zero? || subtotal.zero?

      rows = lines.each_with_index.map do |line, index|
        product = discount * line.gross_cents
        {
          index: index,
          base: product / subtotal,
          remainder: product % subtotal
        }
      end

      rows.each { |row| shares[row[:index]] = row[:base] }
      leftover = discount - shares.sum
      rows.sort_by { |row| [ -row[:remainder], row[:index] ] }
        .first(leftover)
        .each { |row| shares[row[:index]] += 1 }

      shares
    end

    def tax_breakdown(gross_cents, rate_bp, inclusive)
      gross = gross_cents.to_i
      rate = rate_bp.to_i

      if inclusive
        tax = ((gross * rate).to_r / (10_000 + rate)).round
        { taxable_cents: gross - tax, tax_cents: tax }
      else
        tax = ((gross * rate).to_r / 10_000).round
        { taxable_cents: gross, tax_cents: tax }
      end
    end
  end
end
