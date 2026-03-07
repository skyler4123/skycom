# app/controllers/companies/administrators_controller.rb
class Companies::AdministratorsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # Assuming @company.permissions returns a Hash like: { "Admin" => { policies: [...] } }
        @administrators = @company.permissions 
        render json: { administrators: @administrators }
      end
    end
  end
end
