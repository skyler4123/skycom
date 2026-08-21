# frozen_string_literal: true

# Credit deduction is controlled at the CONTROLLER ACTION level via an
# after_action filter — never inline inside actions. Controllers declare
# which CompanyCreditDeduction::* service runs for which action:
#
#   class Companies::DashboardsController < Companies::ApplicationController
#     deduct_company_credits_for :index, with: CompanyCreditDeduction::Companies::Dashboards::IndexService
#   end
#
# The filter:
#   - runs only after a SUCCESSFUL JSON response (no HTML, no 4xx/5xx)
#   - delegates the whole deduction to the declared service class
#   - rescues all deduction errors so the request is never broken
module Companies::CreditDeductionConcern
  extend ActiveSupport::Concern

  included do
    after_action :run_credit_deduction
  end

  class_methods do
    # Declarative DSL — maps one or more actions to their dedicated
    # CompanyCreditDeduction::* service subclass.
    def deduct_company_credits_for(*actions, with:)
      @credit_deduction_services ||= {}
      Array(actions).each { |action| @credit_deduction_services[action.to_sym] = with }
    end
  end

  private

  def run_credit_deduction
    service_class = self.class.instance_variable_get(:@credit_deduction_services)&.[](action_name.to_sym)
    return unless service_class
    return unless request.format.json?
    return unless performed? && response.successful?

    service_class.call(company: current_company)
  rescue StandardError => e
    # A deduction failure must never break the request — log and continue.
    Rails.logger.warn("[CompanyCreditDeduction] #{self.class}##{action_name}: #{e.message}")
  end
end
