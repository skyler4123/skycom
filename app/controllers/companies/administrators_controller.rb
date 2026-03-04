# app/controllers/companies/branches_controller.rb

class Companies::AdministratorsController < Companies::ApplicationController

  def index
    # debugger
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @administrators = @company.permissions
        render json: { administrators: @administrators }
      end
    end
  end
end
