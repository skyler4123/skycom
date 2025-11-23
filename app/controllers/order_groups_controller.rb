class OrderGroupsController < ApplicationController
  before_action :set_order_group, only: %i[ show edit update destroy ]

  # GET /order_groups or /order_groups.json
  def index
    @order_groups = OrderGroup.all
  end

  # GET /order_groups/1 or /order_groups/1.json
  def show
  end

  # GET /order_groups/new
  def new
    @order_group = OrderGroup.new
  end

  # GET /order_groups/1/edit
  def edit
  end

  # POST /order_groups or /order_groups.json
  def create
    @order_group = OrderGroup.new(order_group_params)

    respond_to do |format|
      if @order_group.save
        format.html { redirect_to @order_group, notice: "Order group was successfully created." }
        format.json { render :show, status: :created, location: @order_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /order_groups/1 or /order_groups/1.json
  def update
    respond_to do |format|
      if @order_group.update(order_group_params)
        format.html { redirect_to @order_group, notice: "Order group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @order_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /order_groups/1 or /order_groups/1.json
  def destroy
    @order_group.destroy!

    respond_to do |format|
      format.html { redirect_to order_groups_path, notice: "Order group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_group
      @order_group = OrderGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_group_params
      params.expect(order_group: [ :company_id, :customer_id, :name, :description, :code, :currency, :duration, :status, :business_type, :discarded_at ])
    end
end
