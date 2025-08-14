class LocalesController < ApplicationController
  # Trocar idioma deve ser público
  skip_before_action :authenticate_user!, only: :update

  def update
    chosen  = params[:id].to_s
    allowed = %w[pt en es]
    session[:locale] = allowed.include?(chosen) ? chosen : I18n.default_locale
    target = session[:locale].to_s

    # tenta voltar para a mesma página mas com /<locale> correto no path
    if request.referer.present?
      begin
        uri = URI.parse(request.referer)
        # substitui /pt|en|es no início do path pelo novo locale (ou adiciona se não existir)
        new_path = uri.path.sub(/\A\/(pt|en|es)(?=\/|$)/, "/#{target}")
        new_path = "/#{target}#{new_path}" unless new_path.start_with?("/#{target}")
        uri.path = new_path
        # mantém a query string, âncora, etc.
        redirect_to uri.to_s, allow_other_host: false and return
      rescue URI::InvalidURIError
        # cai no fallback abaixo
      end
    end

    # fallback sensato
    redirect_to(user_signed_in? ? dashboard_path(locale: target) : root_path(locale: target))
  end
end
