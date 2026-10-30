# frozen_string_literal: true

# Company::RestaurantConcern — Atomic purpose: business-type extension point for
# restaurant companies.
#
# Why it exists: restaurant-specific behavior is isolated here so it can be
# added without widening Company for every tenant.
# How it works: currently a no-op placeholder included by Company;
# restaurant-only methods and callbacks should be added here.
# Main associations: none directly.
module Company::RestaurantConcern
  extend ActiveSupport::Concern

  included do
  end
end
