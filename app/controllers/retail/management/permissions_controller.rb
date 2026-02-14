class Retail::Management::PermissionsController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        permissions = @retail.permissions
        render json: { permissions: permissions }
      end
    end
  end
end
