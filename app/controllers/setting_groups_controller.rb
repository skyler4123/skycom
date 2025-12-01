class SettingGroupsController < ApplicationController
  before_action :set_setting_group, only: %i[ show edit update destroy ]

  # GET /setting_groups or /setting_groups.json
  def index
    @setting_groups = SettingGroup.all
  end

  # GET /setting_groups/1 or /setting_groups/1.json
  def show
  end

  # GET /setting_groups/new
  def new
    @setting_group = SettingGroup.new
  end

  # GET /setting_groups/1/edit
  def edit
  end

  # POST /setting_groups or /setting_groups.json
  def create
    @setting_group = SettingGroup.new(setting_group_params)

    respond_to do |format|
      if @setting_group.save
        format.html { redirect_to @setting_group, notice: "Setting group was successfully created." }
        format.json { render :show, status: :created, location: @setting_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @setting_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /setting_groups/1 or /setting_groups/1.json
  def update
    respond_to do |format|
      if @setting_group.update(setting_group_params)
        format.html { redirect_to @setting_group, notice: "Setting group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @setting_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @setting_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /setting_groups/1 or /setting_groups/1.json
  def destroy
    @setting_group.destroy!

    respond_to do |format|
      format.html { redirect_to setting_groups_path, notice: "Setting group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting_group
      @setting_group = SettingGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def setting_group_params
      params.expect(setting_group: [ :company_group_id, :company_id, :content, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
