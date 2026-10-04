# app/controllers/companies/events_controller.rb
#
# Events dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as other resources (?q= / ?filters[key]= → Meilisearch via
# Events::SearchQueryService; plain DB path otherwise).
# create/update accept link arrays (customer_ids/employee_ids/service_ids/
# facility_ids/event_stock_lines) and run the stock side effects through
# Events::AfterSaveService (holds, warn-but-allow warnings, release on done,
# order bridge on completed) inside the same transaction.
# Serves Stimulus: Companies_Events_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_Events_NewController|ShowController|EditController,
#                  Companies_Calendars_IndexController (board create modal, JSON create)
# Endpoints: GET /companies/:company_id/events(.json) + nested CRUD — see config/routes.rb
# Docs: docs/EVENTS.md, docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::EventsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.events
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = Events::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @events_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          events: format_events(@events_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    event = current_company.events.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        warnings = Events::ConflictWarningService.call(event: event)[:warnings]
        render json: { event: format_event(event), warnings: warnings }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    event = current_company.events.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          event: format_event(event),
          **form_reference_data
        }
      end
    end
  end

  def create
    event = current_company.events.new(event_params)
    event.code ||= "EVT-#{SecureRandom.hex(4).upcase}"

    respond_to do |format|
      format.html do
        begin
          warnings = persist_event(event, previous_stock_map: {})
          notice = "Event created successfully"
          notice += " (#{warnings.size} warning(s): #{warnings.to_sentence})" if warnings.any?
          redirect_to company_event_path(current_company, event), notice: notice
        rescue Events::StrictHoldError, ActiveRecord::RecordInvalid => e
          redirect_to new_company_event_path(current_company), alert: error_message(e, event)
        end
      end
      format.json do
        begin
          warnings = persist_event(event, previous_stock_map: {})
          render json: { event: format_event(event.reload), warnings: warnings,
            message: "Event created successfully" }, status: :created
        rescue Events::StrictHoldError, ActiveRecord::RecordInvalid => e
          render json: { errors: error_messages(e, event) }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    event = current_company.events.find(params[:id])
    previous_status = event.workflow_status
    previous_stock_map = stock_map(event)

    respond_to do |format|
      format.html do
        begin
          event.assign_attributes(event_params)
          warnings = persist_event(event, previous_workflow_status: previous_status,
            previous_stock_map: previous_stock_map)
          notice = "Event updated successfully."
          notice += " (#{warnings.size} warning(s): #{warnings.to_sentence})" if warnings.any?
          redirect_to company_event_path(current_company, event), notice: notice
        rescue Events::StrictHoldError, ActiveRecord::RecordInvalid => e
          redirect_to edit_company_event_path(current_company, event),
            alert: error_message(e, event)
        end
      end
      format.json do
        begin
          event.assign_attributes(event_params)
          warnings = persist_event(event, previous_workflow_status: previous_status,
            previous_stock_map: previous_stock_map)
          render json: { event: format_event(event.reload), warnings: warnings,
            message: "Event updated successfully" }, status: :ok
        rescue Events::StrictHoldError, ActiveRecord::RecordInvalid => e
          render json: { errors: error_messages(e, event) }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Event not found" }, status: :not_found
  end

  private

  # Saves the event plus its link rows, then runs the stock side effects —
  # all in one transaction so a strict hold failure persists nothing.
  # Returns the warnings array.
  def persist_event(event, previous_workflow_status: nil, previous_stock_map: {})
    warnings = nil
    ActiveRecord::Base.transaction do
      event.save!
      sync_link_rows(event)
      result = Events::AfterSaveService.call(event: event,
        previous_workflow_status: previous_workflow_status,
        previous_stock_map: previous_stock_map)
      warnings = result[:warnings]
    end
    warnings
  end

  def stock_map(event)
    event.event_stock_appointments.each_with_object({}) do |line, map|
      map[line.stock_id] = line.quantity.to_i
    end
  end

  def sync_link_rows(event)
    sync_id_links(event, CustomerEventAppointment, :customer, Array(params.dig(:event, :customer_ids)))
    sync_id_links(event, EmployeeEventAppointment, :employee, Array(params.dig(:event, :employee_ids)))
    sync_id_links(event, EventServiceAppointment, :service, Array(params.dig(:event, :service_ids)))
    sync_id_links(event, EventFacilityAppointment, :facility, Array(params.dig(:event, :facility_ids)))
    sync_stock_lines(event)
  end

  def sync_id_links(event, klass, key, ids)
    return if params.dig(:event, :"#{key}_ids").nil?

    wanted = ids.map(&:to_s).uniq
    klass.where(company_id: event.company_id, event_id: event.id).where.not("#{key}_id": wanted).delete_all
    existing = klass.where(company_id: event.company_id, event_id: event.id).pluck("#{key}_id").map(&:to_s)
    (wanted - existing).each do |id|
      klass.create!(company_id: event.company_id, event_id: event.id, "#{key}_id": id)
    end
  end

  def sync_stock_lines(event)
    return if params.dig(:event, :event_stock_lines).nil?

    wanted = stock_line_list.to_h do |l|
      [ (l[:stock_id] || l["stock_id"]).to_s, (l[:quantity] || l["quantity"]).to_i ]
    end
    event.event_stock_appointments.where.not(stock_id: wanted.keys).delete_all
    wanted.each do |stock_id, quantity|
      row = event.event_stock_appointments.find_by(stock_id: stock_id)
      if row
        row.update!(quantity: quantity) if row.quantity != quantity
      else
        event.event_stock_appointments.create!(company_id: event.company_id, stock_id: stock_id, quantity: quantity)
      end
    end
  end

  # HTML forms post indexed hashes ({"0" => {...}}); JSON posts real arrays.
  def stock_line_list
    raw = params.dig(:event, :event_stock_lines)
    return [] if raw.nil?
    return raw if raw.is_a?(Array)

    raw.respond_to?(:values) ? raw.values : []
  end

  def error_message(error, record)
    error.is_a?(Events::StrictHoldError) ? error.message : record.errors.full_messages.to_sentence
  end

  def error_messages(error, record)
    error.is_a?(Events::StrictHoldError) ? [ error.message ] : record.errors.full_messages
  end

  def form_reference_data
    {
      customers: current_company.customers.order(:name).limit(200)
        .map { |c| c.as_json(only: [ :id, :name ]) },
      employees: current_company.employees.order(:name).limit(200)
        .map { |e| e.as_json(only: [ :id, :name ]) },
      services: current_company.services.order(:name).limit(200)
        .map { |s| s.as_json(only: [ :id, :name ]) },
      facilities: current_company.facilities.order(:name).limit(200)
        .map { |f| f.as_json(only: [ :id, :name ]) },
      stocks: current_company.stocks.limit(200)
        .map { |s| s.as_json(only: [ :id, :name ]).merge(product_id: s.product_id) }
    }
  end

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  def event_params
    params.require(:event).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :category_id,
      :branch_id,
      :event_group_id,
      :start_at,
      :end_at,
      *property_keys
    )
  end

  def format_event(event)
    event.as_json(only: [
      :id, :name, :description, :code, :category_id, :branch_id, :event_group_id,
      :start_at, :end_at,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      category: event.category&.as_json(only: [ :id, :name ]),
      branch: event.branch&.as_json(only: [ :id, :name ]),
      customers: event.customer_event_appointments.map { |a|
        a.as_json(only: [ :id, :customer_id, :role ]).merge(name: a.customer&.name) },
      employees: event.employee_event_appointments.map { |a|
        a.as_json(only: [ :id, :employee_id ]).merge(name: a.employee&.name) },
      services: event.event_service_appointments.map { |a|
        a.as_json(only: [ :id, :service_id, :role ]).merge(name: a.service&.name) },
      facilities: event.event_facility_appointments.map { |a|
        a.as_json(only: [ :id, :facility_id, :role ]).merge(name: a.facility&.name) },
      stocks: event.event_stock_appointments.map { |a|
        a.as_json(only: [ :id, :stock_id, :quantity ]).merge(name: a.stock&.name) },
      orders: event.event_order_appointments.map { |a|
        a.as_json(only: [ :id, :order_id ]).merge(name: a.order&.name) }
    )
  end

  def format_events(events)
    events.map { |event| format_event(event) }
  end
end
