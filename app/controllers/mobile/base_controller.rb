class Mobile::BaseController < ApplicationController
  skip_before_action :sync_client_cache_version
  skip_before_action :set_paper_trail_whodunnit
  layout "mobile"

  private

  # Mobile pages are also served inside the Hotwire Native app, so signed-out
  # visitors must land on the mobile sign-in page instead of the marketing root.
  def authenticate
    redirect_to mobile_sign_in_path unless is_signed_in?
  end
end
