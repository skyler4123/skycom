class PurchaseItemsController < ApplicationController
  before_action :set_purchase_item, only: %i[ show edit update destroy ]

  # GET /purchase_items or /purchase_items.json
  def index
    @purchase_items = PurchaseItem.all
  end

  # GET /purchase_items/1 or /purchase_items/1.json
  def show
  end

  # GET /purchase_items/new
  def new
    @purchase_item = PurchaseItem.new
  end

  # GET /purchase_items/1/edit
  def edit
  end

  # POST /purchase_items or /purchase_items.json
  def create
    @purchase_item = PurchaseItem.new(purchase_item_params)

    respond_to do |format|
      if @purchase_item.save
        format.html { redirect_to @purchase_item, notice: "Purchase item was successfully created." }
        format.json { render :show, status: :created, location: @purchase_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @purchase_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchase_items/1 or /purchase_items/1.json
  def update
    respond_to do |format|
      if @purchase_item.update(purchase_item_params)
        format.html { redirect_to @purchase_item, notice: "Purchase item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @purchase_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @purchase_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchase_items/1 or /purchase_items/1.json
  def destroy
    @purchase_item.destroy!

    respond_to do |format|
      format.html { redirect_to purchase_items_path, notice: "Purchase item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase_item
      @purchase_item = PurchaseItem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def purchase_item_params
      params.expect(purchase_item: [ :purchase_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :status, :business_type, :discarded_at ])
    end
end
