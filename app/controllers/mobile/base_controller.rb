class Mobile::BaseController < ApplicationController
  skip_before_action :sync_client_cache_version
  skip_before_action :set_paper_trail_whodunnit
  layout "mobile"
end
