class PlannedEventsChannel < ApplicationCable::Channel
  def subscribed
    # Assumindo que tens current_user disponível aqui
    stream_for current_user
  end

  def unsubscribed
    # Cleanup (se necessário)
  end
end
