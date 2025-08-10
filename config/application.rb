require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

# ⇩⇩⇩ Adiciona este bloco
if ENV["RAILS_ENV"] == "development" || ENV["RACK_ENV"] == "development"
  begin
    require "debug/prelude"
  rescue LoadError
    # ignorar
  end
end
# ⇧⇧⇧

module IoTAgriculturalPlatform
  class Application < Rails::Application
    config.load_defaults 7.2

    config.autoload_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]
    config.eager_load_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]

    config.action_controller.raise_on_missing_callback_actions = false

    config.time_zone = 'Lisbon'
    config.active_record.default_timezone = :local

    config.i18n.available_locales = [:en, :pt, :es]
    config.i18n.default_locale = :en
  end
end
