# frozen_string_literal: true

# Company::HospitalConcern — Atomic purpose: business-type extension point for
# hospital companies.
#
# Why it exists: hospital-specific behavior is isolated here so it can be added
# without widening Company for every tenant.
# How it works: currently a no-op placeholder included by Company; hospital-only
# methods and callbacks should be added here.
# Main associations: none directly.
module Company::HospitalConcern
  extend ActiveSupport::Concern

  included do
  end
end
