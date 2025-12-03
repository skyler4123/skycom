module ApplicationController::CurrentConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_current_company_group_id

    private

    # Get current_company_group_id from Cookie
    def set_current_company_group_id
      Current.company_group_id = params[:education_id] if params[:education_id].present?
      Current.company_group_id = params[:hospital_id] if params[:hospital_id].present?
      Current.company_group_id = params[:hotel_id] if params[:hotel_id].present?
      Current.company_group_id = params[:restaurant_id] if params[:restaurant_id].present?
      Current.company_group_id = params[:retail_id] if params[:retail_id].present?
      cookies[:current_company_group_id] = Current.company_group_id
    end
  end
end
