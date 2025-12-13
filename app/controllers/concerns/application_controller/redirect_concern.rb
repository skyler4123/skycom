module ApplicationController::RedirectConcern
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_company_groups

    private
    # If user have no company_groups, redirect to new_company_groups page
    # If params[:school_id] is present, redirect to school/schools page
    # If params[:retail_id] is present, redirect to retail/stores page
    def redirect_to_company_groups
      if Current.user && Current.user.company_groups.empty?
        redirect_to new_company_group_path and return
      elsif params[:school_id]
        redirect_to school_schools_path and return
      elsif params[:retail_id]
        redirect_to retail_stores_path and return
      end
    end
  end
end
