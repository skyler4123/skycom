# frozen_string_literal: true

# Deducts dashboard-access credits (action_type: "access_dashboard").
# Triggered by Companies::DashboardsController via the CreditDeductionConcern
# after_action — this service never runs inline in the action.
module CompanyCreditDeduction
  module Companies
    module Dashboards
      class IndexService < CompanyCreditDeduction::BaseService
        def action_type = "access_dashboard"

        def description = "Dashboard access"
      end
    end
  end
end
