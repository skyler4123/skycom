# frozen_string_literal: true

# Bridges a completed Event to a payable Order (result-hash contract).
#
# NOTE (decoupled): not called by Events::AfterSaveService for now — events stay
# independent until reconnected. Kept intact so the reconnect is a one-line revert.
#
# The Event tracks the occasion; the Order processes its money. On success
# the order is a normal pending in_store order with price snapshots taken
# from the catalog at completion time — it then flows through the standard
# POS pipeline (pay → finalize) untouched. Idempotent: an event links at
# most one order; repeats return the existing row.
module Events
  class CreateOrderService
    def self.call(event:)
      new(event: event).call
    end

    def initialize(event:)
      @event = event
    end

    def call
      return guard_failure("Event category does not create orders") unless bridge_enabled?
      return guard_failure("Event has no billable lines") if billable_lines.empty?

      existing = EventOrderAppointment.find_by(company_id: @event.company_id, event_id: @event.id)
      return { success: true, order: existing.order } if existing

      order = nil
      ActiveRecord::Base.transaction do
        order = Order.create!(
          company_id: @event.company_id,
          branch_id: @event.branch_id,
          customer: order_customer,
          name: "Event Order #{@event.code.presence || @event.id.to_s[0, 8]}",
          currency: @event.company.currency,
          workflow_status: :pending,
          business_type: :in_store
        )
        insert_product_lines(order)
        insert_service_lines(order)
        EventOrderAppointment.create!(company_id: @event.company_id, event_id: @event.id, order_id: order.id)
      end

      { success: true, order: order }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: [ e.message ] }
    end

    private

    def bridge_enabled?
      EventConfig.exists?(
        company_id: @event.company_id, category_id: @event.category_id,
        create_order_on_complete: true
      )
    end

    def billable_lines
      @billable_lines ||= @event.event_stock_appointments.to_a + @event.event_service_appointments.to_a
    end

    def guard_failure(message)
      { success: false, errors: [ message ] }
    end

    def order_customer
      @event.customers.first || @event.company.customers.create!(name: "Walk-in Customer #{Time.current.to_i}", business_type: :individual)
    end

    def insert_product_lines(order)
      rows = @event.event_stock_appointments.map do |line|
        product = line.stock.product
        unit_price = product.price.to_f
        {
          company_id: @event.company_id,
          order_id: order.id,
          product_id: product.id,
          quantity: line.quantity,
          unit_price: unit_price,
          total_price: line.quantity.to_i * unit_price,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      OrderProductAppointment.insert_all!(rows) if rows.any?
    end

    def insert_service_lines(order)
      rows = @event.event_service_appointments.map do |line|
        unit_price = line.service.price.to_f
        {
          company_id: @event.company_id,
          order_id: order.id,
          service_id: line.service_id,
          quantity: 1,
          unit_price: unit_price,
          total_price: unit_price,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      OrderServiceAppointment.insert_all!(rows) if rows.any?
    end
  end
end
