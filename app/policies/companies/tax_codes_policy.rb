# frozen_string_literal: true

class Companies::TaxCodesPolicy < ApplicationPolicy
  def index?
    record.owner_role?
  end

  def create?
    record.owner_role?
  end

  def update?
    record.owner_role?
  end

  def destroy?
    record.owner_role?
  end
end
