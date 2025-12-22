class Retail::Pos::BranchesController < Retail::Pos::ApplicationController
  # The POS screen for a branch
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { retail: @retail, branches: @branches } }
    end
  end

  def products
    @products = @branch.products
    respond_to do |format|
      format.json { render json: @products.to_json(methods: [ :image_urls ])  }
    end
  end
end
