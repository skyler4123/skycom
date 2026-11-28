require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Skycom
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Public marketing pages are localized server-side. Missing translations must
    # fail tests instead of silently mixing English into a non-English URL.
    # Keep this list in sync with PUBLISHED_LOCALES
    # (spec/i18n/home_locale_completeness_spec.rb guards the duplicate).
    config.i18n.available_locales = %i[en vi]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end






# Custom configuration
module Skycom
  class Application < Rails::Application
    config.generators.orm :active_record, primary_key_type: :uuid

    # Configures Active Storage to use MiniMagick (ImageMagick) for image processing.
    # Overrides the Rails default (:vips) to avoid requiring the libvips C-library dependency.
    config.active_storage.variant_processor = :mini_magick
  end
end
