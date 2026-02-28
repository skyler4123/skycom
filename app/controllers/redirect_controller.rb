class RedirectController < ApplicationController

  def companies
    companies = current_user.companies
    redirect_company = companies.first if companies.present?
    redirect_to company_branches_path(redirect_company) if redirect_company
  end
end
