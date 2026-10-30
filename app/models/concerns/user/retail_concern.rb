# frozen_string_literal: true

# User::RetailConcern — Atomic purpose: retail-specific convenience readers for
# a User.
#
# Why it exists: retail screens need the user's retail companies/branch without
# repeating the business_type filter.
# How it works: #retails scopes companies to business_type :retail; #retail
# returns the first one.
# Main associations: none directly; relies on User#companies.
module User::RetailConcern
  extend ActiveSupport::Concern

  included do
    def retails
      companies.where(business_type: :retail)
    end

    def retail
      retails.first
    end
  end
end
