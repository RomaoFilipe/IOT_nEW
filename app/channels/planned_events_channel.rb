class PlannedEventsChannel < ApplicationCable::Channel
  def subscribed
    # Pode ser mais específico por utilizador, ex:
    stream_from "planned_events_#{current_user.id}"
  end

  def unsubscribed
    # Cleanup se necessário
  end
end