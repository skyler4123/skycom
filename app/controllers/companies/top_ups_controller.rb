# frozen_string_literal: true

class Companies::TopUpsController < Companies::ApplicationController
  skip_before_action :check_accessable

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def create
    redirect_to company_billing_path(current_company),
      notice: "Top-up feature coming soon"
  end
end
