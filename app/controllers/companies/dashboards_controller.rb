# app/controllers/companies/branches_controller.rb

class Companies::DashboardsController < Companies::ApplicationController
  def index
    # debugger
    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end
end
