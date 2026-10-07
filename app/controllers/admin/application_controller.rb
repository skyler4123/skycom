class Admin::ApplicationController < ApplicationController
  layout "admin"

  include ApplicationController::WebsocketConcern

  before_action :only_admin_can_access
  before_action :set_websocket_channels

  private

  # def set_retail
  #   retail_id = params[:retail_id]
  #   @retail = Company.find(retail_id) if retail_id.present?
  # end
  def only_admin_can_access
    redirect_to root_path unless current_user.system_role_super_admin? || current_user.system_role_admin?
  end

  # Admin WebSocket channels (overrides WebsocketConcern).
  # Companies layout authorizes current-company + user; admin has no
  # current_company, so authorize user always + the ticket's company
  # channel on ticket detail pages. List/pool pages stay user-only.
  def set_websocket_channels
    return unless is_signed_in? && current_user

    @channels = []
    @channels << WEBSOCKET.channel_name(:user, current_user.id) if current_user

    if params[:controller] == "admin/company_tickets" && params[:id].present?
      company_id = CompanyTicket.where(id: params[:id]).pick(:company_id)
      @channels << WEBSOCKET.channel_name(:company, company_id) if company_id
    end

    @channels.compact!
  end
end
