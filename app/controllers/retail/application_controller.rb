class Retail::ApplicationController < ApplicationController
  before_action :set_retail

  private

  def set_retail
    retail_id = params[:retail_id]
    @retail = CompanyGroup.find(retail_id) if retail_id.present?
  end
end
