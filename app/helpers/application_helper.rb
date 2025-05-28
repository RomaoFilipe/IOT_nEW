module ApplicationHelper
  def format_time(seconds)
    minutes = (seconds / 60).to_i
    hours = (minutes / 60).to_i
    remaining_minutes = minutes % 60
    remaining_seconds = seconds % 60
    "#{hours}h #{remaining_minutes}m #{remaining_seconds}s"
  end
end
