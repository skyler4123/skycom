# app/controllers/concerns/companies/feature_gating_concern.rb
module Companies::FeatureGatingConcern
  extend ActiveSupport::Concern

  included do
    before_action :check_feature_enabled!
  end

  class_methods do
    def feature_key(key = nil, only: nil, except: nil)
      if key
        @feature_key = key.to_s.freeze
        @feature_key_only = normalize_action_names(only)
        @feature_key_except = normalize_action_names(except)
      else
        @feature_key
      end
    end

    def feature_key_only
      @feature_key_only
    end

    def feature_key_except
      @feature_key_except
    end

    private

    def normalize_action_names(actions)
      case actions
      when nil then nil
      when Array then actions.map(&:to_s).map(&:freeze)
      else [ actions.to_s ].freeze
      end
    end
  end

  private

  def check_feature_enabled!
    key = self.class.feature_key
    return unless key
    return if feature_gate_exempted?
    return unless current_company
    return unless BillingResource.exists?
    return if current_company.feature_enabled?(key)

    display_name = BillingResource.find_by(
      name: key, resource_type: :addon_feature, country: current_company.country
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

  def feature_gate_exempted?
    only = self.class.feature_key_only
    except = self.class.feature_key_except
    return true if only && !only.include?(action_name)
    return true if except&.include?(action_name)

    false
  end
end
