# frozen_string_literal: true

module OrderProcessingV1
  class CreateOrderService
    def self.call(company:, branch:, items:, customer: nil)
      total_price = items.sum { |i| i[:quantity].to_i * i[:unit_price].to_f }

      order_customer = customer || company.customers.create!(
        name: "Walk-in Customer #{Time.current.to_i}",
        business_type: :individual
      )

      order = Order.create!(
        company: company,
        branch: branch,
        customer: order_customer,
        name: "POS Order #{Time.current.to_i}",
        workflow_status: :pending,
        currency: :usd,
        business_type: :in_store
      )

      order_appointments = items.map do |item|
        product = Product.find(item[:product_id])
        {
          company_id: company.id,
          order_id: order.id,
          appoint_to_type: "Product",
          appoint_to_id: item[:product_id],
          quantity: item[:quantity],
          unit_price: item[:unit_price],
          total_price: item[:quantity].to_i * item[:unit_price].to_f,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      OrderAppointment.insert_all!(order_appointments)

      { order_id: order.id, total_price: total_price }
    end
  end
end
