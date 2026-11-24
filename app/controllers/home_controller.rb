class HomeController < ApplicationController
  skip_before_action :authenticate, only: [ :index, :sitemap, :robots ]
  skip_before_action :set_current_session, only: [ :sitemap, :robots ]
  skip_before_action :sync_client_cache_version, only: [ :sitemap, :robots ]

  before_action :redirect_trailing_slash, only: [ :index ]
  before_action :redirect_default_locale, only: [ :index ]
  around_action :switch_locale, only: [ :index ]
  after_action :set_content_language, only: [ :index ]

  def index
    # The homepage is fully static HTML (signed-out state ships for everyone;
    # signed-in users re-render the header client-side from the client cache),
    # so browsers may cache it. It must stay browser-private: the layout embeds
    # a per-session CSRF token that modal forms submit, and a shared copy would
    # serve one user's token to everyone (mass 422s). Vary: Cookie keeps the
    # entry correct across sign-in/sign-out. Flash messages are per-user too —
    # never cache a response carrying one. Locale isolation comes from the URL
    # (`/` vs `/vi`), not from a shared cache key.
    if flash.any?
      expires_now
    else
      expires_in 1.hour, public: false
      response.headers["Vary"] = "Cookie"
    end

    respond_to do |format|
      format.html do
        if !current_session
          cookies.delete(:session_token)
          cookies.delete(:is_signed_in)
        end
      end
      # format.json do
      # end
    end
  end

  def sitemap
    expires_in 1.day, public: true
    render "home/sitemap", formats: [ :xml ], layout: false
  end

  def robots
    expires_in 1.day, public: true
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    render "home/robots", formats: [ :text ], layout: false
  end

  private

  def redirect_trailing_slash
    path = request.original_fullpath.split("?", 2).first
    return if path == "/"
    return unless path.end_with?("/")

    redirect_to path.chomp("/"), status: :moved_permanently
  end

  def redirect_default_locale
    return if request.path_parameters[:locale].blank?
    return unless request.path_parameters[:locale].to_s == DEFAULT_LOCALE.to_s

    redirect_to root_path, status: :moved_permanently
  end

  def switch_locale(&action)
    locale = request.path_parameters[:locale].presence || DEFAULT_LOCALE
    raise ActionController::RoutingError, "Unknown locale" unless PUBLISHED_LOCALES.include?(locale.to_sym)

    I18n.with_locale(locale, &action)
  end

  def set_content_language
    response.headers["Content-Language"] = I18n.locale.to_s
  end

  # def retail
  #   retail = current_user.retail
  #   redirect_to retail_management_dashboard_index_path(retail) if retail
  #   redirect_to new_company_path if !retail
  # end

  # def education
  #   education = current_user.education
  #   redirect_to education_schools_path(education) if education
  #   redirect_to new_company_path if !education
  # end

  # def hospital
  #   hospital = current_user.hospital
  #   redirect_to hospital_patients_path(hospital) if hospital
  #   redirect_to new_company_path if !hospital
  # end

  # def restaurant
  #   restaurant = current_user.restaurant
  #   redirect_to restaurant_management_dashboard_index_path(restaurant) if restaurant
  #   redirect_to new_company_path if !restaurant
  # end

  # def shop
  #   shop = current_user.shop
  #   redirect_to shop_management_dashboard_index_path(shop) if shop
  #   redirect_to new_company_path if !shop
  # end

  # def fitness
  #   fitness = current_user.fitness
  #   redirect_to fitness_management_dashboard_index_path(fitness) if fitness
  #   redirect_to new_company_path if !fitness
  # end
end
