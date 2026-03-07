module ApplicationController::RedirectConcern
  extend ActiveSupport::Concern

  # included do
  #   before_action :redirect_to_companies

  #   private
  #   # If user have no companies, redirect to new_companies page
  #   # If params[:school_id] is present, redirect to school/schools page
  #   # If params[:retail_id] is present, redirect to retail/stores page
  #   def redirect_to_companies
  #     if current_user && current_user.companies.empty?
  #       redirect_to new_company_path and return
  #     elsif params[:school_id]
  #       redirect_to school_schools_path and return
  #     elsif params[:retail_id]
  #       redirect_to retail_stores_path and return
  #     end
  #   end
  # end
end
