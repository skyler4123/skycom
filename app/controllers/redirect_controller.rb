class RedirectController < ApplicationController
  # Avatar / "My Profile" target for users whose client cache has no employee
  # record (so the browser cannot build the employee show URL itself).
  # System accounts live in the admin portal; employees go to their own show
  # page; everyone else needs an employee account before they have a profile.
  # Serves Stimulus: users--avatar-popover (fallback link), companies/sidebars
  # (My Profile → Employee fallback).
  def profile
    if current_user.system_role_admin? || current_user.system_role_super_admin?
      redirect_to admin_companies_path
    elsif (employee = current_user.employees.kept.first)
      redirect_to company_employee_path(employee.company_id, employee)
    else
      redirect_to root_path, alert: "You need an employee account of a company to see your profile."
    end
  end

  def companies
    companies = current_user.accessible_companies
    redirect_to root_path if companies.empty?
    redirect_company = companies.first if companies.present?
    redirect_to company_dashboards_path(redirect_company) if redirect_company
  end
end
