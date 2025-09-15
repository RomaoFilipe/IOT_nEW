# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#     # Specify URI for violation reports
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end
#
#   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src style-src)
#
#   # Report violations without enforcing the policy.
#   # config.content_security_policy_report_only = true
# end
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://api.mapbox.com"
    policy.img_src     :self, :data, "https://api.mapbox.com", "https://*.tiles.mapbox.com"
    policy.script_src  :self, :unsafe_inline, "https://api.mapbox.com", "https://cdn.tailwindcss.com", "https://cdn.jsdelivr.net"
    policy.style_src   :self, :unsafe_inline, "https://api.mapbox.com", "https://cdn.tailwindcss.com"
    policy.connect_src :self, "https://api.mapbox.com", "https://events.mapbox.com", "https://*.tiles.mapbox.com"
    policy.worker_src  :self, :blob
    policy.frame_ancestors :self
  end

  # Em dev podes comentar o report_only para ver logo o bloqueio se houver
  # config.content_security_policy_report_only = true
end
