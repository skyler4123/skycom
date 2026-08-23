class Companies::PoliciesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.policies

        @pagy, @policies_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          policies: format_policies(@policies_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_policies(policies)
    policies.map do |policy|
      policy.as_json(only: [ :id, :name, :description, :code, :resource, :action, :business_type, :lifecycle_status, :workflow_status ]).merge(
        branch: policy.branch&.as_json(only: [ :id, :name ])
      )
    end
  end
end
