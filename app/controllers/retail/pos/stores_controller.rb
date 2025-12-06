class Retail::Pos::StoresController < Retail::Pos::ApplicationController

  # The POS screen for a store
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { retail: @retail, stores: @stores } }
    end
  end

  def products
    @products = @store.products
    respond_to do |format|
      format.json { render json: @products.to_json(methods: [:image_urls])  }
    end
  end
end
