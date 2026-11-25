# frozen_string_literal: true

# OrderProcessingV1::CreateOrderService — creates a pending POS order.
#
# The browser sends products/services and quantities only. Every price, the
# currency, the tax snapshot, and the selling stock row come from the server,
# so a tampered client cannot set the amount charged. Product stock is resolved
# once here and persisted on the line; pay reserves that exact stock.
module OrderProcessingV1
  class CreateOrderService
    Line = Struct.new(
      :kind, :record, :stock, :quantity, :unit_price_cents, :tax_code,
      keyword_init: true
    ) do
      def total_cents
        unit_price_cents * quantity
      end
    end

    def self.call(company:, branch:, items:, customer: nil, employee: nil)
      new(company: company, branch: branch, items: items, customer: customer, employee: employee).call
    end

    def initialize(company:, branch:, items:, customer: nil, employee: nil)
      @company = company
      @branch = branch
      @items = Array(items)
      @customer = customer
      @employee = employee
    end

    def call
      lines = resolve_lines
      raise InvalidOrderItemError, "Cart is empty" if lines.empty?

      check_availability!(lines.select { |line| line.kind == "product" })

      ActiveRecord::Base.transaction do
        order = create_order
        insert_lines(order, lines)
        totals = OrderTotalsService.call(order: order)
        PersistLineTaxesService.call(line_taxes: totals.line_taxes)
        order.update_columns(tax_cents: totals.tax_cents, total_cents: totals.total_cents)
        order_result(order, totals, lines)
      end
    end

    private

    def resolve_lines
      default_tax_code = TaxConfig.for_company!(@company).default_tax_code
      product_items = @items.select { |item| item[:product_id].present? }
      products = if product_items.any?
        @company.products.where(branch_id: @branch.id, id: product_items.map { |item| item[:product_id] }).index_by(&:id)
      else
        {}
      end
      stocks = Pos::SellingStockResolver.for_products(
        company: @company, branch: @branch, products: products.values
      )

      @items.map do |item|
        quantity = item[:quantity].to_i
        raise InvalidOrderItemError, "Quantity must be at least 1" if quantity < 1

        if item[:product_id].present?
          product = products[item[:product_id].to_s]
          raise InvalidOrderItemError, "Product not found in this branch" unless product
          raise InvalidOrderItemError, "Price is not set for #{product.name}" if product.price_cents.nil?

          stock = stocks[product.id]
          raise InsufficientStockError, "Product is not stocked at this branch" unless stock

          Line.new(
            kind: "product", record: product, stock: stock, quantity: quantity,
            unit_price_cents: product.price_cents.to_i,
            tax_code: TaxCodes::Resolver.call(record: product, default_tax_code: default_tax_code)
          )
        elsif item[:service_id].present?
          service = @company.services.where(branch_id: @branch.id).find_by(id: item[:service_id])
          raise InvalidOrderItemError, "Service not found in this branch" unless service
          raise InvalidOrderItemError, "Price is not set for #{service.name}" if service.price_cents.nil?

          Line.new(
            kind: "service", record: service, quantity: quantity,
            unit_price_cents: service.price_cents.to_i,
            tax_code: TaxCodes::Resolver.call(record: service, default_tax_code: default_tax_code)
          )
        else
          raise InvalidOrderItemError, "Item must be a product or a service"
        end
      end
    end

    def check_availability!(product_lines)
      return if product_lines.empty?

      items = product_lines.group_by { |line| line.stock.id }.map do |stock_id, lines|
        { stock_id: stock_id, quantity: lines.sum(&:quantity) }
      end
      result = CheckAvailabilityService.call(items: items)
      return if result[:available]

      raise InsufficientStockError, "Insufficient stock for item #{result[:failed_item]}"
    end

    def create_order
      Order.create!(
        company: @company,
        branch: @branch,
        customer: @customer || create_walk_in_customer,
        name: "POS Order #{Time.current.to_i}-#{SecureRandom.hex(2).upcase}",
        workflow_status: :pending,
        currency: @company.currency,
        business_type: :in_store,
        fulfillment_channel: :walk_in,
        employee: @employee
      )
    end

    def create_walk_in_customer
      @company.customers.create!(
        name: "Walk-in Customer #{Time.current.to_i}-#{SecureRandom.hex(2).upcase}",
        business_type: :individual
      )
    end

    def insert_lines(order, lines)
      now = Time.current
      currency = @company.currency

      product_rows = lines.select { |line| line.kind == "product" }.map do |line|
        {
          company_id: @company.id,
          order_id: order.id,
          product_id: line.record.id,
          stock_id: line.stock.id,
          name: line.record.name,
          quantity: line.quantity,
          unit_price: Money.from_cents(line.unit_price_cents, currency).to_f,
          total_price: Money.from_cents(line.total_cents, currency).to_f,
          tax_code_id: line.tax_code&.id,
          tax_name: line.tax_code&.name.presence || "Tax",
          tax_rate_bp: line.tax_code&.rate_bp.to_i,
          tax_inclusive: line.tax_code&.is_inclusive || false,
          created_at: now,
          updated_at: now
        }
      end
      OrderProductAppointment.insert_all!(product_rows) if product_rows.any?

      service_rows = lines.select { |line| line.kind == "service" }.map do |line|
        {
          company_id: @company.id,
          order_id: order.id,
          service_id: line.record.id,
          name: line.record.name,
          quantity: line.quantity,
          unit_price: Money.from_cents(line.unit_price_cents, currency).to_f,
          total_price: Money.from_cents(line.total_cents, currency).to_f,
          tax_code_id: line.tax_code&.id,
          tax_name: line.tax_code&.name.presence || "Tax",
          tax_rate_bp: line.tax_code&.rate_bp.to_i,
          tax_inclusive: line.tax_code&.is_inclusive || false,
          created_at: now,
          updated_at: now
        }
      end
      OrderServiceAppointment.insert_all!(service_rows) if service_rows.any?
    end

    def order_result(order, totals, lines)
      {
        order_id: order.id,
        currency: totals.currency,
        subtotal_cents: totals.subtotal_cents,
        tax_cents: totals.tax_cents,
        added_tax_cents: totals.added_tax_cents,
        total_cents: totals.total_cents,
        tax_lines: totals.tax_lines,
        items: lines.map do |line|
          {
            kind: line.kind,
            id: line.record.id,
            quantity: line.quantity,
            unit_price_cents: line.unit_price_cents,
            total_cents: line.total_cents,
            tax: line.tax_code&.option_payload
          }
        end
      }
    end
  end
end
