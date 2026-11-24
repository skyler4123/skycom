# frozen_string_literal: true

module HomeHelper
  def home_locale_path(locale)
    locale = locale.to_sym
    return root_path if locale == DEFAULT_LOCALE

    localized_home_path(locale: locale)
  end

  def canonical_home_url(locale = I18n.locale)
    "#{CANONICAL_BASE_URL}#{home_locale_path(locale)}"
  end

  def home_alternate_urls
    PUBLISHED_LOCALES.map { |locale| [ locale.to_s, canonical_home_url(locale) ] } +
      [ [ "x-default", canonical_home_url(DEFAULT_LOCALE) ] ]
  end

  def home_og_locale(locale = I18n.locale)
    OG_LOCALES.fetch(locale.to_sym)
  end

  def home_og_alternate_locales
    (PUBLISHED_LOCALES - [ I18n.locale.to_sym ]).map { |locale| home_og_locale(locale) }
  end

  def home_structured_data
    organization_id = "#{CANONICAL_BASE_URL}/#organization"
    website_id = "#{CANONICAL_BASE_URL}/#website"

    {
      "@context" => "https://schema.org",
      "@graph" => [
        {
          "@type" => "Organization",
          "@id" => organization_id,
          "name" => "Skycom",
          "url" => CANONICAL_BASE_URL,
          "logo" => "#{CANONICAL_BASE_URL}/icon.png"
        },
        {
          "@type" => "WebSite",
          "@id" => website_id,
          "name" => "Skycom",
          "url" => CANONICAL_BASE_URL,
          "inLanguage" => I18n.locale.to_s,
          "publisher" => { "@id" => organization_id }
        },
        {
          "@type" => "SoftwareApplication",
          "@id" => "#{CANONICAL_BASE_URL}/#software",
          "name" => "Skycom",
          "applicationCategory" => "BusinessApplication",
          "operatingSystem" => "Web, Android",
          "url" => canonical_home_url,
          "description" => t("home.meta.description"),
          "inLanguage" => I18n.locale.to_s,
          "publisher" => { "@id" => organization_id }
        }
      ]
    }
  end

  def home_structured_data_json
    json_escape(JSON.generate(home_structured_data))
  end

  def home_demo_money(amount)
    number_to_currency(amount, precision: 2, locale: I18n.locale)
  end

  def home_demo_number(amount)
    number_with_delimiter(amount, locale: I18n.locale)
  end

  def home_demo_precision(amount, precision: 1)
    number_with_precision(amount, precision: precision, locale: I18n.locale)
  end
end
