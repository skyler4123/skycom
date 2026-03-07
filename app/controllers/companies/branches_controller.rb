# app/controllers/companies/branches_controller.rb

class Companies::BranchesController < Companies::ApplicationController

  def index
    # debugger
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @branches = @company.branches
        render json: { branches: @branches }
      end
    end
  end
end
