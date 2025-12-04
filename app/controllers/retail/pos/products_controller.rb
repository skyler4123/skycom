class Retail::Pos::ProductsController < Retail::Pos::ApplicationController
  # GET /companies or /companies.json
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { retail: @retail, stores: @stores } }
    end
  end
end
