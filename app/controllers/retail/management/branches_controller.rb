class Retail::Management::BranchesController < Retail::Management::ApplicationController
  rate_limit to: 40, within: 1.minute, only: :index

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
