# frozen_string_literal: true

# Financial analytics follows invoice visibility. The owner bypass lives in
# Employee#can?, so Admin/Manager roles with Invoice read can open the page;
# roles without money visibility cannot.
class Companies::AnalyticsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Invoice)
  end

  def show?
    record.can?(:read, Invoice)
  end

  # The analytics layout is company-wide configuration — owner-only, mirroring
  # Companies::DashboardsPolicy#update?.
  def update?
    record.owner_role?
  end
end
