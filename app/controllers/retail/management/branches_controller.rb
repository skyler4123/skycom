class Retail::Management::BranchesController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @branches = @retail.branches
        render json: { branches: @branches }
      end
    end
  end
end
