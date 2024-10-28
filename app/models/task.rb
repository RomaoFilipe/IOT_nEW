class Task < ApplicationRecord
  belongs_to :crop
  validates :name, :start_time, :end_time, presence: true
end
