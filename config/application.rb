require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IoTAgriculturalPlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Ignorar diretórios específicos no lib que não contêm arquivos .rb
    config.autoload_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]
    config.eager_load_paths += Dir[Rails.root.join('lib', '{assets,tasks}')]

    # Evitar erro de callback para ações ausentes
    config.action_controller.raise_on_missing_callback_actions = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
