class FacilityGroupsController < ApplicationController
  before_action :set_facility_group, only: %i[ show edit update destroy ]

  # GET /facility_groups or /facility_groups.json
  def index
    @facility_groups = FacilityGroup.all
  end

  # GET /facility_groups/1 or /facility_groups/1.json
  def show
  end

  # GET /facility_groups/new
  def new
    @facility_group = FacilityGroup.new
  end

  # GET /facility_groups/1/edit
  def edit
  end

  # POST /facility_groups or /facility_groups.json
  def create
    @facility_group = FacilityGroup.new(facility_group_params)

    respond_to do |format|
      if @facility_group.save
        format.html { redirect_to @facility_group, notice: "Facility group was successfully created." }
        format.json { render :show, status: :created, location: @facility_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @facility_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /facility_groups/1 or /facility_groups/1.json
  def update
    respond_to do |format|
      if @facility_group.update(facility_group_params)
        format.html { redirect_to @facility_group, notice: "Facility group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @facility_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @facility_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /facility_groups/1 or /facility_groups/1.json
  def destroy
    @facility_group.destroy!

    respond_to do |format|
      format.html { redirect_to facility_groups_path, notice: "Facility group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_facility_group
      @facility_group = FacilityGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def facility_group_params
      params.expect(facility_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
