# app/policies/companies/invoices_policy.rb
class Companies::InvoicesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Invoice)
  end

  def show?
    record.can?(:read, Invoice)
  end

  def new?
    record.can?(:create, Invoice)
  end

  def create?
    record.can?(:create, Invoice)
  end

  def edit?
    record.can?(:update, Invoice)
  end

  def update?
    record.can?(:update, Invoice)
  end
end
