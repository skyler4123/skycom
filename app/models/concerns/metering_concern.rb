# frozen_string_literal: true

# Auto-increment Redis usage counters when business records are created.
# Include in any model that should count toward billing volumetric metrics.
#
#   class Order < ApplicationRecord
#     include MeteringConcern
#     metered_as :orders  # key must match a BillingResource name
#   end
#
# On Order.create → after_commit fires → company.record_usage!("orders")
#   → Kredis.redis.incrby("skycom:company:<uuid>:orders:20260624", 1)
#
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
