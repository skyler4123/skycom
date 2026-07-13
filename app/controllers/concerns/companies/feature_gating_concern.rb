# app/controllers/concerns/companies/feature_gating_concern.rb
module Companies::FeatureGatingConcern
  extend ActiveSupport::Concern

  included do
    before_action :check_feature_enabled!
  end

  class_methods do
    def feature_key(key = nil)
      if key
        @feature_key = key.to_s.freeze
      else
        @feature_key
      end
    end
  end

  private

  def check_feature_enabled!
    key = self.class.feature_key
    return unless key
    return unless current_company
    return unless BillingResource.exists?
    return if current_company.feature_enabled?(key)

    display_name = BillingResource.find_by(
      name: key, resource_type: :addon_feature, country_code: current_company.country_code
    )&.description || key.humanize

    respond_to do |format|
      format.html do
        redirect_to company_billing_path(current_company),
          alert: "Feature not available. Upgrade your plan to enable #{display_name}."
      end
      format.json do
        render json: {
          error: "Feature not available",
          feature_key: key,
          upgrade_url: company_billing_path(current_company)
        }, status: :forbidden
      end
    end
  end
end
