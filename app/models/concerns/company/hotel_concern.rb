# frozen_string_literal: true

# Company::HotelConcern — Atomic purpose: business-type extension point for
# hotel companies.
#
# Why it exists: hotel-specific behavior is isolated here so it can be added
# without widening Company for every tenant.
# How it works: currently a no-op placeholder included by Company; hotel-only
# methods and callbacks should be added here.
# Main associations: none directly.
module Company::HotelConcern
  extend ActiveSupport::Concern

  included do
  end
end
