class CustomerGroupsController < ApplicationController
  before_action :set_customer_group, only: %i[ show edit update destroy ]

  # GET /customer_groups or /customer_groups.json
  def index
    @customer_groups = CustomerGroup.all
  end

  # GET /customer_groups/1 or /customer_groups/1.json
  def show
  end

  # GET /customer_groups/new
  def new
    @customer_group = CustomerGroup.new
  end

  # GET /customer_groups/1/edit
  def edit
  end

  # POST /customer_groups or /customer_groups.json
  def create
    @customer_group = CustomerGroup.new(customer_group_params)

    respond_to do |format|
      if @customer_group.save
        format.html { redirect_to @customer_group, notice: "Customer group was successfully created." }
        format.json { render :show, status: :created, location: @customer_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customer_groups/1 or /customer_groups/1.json
  def update
    respond_to do |format|
      if @customer_group.update(customer_group_params)
        format.html { redirect_to @customer_group, notice: "Customer group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customer_groups/1 or /customer_groups/1.json
  def destroy
    @customer_group.destroy!

    respond_to do |format|
      format.html { redirect_to customer_groups_path, notice: "Customer group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer_group
      @customer_group = CustomerGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def customer_group_params
      params.expect(customer_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
