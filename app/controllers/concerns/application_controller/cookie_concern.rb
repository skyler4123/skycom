# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:)
    current_user = { id: user.id, email: user.email, avatar: user.avatar_url }

    companies = user.companies.map do |company|
      business_type = company.business_type
      url = case business_type
      when "retail"    then retail_management_branches_path(retail_id: company.id)
      when "education" then education_schools_path(education_id: company.id)
      when "hospital"  then hospital_patients_path(hospital_id: company.id)
      end

      { id: company.id, name: company.name, business_type: business_type, url: url }
    end

    cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
    cookies.permanent[:is_signed_in] = true
    cookies.permanent[:current_user] = current_user.to_json
    cookies.permanent[:companies] = companies.to_json
  end
end
