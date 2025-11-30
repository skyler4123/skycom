class EventGroupsController < ApplicationController
  before_action :set_event_group, only: %i[ show edit update destroy ]

  # GET /event_groups or /event_groups.json
  def index
    @event_groups = EventGroup.all
  end

  # GET /event_groups/1 or /event_groups/1.json
  def show
  end

  # GET /event_groups/new
  def new
    @event_group = EventGroup.new
  end

  # GET /event_groups/1/edit
  def edit
  end

  # POST /event_groups or /event_groups.json
  def create
    @event_group = EventGroup.new(event_group_params)

    respond_to do |format|
      if @event_group.save
        format.html { redirect_to @event_group, notice: "Event group was successfully created." }
        format.json { render :show, status: :created, location: @event_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_groups/1 or /event_groups/1.json
  def update
    respond_to do |format|
      if @event_group.update(event_group_params)
        format.html { redirect_to @event_group, notice: "Event group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @event_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_groups/1 or /event_groups/1.json
  def destroy
    @event_group.destroy!

    respond_to do |format|
      format.html { redirect_to event_groups_path, notice: "Event group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_group
      @event_group = EventGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_group_params
      params.expect(event_group: [ :company_group_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
