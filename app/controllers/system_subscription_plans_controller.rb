class SystemSubscriptionPlansController < ApplicationController
  before_action :set_system_subscription_plan, only: %i[ show edit update destroy ]

  # GET /system_subscription_plans or /system_subscription_plans.json
  def index
    @system_subscription_plans = SystemSubscriptionPlan.all
  end

  # GET /system_subscription_plans/1 or /system_subscription_plans/1.json
  def show
  end

  # GET /system_subscription_plans/new
  def new
    @system_subscription_plan = SystemSubscriptionPlan.new
  end

  # GET /system_subscription_plans/1/edit
  def edit
  end

  # POST /system_subscription_plans or /system_subscription_plans.json
  def create
    @system_subscription_plan = SystemSubscriptionPlan.new(system_subscription_plan_params)

    respond_to do |format|
      if @system_subscription_plan.save
        format.html { redirect_to @system_subscription_plan, notice: "System subscription plan was successfully created." }
        format.json { render :show, status: :created, location: @system_subscription_plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_subscription_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_subscription_plans/1 or /system_subscription_plans/1.json
  def update
    respond_to do |format|
      if @system_subscription_plan.update(system_subscription_plan_params)
        format.html { redirect_to @system_subscription_plan, notice: "System subscription plan was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @system_subscription_plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_subscription_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_subscription_plans/1 or /system_subscription_plans/1.json
  def destroy
    @system_subscription_plan.destroy!

    respond_to do |format|
      format.html { redirect_to system_subscription_plans_path, notice: "System subscription plan was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_subscription_plan
      @system_subscription_plan = SystemSubscriptionPlan.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def system_subscription_plan_params
      params.expect(system_subscription_plan: [ :price_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :discarded_at ])
    end
end
