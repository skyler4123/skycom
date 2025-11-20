class CartGroupsController < ApplicationController
  before_action :set_cart_group, only: %i[ show edit update destroy ]

  # GET /cart_groups or /cart_groups.json
  def index
    @cart_groups = CartGroup.all
  end

  # GET /cart_groups/1 or /cart_groups/1.json
  def show
  end

  # GET /cart_groups/new
  def new
    @cart_group = CartGroup.new
  end

  # GET /cart_groups/1/edit
  def edit
  end

  # POST /cart_groups or /cart_groups.json
  def create
    @cart_group = CartGroup.new(cart_group_params)

    respond_to do |format|
      if @cart_group.save
        format.html { redirect_to @cart_group, notice: "Cart group was successfully created." }
        format.json { render :show, status: :created, location: @cart_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @cart_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cart_groups/1 or /cart_groups/1.json
  def update
    respond_to do |format|
      if @cart_group.update(cart_group_params)
        format.html { redirect_to @cart_group, notice: "Cart group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @cart_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @cart_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cart_groups/1 or /cart_groups/1.json
  def destroy
    @cart_group.destroy!

    respond_to do |format|
      format.html { redirect_to cart_groups_path, notice: "Cart group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cart_group
      @cart_group = CartGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def cart_group_params
      params.expect(cart_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
