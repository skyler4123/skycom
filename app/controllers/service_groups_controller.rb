class ServiceGroupsController < ApplicationController
  before_action :set_service_group, only: %i[ show edit update destroy ]

  # GET /service_groups or /service_groups.json
  def index
    @service_groups = ServiceGroup.all
  end

  # GET /service_groups/1 or /service_groups/1.json
  def show
  end

  # GET /service_groups/new
  def new
    @service_group = ServiceGroup.new
  end

  # GET /service_groups/1/edit
  def edit
  end

  # POST /service_groups or /service_groups.json
  def create
    @service_group = ServiceGroup.new(service_group_params)

    respond_to do |format|
      if @service_group.save
        format.html { redirect_to @service_group, notice: "Service group was successfully created." }
        format.json { render :show, status: :created, location: @service_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @service_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /service_groups/1 or /service_groups/1.json
  def update
    respond_to do |format|
      if @service_group.update(service_group_params)
        format.html { redirect_to @service_group, notice: "Service group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @service_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @service_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /service_groups/1 or /service_groups/1.json
  def destroy
    @service_group.destroy!

    respond_to do |format|
      format.html { redirect_to service_groups_path, notice: "Service group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service_group
      @service_group = ServiceGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def service_group_params
      params.expect(service_group: [ :company_id, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at ])
    end
end
