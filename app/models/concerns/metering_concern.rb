# frozen_string_literal: true

module MeteringConcern
  extend ActiveSupport::Concern

  class_methods do
    def metered_as(resource_key)
      @metered_resource_key = resource_key
    end

    def metered_resource_key
      @metered_resource_key
    end
  end

  included do
    after_commit :increment_usage_counter, on: :create
  end

  private

  def increment_usage_counter
    key = self.class.metered_resource_key
    return unless key && respond_to?(:company_id) && company_id.present?

    company&.record_usage!(key)
  end
end
