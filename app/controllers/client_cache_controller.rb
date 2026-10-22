# app/controllers/client_cache_controller.rb

# Give the latest cache for client.
# Serves Stimulus: client_cache_controller (sync: version-cookie compare → GET index JSON → localStorage)
# Endpoints: GET /client_cache(.json) — { user, companies[] (with branches, departments,
#   roles, categories, property_mappings, table_configs, company_settings), employees[] }
# Docs: docs/CACHE.md (client cache incl. dynamic sidebar settings), docs/SIDEBAR.md
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
              company_settings: {},
              workflows: { include: { workflow_steps: {} } }
            },
            methods: [ :resource_names ]
          ),
          employees: current_user.employees,
          export_pages: EXPORT_ENABLED_RESOURCES
        }
      end
    end
  end
end
