class Companies::CompaniesPolicy < ApplicationPolicy
  def edit?
    record.can?(:update, Company)
  end

  def update?
    record.can?(:update, Company)
  end
end
