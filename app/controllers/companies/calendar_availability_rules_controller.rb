# app/controllers/companies/calendar_availability_rules_controller.rb
#
# Practitioner / room working hours — JSON API (Shell-First). index supports
# ?q= plus ?practitioner_id= / ?location_id= / ?blackout= filters.
#
# These are raw hours. Skycom does not compute free slots from them yet; that is
# the Calendar::Adapter#available_slots seam (docs/CALENDAR.md §6). Overlap
# between two rules on the same owner is rejected so a provider never receives
# a contradictory schedule.
#
# Serves Stimulus: Companies_CalendarAvailabilityRules_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarAvailabilityRules_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_availability_rules.json
# Endpoints: GET    /companies/:company_id/calendar_availability_rules(.json)
#            GET    /companies/:company_id/calendar_availability_rules/:id(.json)
#            GET    /companies/:company_id/calendar_availability_rules/new(.json)
#            GET    /companies/:company_id/calendar_availability_rules/:id/edit(.json)
#            POST   /companies/:company_id/calendar_availability_rules(.json)
#            PATCH  /companies/:company_id/calendar_availability_rules/:id(.json)
#            DELETE /companies/:company_id/calendar_availability_rules/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarAvailabilityRulesController < Companies::ApplicationController
  include Companies::CalendarSerializable

  before_action :set_calendar_availability_rule, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_availability_rules: records.map { |rule| format_rule(rule) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_availability_rule: format_rule(calendar_availability_rule) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_availability_rule: { timezone: Time.zone.name, days_of_week: [ 1, 2, 3, 4, 5 ] } } }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_availability_rule: format_rule(calendar_availability_rule) } }
    end
  end

  def create
    rule = current_company.calendar_availability_rules.new(rule_params)

    if rule.save && !overlaps_existing?(rule)
      render json: { calendar_availability_rule: format_rule(rule), message: "Working hours created successfully!" }
    else
      render json: { errors: errors_for(rule) }, status: :unprocessable_content
    end
  end

  def update
    if calendar_availability_rule.update(rule_params) && !overlaps_existing?(calendar_availability_rule)
      render json: {
        calendar_availability_rule: format_rule(calendar_availability_rule),
        message: "Working hours updated successfully!"
      }
    else
      render json: { errors: errors_for(calendar_availability_rule) }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_availability_rule.destroy!

    render json: { message: "Working hours deleted successfully!" }
  end

  private

  def calendar_availability_rule
    @calendar_availability_rule ||= current_company.calendar_availability_rules.find(params[:id])
  end

  def set_calendar_availability_rule
    calendar_availability_rule
  end

  def format_rule(rule)
    rule.as_json(only: [
      :id, :name, :timezone, :days_of_week, :start_time, :end_time,
      :effective_from, :effective_to, :priority, :is_unavailable,
      :calendar_practitioner_id, :calendar_location_id, :lifecycle_status,
      :created_at, :updated_at
    ]).merge(
      owner_label: rule.owner_label,
      working: rule.working?,
      calendar_practitioner: rule.calendar_practitioner&.as_json(only: [ :id, :name, :color ]),
      calendar_location: rule.calendar_location&.as_json(only: [ :id, :name, :color ])
    )
  end

  def filtered_scope
    scope = current_company.calendar_availability_rules.ordered
    scope = scope.where(calendar_practitioner_id: params[:practitioner_id]) if params[:practitioner_id].present?
    scope = scope.where(calendar_location_id: params[:location_id]) if params[:location_id].present?
    scope = scope.where(is_unavailable: params[:blackout] == "true") if params[:blackout].present?
    scope = scope.effective_on(Date.parse(params[:on])) if params[:on].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    scope.where("calendar_availability_rules.name ILIKE :q", q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%")
  rescue ArgumentError
    scope
  end

  # Checks the neighbour-rule overlap in SQL, then reports it on the record so
  # the FE gets it through the same `errors` array as everything else.
  # #neighbour_for returns nil for a rule that is too incomplete to compare.
  def overlaps_existing?(rule)
    return false if neighbour_for(rule).nil?

    rule.errors.add(:base, "Overlaps an existing window for #{rule.owner_label} on those days")
    true
  end

  def neighbour_for(rule)
    return nil if rule.start_time.blank? || rule.end_time.blank?
    return nil if rule.calendar_practitioner_id.blank? && rule.calendar_location_id.blank?

    scope = current_company.calendar_availability_rules.where(is_unavailable: rule.is_unavailable)
    scope = scope.where.not(id: rule.id) if rule.id.present?

    if rule.calendar_practitioner_id.present?
      scope = scope.where(calendar_practitioner_id: rule.calendar_practitioner_id)
    else
      scope = scope.where(calendar_location_id: rule.calendar_location_id)
    end

    # Half-open overlap, same as Calendar::ConflictChecker: 09:00–17:00 and
    # 17:00–20:00 are fine, 09:00–12:00 and 11:00–14:00 are not.
    scope = scope.where("start_time < ? AND end_time > ?", rule.end_time, rule.start_time)

    # A rule with no explicit days is treated as matching every day.
    days = Array(rule.days_of_week.presence || CALENDAR_WEEKDAYS)
    scope = scope.where("days_of_week && ARRAY[?]::integer[]", days)

    scope.first
  end

  def errors_for(rule)
    rule.errors.full_messages.presence || [ "Working hours overlap an existing window" ]
  end

  def rule_params
    permitted = params.require(:calendar_availability_rule).permit(
      :name, :timezone, :start_time, :end_time,
      :effective_from, :effective_to, :priority, :is_unavailable,
      :calendar_practitioner_id, :calendar_location_id, :lifecycle_status,
      # Array values need the explicit `[]` form — a bare :days_of_week symbol
      # is silently dropped by strong params.
      days_of_week: []
    )
    permitted[:days_of_week] = Array(permitted[:days_of_week]).map(&:to_i) if permitted.key?(:days_of_week)
    permitted
  end
end
