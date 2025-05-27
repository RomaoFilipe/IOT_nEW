class PlannedTask < ApplicationRecord
  belongs_to :field

  scope :upcoming, -> { where(completed: false).where("scheduled_for >= ?", Time.current).order(:scheduled_for) }
end
