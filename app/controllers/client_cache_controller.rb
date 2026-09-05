# app/controllers/client_cache_controller.rb

# Give the latest cache for client
class ClientCacheController < ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          user: current_user.as_json,
          companies: current_user.accessible_companies.as_json(
            include: {
              branches:          {},
              departments:       {},
              roles:             {},
              categories:        {},
              property_mappings: {},
              table_configs:     {},
              settings:          {}
            },
            methods: [ :resource_names ]
          ),
          enums: ClientCache::EnumsBuilder.build,
          employees: current_user.employees
        }
      end
    end
  end
end
