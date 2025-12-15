class SubscriptionGroupsController < ApplicationController
  before_action :set_subscription_group, only: %i[ show edit update destroy ]

  # GET /subscription_groups or /subscription_groups.json
  def index
    @subscription_groups = SubscriptionGroup.all
  end

  # GET /subscription_groups/1 or /subscription_groups/1.json
  def show
  end

  # GET /subscription_groups/new
  def new
    @subscription_group = SubscriptionGroup.new
  end

  # GET /subscription_groups/1/edit
  def edit
  end

  # POST /subscription_groups or /subscription_groups.json
  def create
    @subscription_group = SubscriptionGroup.new(subscription_group_params)

    respond_to do |format|
      if @subscription_group.save
        format.html { redirect_to @subscription_group, notice: "Subscription group was successfully created." }
        format.json { render :show, status: :created, location: @subscription_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscription_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscription_groups/1 or /subscription_groups/1.json
  def update
    respond_to do |format|
      if @subscription_group.update(subscription_group_params)
        format.html { redirect_to @subscription_group, notice: "Subscription group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @subscription_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscription_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscription_groups/1 or /subscription_groups/1.json
  def destroy
    @subscription_group.destroy!

    respond_to do |format|
      format.html { redirect_to subscription_groups_path, notice: "Subscription group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription_group
      @subscription_group = SubscriptionGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subscription_group_params
      params.expect(subscription_group: [ :company_group_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
