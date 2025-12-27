# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:, exclusive_token: nil)
    current_user = { id: user.id, email: user.email, avatar: user.avatar_url }

    company_groups = user.company_groups.map do |company_group|
      business_type = company_group.business_type
      url = case business_type
            when "retail"    then retail_management_branches_path(retail_id: company_group.id)
            when "education" then education_schools_path(education_id: company_group.id)
            when "hospital"  then hospital_patients_path(hospital_id: company_group.id)
            end

      { id: company_group.id, name: company_group.name, business_type: business_type, url: url }
    end

    cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

    # Only set exclusive_token if provided
    if exclusive_token.present?
      cookies.signed.permanent[:exclusive_token] = { value: exclusive_token, httponly: true }
    else
      cookies.delete(:exclusive_token) # Clear it if not needed (e.g. normal login)
    end

    cookies.permanent[:is_signed_in] = true
    cookies.permanent[:current_user] = current_user.to_json
    cookies.permanent[:company_groups] = company_groups.to_json
  end
end
