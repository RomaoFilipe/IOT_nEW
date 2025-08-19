# app/models/production_fact.rb
class ProductionFact < ApplicationRecord
  belongs_to :company

  scope :for_company, ->(c) { where(company: c) }
  scope :for_period,  ->(range) {
    where("(period_start IS NULL OR period_start <= ?) AND (period_end IS NULL OR period_end >= ?)", range.end, range.begin)
  }
end
