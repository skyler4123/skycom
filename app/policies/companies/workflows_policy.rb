# app/policies/companies/workflows_policy.rb
class Companies::WorkflowsPolicy < ApplicationPolicy
  def index?;    record.can?(:read,    Workflow) end
  def show?;     record.can?(:read,    Workflow) end
  def new?;      record.can?(:create,  Workflow) end
  def create?;   record.can?(:create,  Workflow) end
  def edit?;     record.can?(:update,  Workflow) end
  def update?;   record.can?(:update,  Workflow) end
  def destroy?;  record.can?(:delete,  Workflow) end
end
