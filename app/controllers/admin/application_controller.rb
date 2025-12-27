class Admin::ApplicationController < ApplicationController
  before_action :only_admin_can_access

  private

  # def set_retail
  #   retail_id = params[:retail_id]
  #   @retail = CompanyGroup.find(retail_id) if retail_id.present?
  # end
  def only_admin_can_access
    redirect_to root_path unless Current.user.system_role_super_admin? || Current.user.system_role_admin?
  end    
end
