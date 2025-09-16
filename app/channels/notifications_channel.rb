class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Simples: todos recebem. Se quiseres por conta/tenant, mete aqui a chave adequada.
    stream_from "notifications"
  end
end
