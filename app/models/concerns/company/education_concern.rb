# frozen_string_literal: true

# Company::EducationConcern — Atomic purpose: business-type extension point for
# education companies.
#
# Why it exists: education-specific behavior is attached to Company only when
# the business type needs it, keeping the base Company model focused.
# How it works: currently exposes #schools as an alias of #branches; future
# education-only behavior belongs here.
# Main associations: none directly; relies on Company#branches.
module Company::EducationConcern
  extend ActiveSupport::Concern

  included do
    def schools
      branches
    end
  end
end
