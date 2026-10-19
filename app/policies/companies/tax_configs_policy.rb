# frozen_string_literal: true

class Companies::TaxConfigsPolicy < ApplicationPolicy
  def show?
    record.owner_role?
  end

  def update?
    record.owner_role?
  end
end
