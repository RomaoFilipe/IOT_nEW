require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IoTAgriculturalPlatform
  class Application < Rails::Application
    config.load_defaults 7.2

    config.autoload_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]
    config.eager_load_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]

    config.action_controller.raise_on_missing_callback_actions = false

    config.time_zone = 'Lisbon'
    config.active_record.default_timezone = :local

    # ✅ Aqui dentro!
    config.i18n.default_locale = :pt
    config.i18n.available_locales = [:pt, :en, :es]
  end
end