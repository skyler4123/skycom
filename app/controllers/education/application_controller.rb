class Education::ApplicationController < ApplicationController
  before_action :set_education

  private

  def set_education
    education_id = params[:education_id]
    @education = CompanyGroup.find(education_id) if education_id.present?
  end
end
