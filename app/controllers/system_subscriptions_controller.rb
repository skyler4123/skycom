class SystemSubscriptionsController < ApplicationController
  before_action :set_system_subscription, only: %i[ show edit update destroy ]

  # GET /system_subscriptions or /system_subscriptions.json
  def index
    @system_subscriptions = SystemSubscription.all
  end

  # GET /system_subscriptions/1 or /system_subscriptions/1.json
  def show
  end

  # GET /system_subscriptions/new
  def new
    @system_subscription = SystemSubscription.new
  end

  # GET /system_subscriptions/1/edit
  def edit
  end

  # POST /system_subscriptions or /system_subscriptions.json
  def create
    @system_subscription = SystemSubscription.new(system_subscription_params)

    respond_to do |format|
      if @system_subscription.save
        format.html { redirect_to @system_subscription, notice: "System subscription was successfully created." }
        format.json { render :show, status: :created, location: @system_subscription }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_subscriptions/1 or /system_subscriptions/1.json
  def update
    respond_to do |format|
      if @system_subscription.update(system_subscription_params)
        format.html { redirect_to @system_subscription, notice: "System subscription was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @system_subscription }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_subscriptions/1 or /system_subscriptions/1.json
  def destroy
    @system_subscription.destroy!

    respond_to do |format|
      format.html { redirect_to system_subscriptions_path, notice: "System subscription was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_subscription
      @system_subscription = SystemSubscription.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def system_subscription_params
      params.expect(system_subscription: [ :system_subscription_plan_id, :subscription_group_id, :company_group_id, :company_id, :price_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at ])
    end
end
