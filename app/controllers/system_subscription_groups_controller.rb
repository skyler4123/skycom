class SystemSubscriptionGroupsController < ApplicationController
  before_action :set_system_subscription_group, only: %i[ show edit update destroy ]

  # GET /system_subscription_groups or /system_subscription_groups.json
  def index
    @system_subscription_groups = SystemSubscriptionGroup.all
  end

  # GET /system_subscription_groups/1 or /system_subscription_groups/1.json
  def show
  end

  # GET /system_subscription_groups/new
  def new
    @system_subscription_group = SystemSubscriptionGroup.new
  end

  # GET /system_subscription_groups/1/edit
  def edit
  end

  # POST /system_subscription_groups or /system_subscription_groups.json
  def create
    @system_subscription_group = SystemSubscriptionGroup.new(system_subscription_group_params)

    respond_to do |format|
      if @system_subscription_group.save
        format.html { redirect_to @system_subscription_group, notice: "System subscription group was successfully created." }
        format.json { render :show, status: :created, location: @system_subscription_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_subscription_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_subscription_groups/1 or /system_subscription_groups/1.json
  def update
    respond_to do |format|
      if @system_subscription_group.update(system_subscription_group_params)
        format.html { redirect_to @system_subscription_group, notice: "System subscription group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @system_subscription_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_subscription_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_subscription_groups/1 or /system_subscription_groups/1.json
  def destroy
    @system_subscription_group.destroy!

    respond_to do |format|
      format.html { redirect_to system_subscription_groups_path, notice: "System subscription group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_subscription_group
      @system_subscription_group = SystemSubscriptionGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def system_subscription_group_params
      params.expect(system_subscription_group: [ :system_subscription_plan_id, :company_group_id, :company_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at ])
    end
end
