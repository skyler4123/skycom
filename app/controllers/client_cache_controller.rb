class ClientCacheController < ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # debugger
        render json: {
          user: current_user.as_json,
          companies: current_user.companies.as_json(include: [:branches, :departments, :roles]),
          # Future expansions:
          # settings: current_user.settings,
          # permissions: current_user.all_permissions
        }
      end
    end
  end
end