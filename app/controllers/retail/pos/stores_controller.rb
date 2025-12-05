class Retail::Pos::StoresController < Retail::Pos::ApplicationController

  # The POS screen for a store
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { retail: @retail, stores: @stores } }
    end
  end
end
