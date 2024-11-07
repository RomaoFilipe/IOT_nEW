class Task < ApplicationRecord
  validates :title, :start, :end, presence: true
end
