# frozen_string_literal: true

# SubscriptionGroupSubscriptionPlanAppointment — Atomic purpose: atomic row
# binding a SubscriptionPlan to its scope.
#
# Why it exists: connects the plan catalog to the branch offering the plan (or
# the subscription group holding member plans).
#
# How to use: create rows directly or through seed/domain services; read via the
# has_many/through on the owning side.
#
# How it works: concrete FKs plus company_id derived via
# SetDefaultCompanyConcern.
#
# Main associations: belongs_to :company, :subscription_group,
# :subscription_plan.
class SubscriptionGroupSubscriptionPlanAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :subscription_group
  belongs_to :subscription_plan
end
