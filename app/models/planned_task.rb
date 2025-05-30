class PlannedTask < ApplicationRecord
  belongs_to :field

  scope :upcoming, -> { where(completed: false).where("scheduled_for >= ?", Time.current).order(:scheduled_for) }

  def to_event_hash
    {
      id: id,
      type: :task,
      title: title,
      description: description,
      field: field&.name,
      time: scheduled_for,
      priority: priority
    }
  end

end
