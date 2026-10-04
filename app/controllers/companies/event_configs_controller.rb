# app/controllers/companies/event_configs_controller.rb
#
# EventConfig dashboard API (Shell-First). Per-category rule rows: which event
# types hold stock, block-or-warn on hold failure, build an order on
# completion, and warn on double-booked facilities/hosts.
# Serves Stimulus: Companies_EventConfigs_IndexController,
#                  Companies_EventConfigs_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/event_configs(.json) + nested CRUD — see config/routes.rb
# Docs: docs/EVENTS.md
class Companies::EventConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.event_configs.includes(:category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @configs_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          event_configs: @configs_results.map { |c| format_config(c) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    config = current_company.event_configs.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { event_config: format_config(config) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          categories: current_company.categories.where(resource_name: "events")
            .map { |c| c.as_json(only: [ :id, :name ]) }
        }
      end
    end
  end

  def edit
    config = current_company.event_configs.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          event_config: format_config(config),
          categories: current_company.categories.where(resource_name: "events")
            .map { |c| c.as_json(only: [ :id, :name ]) }
        }
      end
    end
  end

  def create
    config = current_company.event_configs.new(config_params)

    if config.save
      redirect_to company_event_config_path(current_company, config), notice: "Event config created successfully"
    else
      redirect_to new_company_event_config_path(current_company),
        alert: config.errors.full_messages.to_sentence
    end
  end

  def update
    config = current_company.event_configs.find(params[:id])

    if config.update(config_params)
      redirect_to company_event_config_path(current_company, config), notice: "Event config updated successfully."
    else
      redirect_to edit_company_event_config_path(current_company, config),
        alert: config.errors.full_messages.to_sentence
    end
  end

  private

  def config_params
    params.require(:event_config).permit(
      :category_id,
      :create_stock_pending,
      :strict_stock_hold,
      :create_order_on_complete,
      :warn_on_facility_overlap,
      :warn_on_host_overlap
    )
  end

  def format_config(config)
    config.as_json(only: [
      :id, :category_id,
      :create_stock_pending, :strict_stock_hold, :create_order_on_complete,
      :warn_on_facility_overlap, :warn_on_host_overlap,
      :created_at, :updated_at
    ]).merge(
      category: config.category&.as_json(only: [ :id, :name ])
    )
  end
end
