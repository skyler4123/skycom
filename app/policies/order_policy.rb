class OrderPolicy < ApplicationPolicy
  attr_reader :user, :record, :employee

  def initialize(user, record)
    @user = user
    @record = record
    # Find the employee profile for the current context (Company Group)
    # Assuming you have a method to access current_company_group or similar in your app context
    # Often accessing: record.company_group or user.employees.find_by(company_group: ...)
    @employee = user.employees.find_by(company_group_id: record.company_group_id)
  end

  # CRUD Mapping
  def index?
    check_permission("read")
  end

  def show?
    check_permission("read")
  end

  def create?
    check_permission("create")
  end

  def update?
    check_permission("update")
  end

  def destroy?
    check_permission("delete")
  end

  private

  def check_permission(action)
    return false unless @employee
    # Checks the DB for policies linked to the employee's roles
    @employee.can?(action, "Order")
  end
end
