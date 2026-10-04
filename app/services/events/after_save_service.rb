# frozen_string_literal: true

# Reconciles an Event's stock side effects after it is saved.
#
# One transaction-safe entry point for the controller: holds new requirement
# lines (when the category opts in), releases removed lines on update, frees
# every event hold when the event reaches done (completed/cancelled), and
# bridges to a payable Order on completion (when asked). Warn-but-allow
# throughout: failures land in warnings, never as exceptions — except a
# failed hold under strict_stock_hold, which raises StrictHoldError so the
# controller rolls the whole save back (422, nothing persisted).
module Events
  class AfterSaveService
    DONE_STATUSES = %w[completed cancelled].freeze

    def self.call(event:, previous_workflow_status: nil, previous_stock_map: {})
      new(event: event, previous_workflow_status: previous_workflow_status,
        previous_stock_map: previous_stock_map).call
    end

    def initialize(event:, previous_workflow_status:, previous_stock_map:)
      @event = event
      @previous_workflow_status = previous_workflow_status
      @previous_stock_map = previous_stock_map
      @warnings = []
    end

    def call
      if done_transition?
        release_event_holds(current_stock_map)
        bridge_order if @event.workflow_status == "completed"
      else
        reconcile_holds
      end
      @warnings.concat(Events::ConflictWarningService.call(event: @event)[:warnings])
      { warnings: @warnings }
    end

    private

    def config
      @config ||= EventConfig.find_by(company_id: @event.company_id, category_id: @event.category_id)
    end

    def done_transition?
      @previous_workflow_status.present? &&
        DONE_STATUSES.include?(@event.workflow_status) &&
        @previous_workflow_status != @event.workflow_status
    end

    def current_stock_map
      @event.event_stock_appointments.each_with_object({}) do |line, map|
        map[line.stock_id] = line.quantity.to_i
      end
    end

    def reconcile_holds
      return unless config&.create_stock_pending?

      current = current_stock_map
      removed = @previous_stock_map.reject { |stock_id, _| current.key?(stock_id) }
      removed.each { |stock_id, qty| release_hold(stock_id, qty) }

      added = current.reject { |stock_id, _| @previous_stock_map.key?(stock_id) }
      added.each { |stock_id, qty| take_hold(stock_id, qty) }
    end

    def release_event_holds(stock_map)
      stock_map.each { |stock_id, qty| release_hold(stock_id, qty) }
    end

    def release_hold(stock_id, quantity)
      stock = Stock.find_by(id: stock_id)
      return if stock.nil? || quantity.to_i <= 0

      result = StockPendings::ReleaseService.call(
        company: @event.company, warehouse: stock.warehouse,
        stock: stock, quantity: quantity, business_type: :event
      )
      @warnings.concat(result[:errors]) unless result[:success]
    end

    def take_hold(stock_id, quantity)
      stock = Stock.find_by(id: stock_id)
      return if stock.nil? || quantity.to_i <= 0

      result = StockPendings::HoldService.call(
        company: @event.company, warehouse: stock.warehouse, stock: stock,
        quantity: quantity, business_type: :event,
        name: @event.name, reason: "event:#{@event.id}"
      )
      return if result[:success]

      message = "Could not hold #{stock.name}: #{result[:errors].to_sentence}"
      raise StrictHoldError, message if config&.strict_stock_hold?

      @warnings << message
    end

    def bridge_order
      return unless config&.create_order_on_complete?
      return if EventOrderAppointment.exists?(company_id: @event.company_id, event_id: @event.id)
      return if current_stock_map.empty? && @event.event_service_appointments.empty?

      result = Events::CreateOrderService.call(event: @event)
      @warnings.concat(result[:errors]) unless result[:success]
    end
  end
end
